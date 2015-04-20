BLUR_WAITFRAMES	= 50
BLUR_NUMFRAMES	= 1195
BLUR_FADEFRAMES	= 32

BLUR_WIDTH	= 160
BLUR_HEIGHT	= 60

	include "../framework/hardware.i"
	include "../framework/framework.i"
	include "../launcher/timings.asm"	
		
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

	
			section	"blur_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable

		bsr.w	blur_init

		bsr.w	blur_update
		jsr		blur_dopage
		bsr.w	blur_setpal
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#BLUR_WAITFRAMES,d0
		move.w	d0,blur_waitframe
		
		move.w	#TIME_BLUR_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		lea		blur_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
				
		move.l	#blur_copperlist,a0
		move.l	#blur_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#BLUR_NUMFRAMES,d0
		move.w	d0,blur_endframe
		
blur_main:
		;move.w	#$0008,$dff180
		bsr.w	blur_update
		;move.w	#$000,$dff180
		
.sync:
		tst.w	blur_sync
		beq.b	.sync
		clr.w	blur_sync
		
		;bsr.w	vsync
		jsr		blur_dopage
		jsr 	blur_fadecols
		
		btst	#$06,$bfe001
		beq.b	blur_end
		
		move.w	blur_endframe,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	blur_main
blur_end:
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		rts		

		cnop	0,4
fw_jumptable:
		dc.l	0
blur_waitframe:
		dc.w	0
blur_endframe:
		dc.w	0

;--------------------------------------------------------------------

blur_init:
		lea		blur_sintab,a0
		lea		$400(a0),a1
		move.l	a1,a2
		lea		$800(a0),a3
		move.w	#$ff,d7
.sl0:	
		move.w	(a0)+,d0
		move.w	d0,-(a1)
		
		neg.w	d0
		move.w	d0,(a2)+
		move.w	d0,-(a3)
		dbra	d7,.sl0

		bsr.w	blur_gentabs
		bsr.w	blur_genc2pcode
		bsr.w	blur_genupdatecode
		
		lea		blur_texture,a0
		lea		blur_texture+$8000,a1
		moveq	#0,d0
		move.w	#$3fff,d7
.l0:
		move.b	(a0)+,d0
		add.b	d0,d0
		move.w	d0,(a1)+
		dbra	d7,.l0
		
		lea		blur_texture+$8000,a0
		lea		blur_texture,a1
		move.w	#$3fff,d7
.l1:
		move.w	(a0)+,(a1)+
		dbra	d7,.l1
		
		lea		blur_mask,a0
		lea		blur_emptybpl,a1
		move.w	#$aaaa,d0
		moveq	#0,d1
		move.w	#BLUR_WIDTH*BLUR_HEIGHT/8-1,d7
.l2:	
		move.w	d0,(a0)+
		move.w	d1,(a1)+
		dbra	d7,.l2
		
		lea		blur_copperscale,a0
		move.l	#$680ffffe,d0
		move.w	#$0108,d1
		move.w	#$010a,d2
		move.w	#$ffd8,d3
		move.w	#$0000,d4
		move.l	#$01020010,d5
		
		move.w	#BLUR_HEIGHT-1,d7
.l3:
		move.l	d0,(a0)+
		move.w	d1,(a0)+
		move.w	d3,(a0)+
		move.w	d2,(a0)+
		move.w	d3,(a0)+
		move.l	d5,(a0)+
		addi.l	#$01000000,d0
		eori.l	#$00000031,d5

		move.l	d0,(a0)+
		move.w	d1,(a0)+
		move.w	d4,(a0)+
		move.w	d2,(a0)+
		move.w	d4,(a0)+
		move.l	d5,(a0)+
		addi.l	#$01000000,d0
		eori.l	#$00000031,d5

		cmpi.l	#$000ffffe,d0
		bne.b	.skip
		move.l	#$ffdffffe,(a0)+
.skip:
		
		move.l	d0,(a0)+
		move.w	d1,(a0)+
		move.w	d3,(a0)+
		move.w	d2,(a0)+
		move.w	d3,(a0)+
		move.l	d5,(a0)+
		addi.l	#$01000000,d0
		eori.l	#$00000031,d5
		
		dbra	d7,.l3
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		$dff000,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		move.w	#2,BLTAMOD(a6)
		move.w	#2,BLTCMOD(a6)
		clr.w	BLTDMOD(a6)
		clr.w	BLTCON1(a6)
		move.w	#$ff00,BLTBDAT(a6)
				
		lea		blur_logo,a0
		move.w	(a0)+,d0	;palette size in entries
		move.w	(a0)+,d1	;width of bitplane in bytes
		move.w	(a0)+,d2	;size of bitplane in bytes
		move.l	(a0)+,d3	;size of image in bytes
		add.w	d0,d0
		adda.w	d0,a0
		
		move.l	a0,d0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		addi.l	#60*40*1,d1
		addi.l	#60*40*2,d2
		addi.l	#60*40*3,d3
		lea		blur_copperbpl1,a6
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)
		move.w	d1,$0e(a6)
		swap	d1
		move.w	d1,$0a(a6)	
		move.w	d2,$16(a6)
		swap	d2
		move.w	d2,$12(a6)
		move.w	d3,$1e(a6)
		swap	d3
		move.w	d3,$1a(a6)
		rts
						
;--------------------------------------------------------------------

blur_genc2pcode:
		lea		blur_c2p_smc+2,a0
		moveq	#0,d0
		move.w	#BLUR_HEIGHT-1,d7
.l2:
		move.w	#5-1,d6
.l1:
		move.w	#32-1,d5
.l0:
		move.w	d0,(a0)
		addq	#4,a0
	
		dbra	d5,.l0

		addq	#4,a0
		
		dbra	d6,.l1
		
		eori.w	#512,d0
		
		dbra	d7,.l2
		rts
					
;--------------------------------------------------------------------

blur_dithertab:
		dc.w	1,0
		dc.w	0,0
		dc.w	1,0
		dc.w	0,1
		dc.w	1,0
		dc.w	1,1
		dc.w	1,1
		dc.w	1,1

blur_gentabs:
		lea		blur_shadetab1,a1
		lea		blur_shadetab2,a2
		lea		blur_shadetab3,a3
		lea		blur_shadetab4,a4
		moveq	#0,d7
.l0:
		moveq	#0,d0
		move.w	d7,d0
		divs.w	#BLUR_STRENGTH/4,d0
		
		move.w	d0,d4
		move.w	d0,d5
		lsr.w	#2,d4
		andi.w	#3,d5
		add.w	d5,d5
		lsl.w	#2,d5
		lea		blur_dithertab,a0
		adda.w	d5,a0
		
		move.w	d4,d0
		add.w	(a0)+,d0
		bsr.w	.calcshadeval
		
		move.w	d0,(a1)+
		lsr.w	#4,d0
		move.w	d0,(a3)+
	
		move.w	d4,d0
		add.w	(a0)+,d0
		bsr.w	.calcshadeval
		lsr.w	#2,d0
		
		move.w	d0,(a2)+
		lsr.w	#4,d0
		move.w	d0,(a4)+
		
		move.w	d4,d0
		add.w	(a0)+,d0
		bsr.w	.calcshadeval
		
		move.w	d0,254(a1)
		lsr.w	#4,d0
		move.w	d0,254(a3)
	
		move.w	d4,d0
		add.w	(a0)+,d0
		bsr.w	.calcshadeval
		lsr.w	#2,d0
		
		move.w	d0,254(a2)
		lsr.w	#4,d0
		move.w	d0,254(a4)
		
		addq	#1,d7
		cmpi.w	#256,d7
		bne.b	.l0
		rts

.calcshadeval:
		move.w	d0,d1
		move.w	d0,d2
		move.w	d0,d3
		andi.w	#$01,d0
		andi.w	#$02,d1
		andi.w	#$04,d2
		andi.w	#$08,d3
		lsl.w	#6,d0
		lsl.w	#6,d1
		lsl.w	#8,d2
		lsl.w	#4,d2
		lsl.w	#8,d3
		lsl.w	#4,d3
		or.w	d1,d0
		or.w	d2,d0
		or.w	d3,d0		
		rts
		
;--------------------------------------------------------------------

blur_setpal:
		lea		blur_palids,a0
		lea 	blur_pal,a1
		lea		blur_copperpal1,a3
		lea		blur_copperpal2,a4
		lea		blur_logo+10,a5
		move.w	(a1),d0
		move.w	#$0180,d1
		
		moveq	#16-1,d7
.l0:	
		move.w	d1,(a3)+
		move.w	(a5)+,(a3)+
		move.w	d1,(a4)+
		move.w	d0,(a4)+
		addq	#2,d1
		dbra	d7,.l0
	
		lea		$dff1a0,a2
		moveq	#16-1,d7
.l1:	
		move.w	d0,(a2)+
		dbra	d7,.l1
		rts

;--------------------------------------------------------------------

 MACRO<BLUR_PIXELS>
		move.w	$1234(a0),d0
		sub.w	$1234(a1),d0
		move.w	$1234(a0),d1
		sub.w	$1234(a1),d1
		move.w	$1234(a0),d2
		sub.w	$1234(a1),d2
		move.w	$1234(a0),d3
		sub.w	$1234(a1),d3
		move.w	$1234(a0),d4
		sub.w	$1234(a1),d4
		move.w	$1234(a0),d5
		sub.w	$1234(a1),d5
		move.w	$1234(a0),d6
		sub.w	$1234(a1),d6
		move.w	$1234(a0),d7
		sub.w	$1234(a1),d7
		
		add.w	d0,\1+0(a4)
		add.w	d1,\1+4(a4)
		add.w	d2,\1+8(a4)
		add.w	d3,\1+12(a4)
		add.w	d4,\1+16(a4)
		add.w	d5,\1+20(a4)
		add.w	d6,\1+24(a4)
		add.w	d7,\1+28(a4)
 ENDM
		
 MACRO<BLUR_PIXELBLOCK>
		BLUR_PIXELS  0+\1
		BLUR_PIXELS 32+\1
		BLUR_PIXELS 64+\1
		BLUR_PIXELS 96+\1
 ENDM

;--------------------------------------------------------------------

blur_genupdatecode:
		lea		blur_updatepois,a2
		lea		blur_updatecode,a0
		
		moveq	#64-1,d6
.l1:
		move.l	a0,64*4(a2)
		move.l	a0,(a2)+
		
		lea		blur_template,a1
		move.w	#blur_templatesize/2-1,d7
.l0:
		move.w	(a1)+,(a0)+
		dbra	d7,.l0
		
		dbra	d6,.l1
		rts
 
blur_templatesize = blur_templateend-blur_template
 
blur_template:
		BLUR_PIXELBLOCK 0*132
		BLUR_PIXELBLOCK 1*132
		BLUR_PIXELBLOCK 2*132
		BLUR_PIXELBLOCK 3*132
		BLUR_PIXELBLOCK 4*132
		rts
blur_templateend:
		
;--------------------------------------------------------------------

BLUR_STRENGTH 	= 8
BLUR_SPEED 		= 3
		
			cnop	0,4
stepux:		dc.l	0
stepuy:		dc.l	0
stepvx:		dc.l	0
stepvy:		dc.l	0
startux:	dc.l	0
startuy:	dc.l	0
startvx:	dc.l	0
startvy:	dc.l	0
stepframe:	dc.w	0
framecount:	dc.w	0

blur_numblits	= 4

blur_step:
		;addq.w	#1,stepframe
		rts

blur_update:
		bsr.w	blur_genframe
		
		move.w	framecount(pc),d1
		cmpi.w	#64,d1
		blt.b	.noblur
		bsr.w	blur_doblur
.noblur:
		addq.w	#1,framecount
		addq.w	#BLUR_SPEED,stepframe
		rts

;--------------------------------------------------------------------

blur_genframe:
		move.l	blur_rubpoi(pc),a3
		addq	#4,a3
		cmpa.l	#blur_updatepois+4*64,a3
		blt.b	.nowrap
		move.l	#blur_updatepois,a3
.nowrap:
		move.l	a3,blur_rubpoi
		
		move.w	stepframe(pc),d1
		lea		blur_texture,a5
		lea		blur_lerpy1,a4
		
		move.l	blur_rubpoi(pc),a3
		move.l	(a3)+,a3
		adda.w	#2+((32*4+8*4*8)*4),a3
		bsr.w	blur_dolerp
	
		lea		blur_texture,a5
		move.w	framecount(pc),d1
		cmpi.w	#BLUR_STRENGTH+64,d1
		bge.b	.swaptex
		lea		blur_texture2,a5
.swaptex:
		
		move.w	stepframe(pc),d1
		subi.w	#BLUR_STRENGTH*BLUR_SPEED,d1
		lea		blur_lerpy2,a4
		
		move.l	blur_rubpoi(pc),a3
		move.l	(a3)+,a3
		adda.w	#2+((32*4+8*4*8)*4)+4,a3
		bsr.w	blur_dolerp
		rts
		
;--------------------------------------------------------------------

blur_dolerp:
		lea		blur_sintab,a0

		move.w	d1,d2
		add.w	d1,d1
		add.w	d2,d1
		move.w	d1,d5
		lsr.w	#1,d1
		andi.w	#$7fe,d1
		move.w	d1,d0

		addi.w	#$200,d0
		andi.w	#$7fe,d0
		move.w	(a0,d0.w),d0
		muls.w	#96*64/2,d0
		swap	d0
		andi.w	#$7fe,d0
		
		move.w	d5,d1
		add.w	d1,d1
		andi.w	#$7fe,d1
		move.w	(a0,d1.w),d6
		addi.w	#$8000,d6
		mulu.w	#$0c00,d6
		swap	d6
		
		move.w	(a0,d0.w),d1
		addi.w	#$200,d0
		andi.w	#$7fe,d0
		move.w	(a0,d0.w),d2
		move.w	d2,d3
		addi.w	#$200,d0
		andi.w	#$7fe,d0
		move.w	(a0,d0.w),d4

		muls.w	d6,d1
		muls.w	d6,d2
		muls.w	d6,d3
		muls.w	d6,d4
		asr.l	#7,d1
		asr.l	#7,d2
		
		move.l	d2,d6
		add.l	d2,d2
		add.l	d6,d2
		asr.l	#1,d2
		
		move.l	d4,d6
		add.l	d4,d4
		add.l	d6,d4
		asr.l	#1,d4
			
		neg.l	d1
		neg.l	d2
	
		move.l	d1,stepux
		move.l	d2,stepuy
		move.l	d3,stepvx
		move.l	d4,stepvy
		
		asr.l	#4,d1
		muls.w	#-BLUR_WIDTH/2*16,d1
		addi.l	#$800000,d1
		move.l	d1,startux

		asr.l	#4,d3
		asr.l	#7,d3
		muls.w	#-BLUR_WIDTH/2*16*16,d3
		lsl.l	#3,d3
		addi.l	#$40000000,d3
		move.l	d3,startvx
		
		asr.l	#4,d2
		muls.w	#-BLUR_HEIGHT/2*16,d2
		move.l	d2,startuy

		asr.l	#4,d4
		asr.l	#7,d4
		muls.w	#-BLUR_HEIGHT/2*16*16,d4
		lsl.l	#3,d4
		move.l	d4,startvy

		move.w	#$7ffe,d6
					
		move.l	startuy,d2
		move.l	startvy,d3
		move.l	stepuy,d0
		move.l	stepvy,d1
		move.w	d0,d4
		move.w	d1,d0
		move.w	d4,d1
		move.w	d2,d4
		move.w	d3,d2
		move.w	d4,d3
		swap	d0
		swap	d1
		swap	d2
		swap	d3
				
		moveq	#100/10-1,d7
.l1:		
		REPT 10
		addx.l	d0,d2
		addx.l	d1,d3
		move.w	d3,d4
		move.b	d2,d4
		and.w	d6,d4
		lea		(a5,d4.w),a2
		move.l	a2,(a4)+
		ENDR
		dbra	d7,.l1
				
		move.l	startux,d2
		move.l	startvx,d3
		move.l	stepux,d0
		move.l	stepvx,d1
		move.w	d0,d4
		move.w	d1,d0
		move.w	d4,d1
		move.w	d2,d4
		move.w	d3,d2
		move.w	d4,d3
		swap	d0
		swap	d1
		swap	d2
		swap	d3

		moveq	#5-1,d7
.l52:
		moveq	#4-1,d5
.l51:
		REPT	8
		
		addx.l	d0,d2
		addx.l	d1,d3
		move.w	d3,d4
		move.b	d2,d4
		and.w	d6,d4
		move.w	d4,(a3)
		
		addq	#8,a3
		
		ENDR
		
		lea		32(a3),a3
		
		dbra	d5,.l51
		
		lea		-(32*4+8*4*8)*2(a3),a3
		
		dbra	d7,.l52		
		rts

;--------------------------------------------------------------------

		cnop	0,4
blur_rubpoi:
		dc.l	blur_updatepois

blur_doblur:		
		lea		blur_buffer,a0
		lea		2(a0),a1
		move.l	blur_screens+4,a2
	
		move.w	#$8bb8,d0
		move.w	#$8be2,d1
		
		lea		blur_bltcommands,a5
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d0,(a5)+
		
		lea		2(a0),a0
		lea		2(a1),a1
		lea		BLUR_WIDTH*BLUR_HEIGHT/4(a2),a2
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d1,(a5)+
		
		lea		BLUR_WIDTH*BLUR_HEIGHT/4-2(a0),a0
		lea		BLUR_WIDTH*BLUR_HEIGHT/4-2(a1),a1
		lea		-BLUR_WIDTH*BLUR_HEIGHT/8(a2),a2
		
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d0,(a5)+
		
		lea		2(a0),a0
		lea		2(a1),a1
		lea		BLUR_WIDTH*BLUR_HEIGHT/4(a2),a2
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d1,(a5)+

		lea		blur_c2p_smc+2,a4
		lea		blur_lerpy1,a5
		lea		blur_lerpy2,a6
		
		move.l	blur_rubpoi(pc),a2
		adda.w	#64,a2
		
		move.w	#BLUR_HEIGHT/2-1,d7
blur_update3:
		move.w	d7,-(sp)
		
		move.l	(a5)+,a0
		move.l	(a6)+,a1
		move.l	(a2),a3
		jsr		(a3)
		lea		132*5(a4),a4
		
		move.l	(a5)+,a0
		move.l	(a6)+,a1
		move.l	(a2)+,a3
		jsr		(a3)
		lea		132*5(a4),a4
		
		move.w	(sp)+,d7
		dbra	d7,blur_update3
	
		bsr.w	blur_c2p
		
		lea		blur_bltcommands,a5
		lea		$dff000,a6
		
		moveq	#blur_numblits-1,d7
blur_update4:			
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		$dff000,a6
		move.l  (a5)+,BLTAPTR(a6)
        move.l  (a5)+,BLTCPTR(a6)
        move.l  (a5)+,BLTDPTR(a6)
        move.w	(a5)+,BLTCON0(a6)
		move.w  #BLUR_WIDTH*BLUR_HEIGHT/4*16+1,BLTSIZE(a6)
		dbra	d7,blur_update4
		
		lea		blur_buffer,a0
		lea		2(a0),a1
		move.l	blur_screens+4,a2
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		; fix first byte of high bitplane, the blitter cant reach this due to shifting
		move.b	0(a0),BLUR_WIDTH*BLUR_HEIGHT*0/8(a2)
		move.b	1(a0),BLUR_WIDTH*BLUR_HEIGHT*2/8(a2)
		move.b	BLUR_WIDTH*BLUR_HEIGHT/4+0(a0),BLUR_WIDTH*BLUR_HEIGHT*1/8(a2)
		move.b	BLUR_WIDTH*BLUR_HEIGHT/4+1(a0),BLUR_WIDTH*BLUR_HEIGHT*3/8(a2)
		rts
	
;--------------------------------------------------------------------

blur_c2p:
		lea		blur_shadetab1,a0
		lea		blur_shadetab2,a1
		lea		blur_shadetab3,a2
		lea		blur_shadetab4,a3
		lea		blur_buffer+BLUR_WIDTH/2*BLUR_HEIGHT,a4
		
blur_c2p_smc:		
		REPT 	5*BLUR_HEIGHT
		
		move.w	$0(a0),d0
		or.w	$0(a1),d0
		or.w	$0(a2),d0
		or.w	$0(a3),d0
		
		move.w	$0(a0),d1
		or.w	$0(a1),d1
		or.w	$0(a2),d1
		or.w	$0(a3),d1
		
		move.w	$0(a0),d2
		or.w	$0(a1),d2
		or.w	$0(a2),d2
		or.w	$0(a3),d2
		
		move.w	$0(a0),d3
		or.w	$0(a1),d3
		or.w	$0(a2),d3
		or.w	$0(a3),d3

		move.w	$0(a0),d4
		or.w	$0(a1),d4
		or.w	$0(a2),d4
		or.w	$0(a3),d4
		
		move.w	$0(a0),d5
		or.w	$0(a1),d5
		or.w	$0(a2),d5
		or.w	$0(a3),d5
		
		move.w	$0(a0),d6
		or.w	$0(a1),d6
		or.w	$0(a2),d6
		or.w	$0(a3),d6
		
		move.w	$0(a0),d7
		or.w	$0(a1),d7
		or.w	$0(a2),d7
		or.w	$0(a3),d7

		movem.w	d0-d7,-(a4)
		
		ENDR
		
		rts
		
;--------------------------------------------------------------------
		
				cnop	0,2
blur_palids:
		dc.w	$00,$08,$10,$18,$02,$0a,$12,$1a
		dc.w	$04,$0c,$14,$1c,$06,$0e,$16,$1e
blur_palids2:
		dc.w	$00,$02,$04,$06,$08,$0a,$0c,$0e
		dc.w	$10,$12,$14,$16,$18,$1a,$1c,$1e
		
blur_fadeframe:
		dc.w	0

blur_fadecols:
		move.w	blur_fadeframe(pc),d0
		cmpi.w	#BLUR_FADEFRAMES+1,d0
		blt.b	.fadein
		cmpi.w	#BLUR_NUMFRAMES-BLUR_FADEFRAMES,d0
		bgt.b	.fadeout
		rts

.fadein:
		lsr.w	#1,d0
		move.w	#$000,d4
		moveq	#16-1,d7
		
		lea		blur_copperpal2+2,a2
		lea		blur_palids,a0
		lea 	blur_pal,a1
		bsr.b	.dofade
		rts
				
.fadeout:
		neg.w	d0
		addi.w	#BLUR_NUMFRAMES,d0
		bmi.w	.skip
		lsr.w	#1,d0

		cmpi.w	#$0f,d0
		bgt.w	.skip
				
		move.w	#$000,d4
		moveq	#16-1,d7
		lea		blur_copperpal2+2,a2
		lea		blur_palids,a0
		lea 	blur_pal,a1
		bsr.b	.dofade
		
		move.w	#$000,d4
		moveq	#16-1,d7
		lea		blur_copperpal1+2,a2
		lea		blur_palids2,a0
		lea 	blur_logo+10,a1
		bsr.b	.dofade
		rts
		
.dofade:
		move.w	d4,d5
		move.w	d5,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6
.l1:	
		move.w	(a0)+,d1
		move.w	(a1,d1.w),d1
		move.w	d1,d2
		move.w	d1,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		sub.w	d4,d1
		sub.w	d5,d2
		sub.w	d6,d3
		mulu.w	d0,d1
		mulu.w	d0,d2
		mulu.w	d0,d3
		lsr.w	#4,d1
		lsr.w	#4,d2
		lsr.w	#4,d3
		add.w	d4,d1
		add.w	d5,d2
		add.w	d6,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		or.w	d2,d1
		or.w	d3,d1
		move.w	d1,(a2)
		addq	#4,a2
		dbra	d7,.l1
.skip:
		rts

;--------------------------------------------------------------------

blur_screens:
		dc.l	blur_screen1,blur_screen2,blur_screen3

blur_dopage:
		lea 	blur_screens,a0

		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)
		
		lea		blur_copperbpl2,a6
		
		move.l	d1,d0
		move.l	d0,d2
		addi.l	#BLUR_WIDTH*BLUR_HEIGHT/4,d2
		
		move.w	d0,$06(a6)
		move.w	d0,$0e(a6)
		swap	d0
		move.w	d0,$02(a6)
		move.w	d0,$0a(a6)
		
		move.w	d2,$16(a6)
		move.w	d2,$1e(a6)
		swap	d2
		move.w	d2,$1a(a6)
		move.w	d2,$12(a6)
		
		lea		blur_mask,a0
		move.l	a0,d0
		move.w	d0,$26(a6)
		swap	d0
		move.w	d0,$22(a6)
		
		lea		blur_emptybpl,a0
		move.l	a0,d0
		move.w	d0,$2e(a6)
		move.w	d0,$36(a6)
		swap	d0
		move.w	d0,$2a(a6)
		move.w	d0,$32(a6)
		rts

;--------------------------------------------------------------------
		
		cnop	0,2
blur_sync:
		dc.w	0
		
blur_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		addq.w	#1,blur_sync
		addq.w	#1,blur_fadeframe
		
		jsr		blur_step

		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
				
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;********************************************************************
				
				section "blur_data",data

				cnop	0,2
blur_sintab:
	incbin "../data/sinplots/sintab1024.dat"
				ds.b	$600

blur_pal:
	incbin "../data/blur/pal.dat"
				dc.w	$0000
				
blur_texture:
	incbin "../data/blur/texturecomp.dat"
				ds.b	$c000
				
;********************************************************************

				section "blur_emptychip",bss,chip

				cnop	0,8
blur_screen1:	ds.b	BLUR_WIDTH*BLUR_HEIGHT/2
blur_screen2:	ds.b	BLUR_WIDTH*BLUR_HEIGHT/2
blur_screen3:	ds.b	BLUR_WIDTH*BLUR_HEIGHT/2
blur_buffer:	ds.w	BLUR_WIDTH/4*BLUR_HEIGHT
blur_mask:		ds.w	BLUR_WIDTH*BLUR_HEIGHT/4
blur_emptybpl:	ds.w	BLUR_WIDTH*BLUR_HEIGHT/4
blur_texture2:	ds.w	$8000

;********************************************************************

				section "blur_empty",bss

				cnop	0,4
blur_lerpy1:	
				ds.l	100
blur_lerpy2:	
				ds.l	100
blur_shadetab1:
				ds.w	512
blur_shadetab2:
				ds.w	512
blur_shadetab3:
				ds.w	512
blur_shadetab4:
				ds.w	512
blur_bltcommands:
				ds.w	8*blur_numblits
blur_updatecode:
				ds.b	blur_templatesize*64
blur_updatepois:
				ds.l	128
				
;********************************************************************

				section "blur_copper",data,chip
			
				cnop	0,2
blur_copperlist:
				dc.l	$008e2c81,$00902cc1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

blur_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

blur_copperpal1:
				blk.l	16,$01800000
								
blur_copperbpl1:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				
				dc.l	$01004200,$01040000						;bplcon mode, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
				dc.l	$01020000								;scroll x odd and even planes

				dc.l	$020ffffe,$009c8010						;wait x: 15, y: 33, start irq

				dc.l	$0118aaaa,$011a0000						;set mask to bpl-dma of plane5 and zero bpl-dma of plane6
				
				dc.l	$660ffffe,$01000200
blur_copperbpl2:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;7 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000,$00f40000,$00f60000
				dc.l	$00f80000,$00fa0000
blur_copperpal2:
				blk.l	16,$01800000

				dc.l	$680ffffe,$01007200						;wait x: 15, y: 1, turn on 5 bitplanes
blur_copperscale:
				blk.l	12*BLUR_HEIGHT+1,$01800000
				dc.l	$01000200								;turn off bitplanes
						
				dc.l	$fffffffe 								;wait for end
				
;--------------------------------------------------------------------
				
				cnop	0,2
blur_logo:
	incbin "../data/blur/logo.ami"
	
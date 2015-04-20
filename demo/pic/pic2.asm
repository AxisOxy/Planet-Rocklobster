width 	= 368
height	= 285
depth	= 5
bplsize	= width*height/8
	
		include "../framework/framework.i"	
		include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

	
			section	"pic_code",code 
		
entrypoint:
		bra.b	pic_start
		bra.b	pic_end
		
pic_start:
		move.l	a6,fw_jumptable
	
		bsr.w	pic_init

		lea		pic_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
	
		move.w	#TIME_PIC2_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
	
		move.l	#pic_copperlist,a0
		move.l	#pic_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		bsr.w	pic_fadein

		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#500-64,d0
		move.w	d0,pic_endframe
		rts
		
pic_end:	
		move.l	fw_jumptable,a6
		move.w	pic_endframe(pc),d0
		jsr		WAITFORFRAME(a6)	

		bsr.w	pic_fadeout
		
		jsr		SETBASECOPPER(a6)	
		rts
			
		cnop	0,4
fw_jumptable:
		dc.l	0
pic_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

pic_init:
		bsr.w	pic_initcopper
		
		lea 	pic_image,a0
		move.w	(a0)+,d0	;palette size in entries
		move.w	(a0)+,d1	;width of bitplane in bytes
		move.w	(a0)+,d2	;size of bitplane in bytes
		move.l	(a0)+,d3	;size of image in bytes
		
		lea		$dff180,a1
		ext.l	d0
		subq.l	#1,d0
.l0:	
		addq	#2,a0
		dbra	d0,.l0
		
		move.l	a0,d0
		
		lea		pic_copperbpl,a0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		addi.l	#bplsize*1,d1
		addi.l	#bplsize*2,d2
		addi.l	#bplsize*3,d3
		addi.l	#bplsize*4,d4
		move.w	d0,$06(a0)
		move.w	d1,$0e(a0)
		move.w	d2,$16(a0)
		move.w	d3,$1e(a0)
		move.w	d4,$26(a0)
		swap	d0
		swap	d1
		swap	d2
		swap	d3
		swap	d4
		move.w	d0,$02(a0)
		move.w	d1,$0a(a0)
		move.w	d2,$12(a0)
		move.w	d3,$1a(a0)
		move.w	d4,$22(a0)
		rts

;--------------------------------------------------------------------

pic_initcopper:
		lea		pic_coppertech,a0
		move.l	#$1c0ffffe,d0
		move.w	#height-1,d7
.l0:		
		move.l	d0,(a0)+
		move.w	#$0102,(a0)+
		clr.w	(a0)+		
		
		addi.l	#$01000000,d0
		cmpi.l	#$000ffffe,d0
		bne.b	.wrap
		move.l	#$ffdffffe,(a0)+
.wrap:
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

		cnop	0,2
pic_rndpoi:
		dc.w	0

 MACRO<PIC_TECH>		
		moveq	#0,d1
		move.b	(a0,d4.w),d1
		addq	#6,d4
		andi.w	#$ff,d4
		
		lsr.w	#3,d1
		mulu.w	d3,d1
		asr.l	#4,d1
		sub.w	d5,d1
		move.w	d1,d2
		lsl.w	#4,d2
		or.w	d2,d1
		move.w	d1,(a1)
		addq	#8,a1
 ENDM
		
pic_updatecopper:
		move.w	pic_rndpoi(pc),d4
		addi.w	#4,d4
		andi.w	#$ff,d4
		move.w	d4,pic_rndpoi

		lea		pic_rndtab,a0
		lea		pic_coppertech+6,a1
		moveq	#16,d3
		sub.w	d0,d3
		bpl.b	.clip
		moveq	#0,d3
.clip:
		move.w	d3,d5
		lsr.w	#1,d5
		subi.w	#8,d5
		
		move.w	#256-28-1,d7
.l0:
		PIC_TECH
		dbra	d7,.l0
		
		addq	#4,a1
		
		move.w	#height-(256-28)-1,d7
.l1:
		PIC_TECH
		dbra	d7,.l1
		rts

;--------------------------------------------------------------------

pic_fadein:
		moveq	#0,d0
.l0:
		move.w	d0,-(sp)

		move.w	#$6ae,d4
		bsr.w	pic_fade
		bsr.w	pic_updatecopper
		
		move.w	(sp)+,d0
		
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
	
		addq	#1,d0
		cmpi.w	#65,d0
		bne.b	.l0
		rts
		
;--------------------------------------------------------------------

pic_fadeout:
		moveq	#64-1,d0
.l0:
		move.w	d0,-(sp)

		move.w	#$fff,d4
		bsr.w	pic_fade
		bsr.w	pic_updatecopper
	
		move.w	(sp)+,d0
		
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
			
		subq	#1,d0
		bpl.b	.l0
		rts

;--------------------------------------------------------------------
	
pic_fade:
		lsr.w	#2,d0

		lea 	pic_image,a0
		move.w	(a0)+,d7	;palette size in entries
		addq.l	#8,a0
		
		move.w	d4,d5
		move.w	d5,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6
		
		lea		$dff180,a1
		ext.l	d7
		subq.l	#1,d7
.l0:	
		move.w	(a0)+,d1
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

		move.w	d1,(a1)+
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

pic_irq:		
		movem.l	d0-d7/a0-a6,-(sp)
		
		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)

		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  

;********************************************************************
				
				section "pic_data",data

pic_rndtab:
	incbin "../data/pic/sin.dat"

;********************************************************************

				section "pic_copper",data,chip

pic_copperlist:	dc.l	$008e1c81,$009038d1,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

pic_copperbpl:	dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000

pic_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
			
				dc.l	$1b0ffffe,$009c8010						;start irq
				
pic_coppermove:
				dc.l	$1c0ffffe,$01005200						;wait x: 15, y: 1, turn on 5 bitplanes
				
pic_coppertech:
				blk.l	height*2+1,$01800000

				dc.l	$fffffffe 								;wait for end

;--------------------------------------------------------------------
				
				cnop	0,8
pic_image:
	incbin "../data/pic/pic2.ami"

CITY_NUMFRAMES = 1105
	
	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

	
			section	"city_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable
		
		;detect aga
		moveq	#0,d1
		move.w 	$dff004,d0
		and.w 	#$6f00,d0                      ; 0110111100000000
		cmp.w 	#$2200,d0                      ; 0010001000000000
		beq.b 	.aga
		cmp.w 	#$2300,d0                      ; 0010001100000000
.aga: 
		seq 	d1
		tst.w	d1
		beq.b	.noaga
		move.w	#$5200,city_agafix+2			;if we have aga, we need to set a correct 5 bitplane mode. saves some mem and reduces dma.
		move.w	#$2c33,city_waitpos
.noaga:
		
		bsr.w	city_init

		bsr.w	city_clearclip
		bsr.w	city_move
		bsr.w	city_update
		bsr.w	city_move
		bsr.w	city_dopage
				
		lea		city_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		move.w	#TIME_CITY_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
				
		move.l	#city_copperlist,a0
		move.l	#city_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
				
		bsr.w	city_fadeincopper
				
		clr.w	city_frame
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#CITY_NUMFRAMES,d0
		move.w	d0,city_endframe
		
		move.w	#1,city_domove
		
city_main:
		;move.w	#$0008,$dff180
		bsr.w	city_update
		;move.w	#$000,$dff180
		
.sync:
		;tst.w	city_sync
		;beq.b	.sync
		
		move.w	city_sync,d0
		add.w	d0,d0
		lea		city_coltab,a0
		;move.w	(a0,d0.w),$dff180
		clr.w	city_sync
	
		move.l	fw_jumptable,a6
		;jsr		VSYNC(a6)

		bsr.w	city_dopage
		
		btst	#$06,$bfe001
		beq.b	city_end
		
		move.w	city_endframe,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	city_main
city_end:
		clr.w	city_domove

		bsr.w	city_fadeoutcopper
		
		;move.l	fw_jumptable,a6
		;jsr		SETBASECOPPER(a6)
		rts		
	
		cnop	0,4
fw_jumptable:
		dc.l	0
city_endframe:
		dc.w	0
		
city_coltab:
		dc.w	$0000,$0fff,$0f00,$00ff,$0f0f,$00f0,$00f,$0ff0

;--------------------------------------------------------------------

city_init:
		lea		city_sintab,a0
		lea		$800(a0),a1
		move.l	a1,a2
		lea		$1000(a0),a3
		move.l	a3,a4
		move.w	#$1ff,d7
.sl0:	
		move.w	(a0)+,d0
		move.w	d0,-(a1)
		move.w	d0,(a4)+
		
		neg.w	d0
		move.w	d0,(a2)+
		move.w	d0,-(a3)
		dbra	d7,.sl0

		bsr.w	city_initpal
		bsr.w	city_initlerp
		bsr.w	city_inittabs
		bsr.w	city_genrender
		
		lea		city_texture,a0
		lea		city_texture1,a1
		lea		city_texture2,a2
		lea		city_texture3,a3
		lea		city_texture4,a4
		moveq	#$0,d7
.l1:
		moveq	#0,d0
		move.b	(a0)+,d0
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
		
		move.w	d7,d6
		add.w	d6,d6
		moveq	#0,d5
		move.w	d6,d5
		
		move.w	d0,(a1)+
		lsr.w	#2,d0
		move.w	d0,(a2)+
		lsr.w	#2,d0
		move.w	d0,(a3)+
		lsr.w	#2,d0
		move.w	d0,(a4)+
		
		addq	#1,d7
		cmpi.w	#$4000,d7
		bne.b	.l1
		
		lea		city_mask,a0
		move.w	#$aaaa,d0
		move.w	#2*bltsize/2-1,d7
.l2:	
		move.w	d0,(a0)+
		dbra	d7,.l2
		
		lea		city_scrambletab,a0
		lea		city_smc+2,a1
		moveq	#0,d0
		move.w	#CITY_WIDTH-1,d7
.l4:
		move.w	d0,d1
		eori.w	#$1f,d1
		move.w	d0,d2
		lsr.w	#5,d2
		add.w	d2,d1
		lsl.w	#2,d1
		lea		(a1,d1.w),a2
		move.l	a2,(a0)+
		addq	#1,d0
		dbra	d7,.l4
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)

		lea		$dff000,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		move.w	#2,BLTAMOD(a6)
		move.w	#2,BLTCMOD(a6)
		clr.w	BLTCON1(a6)
		move.w	#$ff00,BLTBDAT(a6)
		
				
		bsr.w	city_initlogo
		rts

;--------------------------------------------------------------------

city_initlogo:
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
		lea		city_copperbpl2,a6
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

city_updatefadelogo:
		move.w	city_frame(pc),d0
		cmpi.w	#34,d0
		bgt.b	.skip
		lsr.w	#1,d0
		moveq	#0,d4
		bsr.w	.dofade
		rts
		
.dofade:
		lea		blur_logo+10,a0
		lea		city_coppercols2+2,a1
		
		move.w	d4,d5
		move.w	d5,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6
		moveq	#16-1,d7
.l1:	
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
		move.w	d1,(a1)
		addq	#4,a1
		dbra	d7,.l1
.skip:
		rts
		
;--------------------------------------------------------------------
				
		cnop	0,2
city_waitpos:
		dc.w	$2c35
city_copperpattern:
		dc.w	0,0,0,2,0,0,2,0,2,2,0,2,2,2
city_copperbar:
		dc.w	$77a,$88a,$99a,$baa,$cba,$dca,$ca9,$b88
		dc.w	$344,$455,$566,$677,$788,$899,$9aa,$abb,$bcc,$cdd,$dee
		
city_initcopper:
		lea		city_copperbar,a1
		lea		city_copperpattern,a2
		lea		city_copperbarbig,a0
		moveq	#0,d1
		moveq	#0,d2
		move.w	#(CITY_HEIGHT-1)*2-1,d7
.l0:
		move.w	(a2,d2.w),d3
		add.w	d1,d3
		move.w	(a1,d3.w),(a0)+

		cmpi.w	#47*2,d7
		bne.b	.nohorizon
		moveq	#0,d2
		moveq	#8*2,d1
.nohorizon:
		addq	#2,d2
		cmpi.w	#14*2,d2
		bne.b	.lskipinc
		moveq	#0,d2
		addq	#2,d1
.lskipinc:
		dbra	d7,.l0
		
		lea		city_copperscale,a0
		lea		city_copperbarbig,a1
		move.w	city_waitpos(pc),d0
		swap	d0
		move.w	#$fffe,d0
		move.l	#$2cdffffe,d4
		
		move.w	#(CITY_HEIGHT-1)-1,d7
.l1:
		move.l	d0,(a0)+
		move.l	#$0108ffd8,(a0)+
		move.l	#$010affd8,(a0)+
		move.l	#$01020032,(a0)+
		move.l	#$01800000,(a0)+
		move.l	d4,(a0)+
		move.l	#$01800000,(a0)+
		addi.l	#$01000000,d0
		addi.l	#$01000000,d4
				
		move.l	d0,(a0)+
		move.l	#$01080000,(a0)+
		move.l	#$010a0000,(a0)+
		move.l	#$01020043,(a0)+
		move.l	#$01800000,(a0)+
		move.l	d4,(a0)+
		move.l	#$01800000,(a0)+
		addi.l	#$01000000,d0
		addi.l	#$01000000,d4
		dbra	d7,.l1		
		
		move.l	#$01000200,(a0)+	;turn off bitplanes
		rts
	
;--------------------------------------------------------------------

city_fadeincopper:
		bsr.w	city_initcopper
		
		move.w	#160-1,d7
.l0:
		move.w	d7,-(sp)
		
		bsr.w	city_updatefade
	
		move.w	(sp)+,d7
		dbra	d7,.l0
		rts
	
;--------------------------------------------------------------------

city_fadeoutcopper:
		moveq	#0,d7
.l0:
		move.w	d7,-(sp)
		
		bsr.w	city_updatefade
	
		move.w	(sp)+,d7
		addq	#1,d7
		cmpi.w	#160,d7
		bne.b	.l0
		rts

;--------------------------------------------------------------------
	
city_updatefade:
		bsr.w	.clear
		
		move.w	#160-1,d0
		sub.w	d7,d0
		lsl.w	#5,d0
		andi.w	#$ffe,d0

		move.l	#$00008000,d5
		move.l	#(CITY_HEIGHT-2)*256*2,d6

		lea		city_sintab+$000,a2
		move.w	(a2,d0.w),d0
		muls.w	#(CITY_HEIGHT-1)*4+1,d0
		swap	d0
		move.w	#CITY_HEIGHT-1,d4
		move.w	#CITY_HEIGHT-1,d7
		sub.w	d0,d4
		add.w	d0,d7
		cmp.w	d4,d7
		bpl.b	.noswap
		exg		d4,d7
		neg.l	d6
		move.l	#$8000+(CITY_HEIGHT-1)*65536*2,d5
.noswap:
		tst.w	d4
		bpl.b	.cliptop
		moveq	#0,d4
.cliptop:
		cmpi.w	#CITY_HEIGHT*2-2,d7
		blt.b	.clipbottom
		move.w	#CITY_HEIGHT*2-2,d7
.clipbottom:

		sub.w	d4,d7
		beq.b	.skip

		divs.w	d7,d6
		ext.l	d6
		lsl.l	#8,d6
		
		mulu.w	#7*4,d4
		
		bsr.w	.dofade
.skip:
		
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
		rts
	
.clear:
		lea		city_copperscale+18,a0
		move.w	#(CITY_HEIGHT-1)*2-1,d6
.l3:
		clr.w	(a0)
		lea		7*4(a0),a0
		
		dbra	d6,.l3
		rts
		
.dofade:	
		lea		city_copperscale+18,a0
		lea		city_copperbarbig,a1
		adda.w	d4,a0
		subq	#1,d7
		bmi.b	.end
.l4:
		moveq	#0,d3
		move.l	d5,d1
		swap	d1
		cmpi.w	#CITY_HEIGHT*2-4,d1
		bhi.b	.skip1
		add.w	d1,d1
		move.w	(a1,d1.w),d3
.skip1:
		move.w	d3,(a0)
		lea		7*4(a0),a0
		
		add.l	d6,d5
		dbra	d7,.l4
.end:
		rts

;--------------------------------------------------------------------

city_initlerp:
		lea		city_lerptab,a0
		lea		city_lerppois,a2
		moveq	#0,d7
.l0:
		move.l	a0,(a2)+

		move.w	d7,d0
		beq.b	.skip
		
		move.l	#127*256,d1
		divs.w	d0,d1
		
		ext.l	d1
		lsl.l	#8,d1
		move.l	#$8000,d2
		subq	#1,d0
		bmi.b	.skip
.l2:
		move.l	d2,d3
		swap	d3
		add.w	d3,d3
		move.w	d3,(a0)+
		
		add.l	d1,d2
		
		dbra	d0,.l2
.skip:
		addq	#1,d7
		cmpi.w	#CITY_HEIGHT*2,d7
		bne.b	.l0
		rts
				
;--------------------------------------------------------------------

city_inittabs:
		lea		city_heighttab,a0
		lea		city_offsettab,a1
		moveq	#0+1,d0
		moveq	#0,d1
		
		move.w	#CITY_HEIGHT-1,d7
.l0:
		move.w	d0,d2
		cmpi.w	#1,d2
		bne.b	.clip
		move.w	#0,d2
.clip:
		move.w	d2,(a0)+
		
		move.l	d1,(a1)+
		
		addi.w	#64,d0
		addi.l	#CITY_PATCHMOD,d1
						
		dbra	d7,.l0
		
		lea		city_persptab+1*2,a0
		move.l	#CITY_AU*16384,d1
		moveq	#1,d7
.l1:		
		move.l	d1,d0
		divs.w	d7,d0
		move.w	d0,(a0)+
				
		addq	#1,d7
		cmpi.w	#$4000,d7
		bne.b	.l1
		
		lea		city_reciproctab+1*2,a0
		move.l	#256*128,d1
		moveq	#1,d7
.l2:		
		move.l	d1,d0
		divs.w	d7,d0
		move.w	d0,(a0)+
				
		addq	#1,d7
		cmpi.w	#$1000,d7
		bne.b	.l2
		rts
		
;--------------------------------------------------------------------
		
		cnop	0,2
city_palids:
		dc.w	$00,$08,$10,$18,$02,$0a,$12,$1a
		dc.w	$04,$0c,$14,$1c,$06,$0e,$16,$1e

city_initpal:
		lea		city_palids,a0
		lea		city_pal,a1
		lea		$dff180+$20,a2
		lea		city_coppercols1,a3
		move.w	#$0180,d0
		moveq	#16-1,d7
.l0:	
		move.w	(a0)+,d1
		move.w	(a1,d1.w),d1
		move.w	(a1),(a2)+
		move.w	d0,(a3)+
		addq	#2,d0
		move.w	d1,(a3)+
		dbra	d7,.l0
		
		lea		city_coppercols2,a1
		move.w	#$0180,d0
		moveq	#16-1,d7
.l1:	
		move.w	d0,(a1)+
		addq	#2,d0
		clr.w	(a1)+

		dbra	d7,.l1
		rts

;--------------------------------------------------------------------

city_screens:
		dc.l	city_screen1,city_screen2,city_screen3

city_dopage:
		lea 	city_screens,a0
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)
		
		lea		city_copperbpl,a6
		
		addi.l	#40,d1
		move.l	d1,d0
		move.l	d0,d2
		addi.l	#2*bltsize,d2
		
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
		
		lea		city_mask,a0
		move.l	a0,d0
		move.w	d0,$26(a6)
		swap	d0
		move.w	d0,$22(a6)
		rts

;--------------------------------------------------------------------
		
		cnop	0,4
city_sync:
		dc.w	0
city_frame:
		dc.w	0
city_domove:
		dc.w	0
		
city_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
				
		addq.w	#1,city_sync
		addq.w	#1,city_frame
		
		tst.w	city_domove
		beq.b	.skip
		bsr.w	city_move
.skip:		

		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
	
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
				
;--------------------------------------------------------------------

CITY_WIDTH 	= 160
CITY_HEIGHT	= 98

bltsize	= CITY_WIDTH*CITY_HEIGHT/8

city_update:
		bsr.w	city_rotate
		bsr.w	city_sort
		bsr.w	city_draw
		bsr.w	city_clear
		bsr.w	city_stopdraw
		bsr.w	city_prepareblits
		bsr.w	city_render
		bsr.w	city_blit
		bsr.w	city_updatefadelogo
		rts

;--------------------------------------------------------------------

city_move:
		move.w	city_frame(pc),d0
		
		cmpi.w	#128,d0
		bge.b	.fadeout
		
		bra.b	.do
		rts

.fadeout:
		neg.w	d0
		addi.w	#CITY_NUMFRAMES,d0
		cmpi.w	#128,d0
		bge.b	.skip
		
.do:
		lsl.w	#3,d0
		lea		city_sintab+$000,a0
		move.w	(a0,d0.w),d0
		neg.w	d0
		addi.w	#$4000,d0
		asr.w	#7,d0
		addi.w	#CITY_WIDTH/2,d0
		move.w	d0,city_centerx
.skip:
		
		move.w	city_ry(pc),d7
		addi.w	#RY_SPEED,d7
		move.w	d7,city_ry

		move.w	city_movey(pc),d6
		addi.w	#MOVEY_SPEED,d6
		move.w	d6,city_movey

		move.w	city_movez(pc),d5
		addi.w	#MOVEZ_SPEED,d5
		move.w	d5,city_movez
		
		move.w	city_movex(pc),d4
		addi.w	#MOVEX_SPEED,d4
		move.w	d4,city_movex
		rts
		
;--------------------------------------------------------------------

CITY_VERTEX_STRIDE	= 8
CITY_ENDMARK		= $0000
 
CITY_MAXPOINTS	= 128
CITY_AU			= 150
CITY_TF			= 450

RY_SPEED		= $1c/3
MOVEX_SPEED		= $1f/3
MOVEY_SPEED		= $42/3
MOVEZ_SPEED		= $22/3
OFFSETFRAMES 	= 290*3

		cnop	0,2
city_ry:
		dc.w	RY_SPEED*OFFSETFRAMES
city_movex:
		dc.w	MOVEX_SPEED*OFFSETFRAMES+950
city_xpos:	
		dc.w	0
city_movey:
		dc.w	MOVEY_SPEED*OFFSETFRAMES
city_ypos:	
		dc.w	0
city_movez:
		dc.w	MOVEZ_SPEED*OFFSETFRAMES
city_zpos:	
		dc.w	0
city_centerx:
		dc.w	0
		
CITY_NUMXS		= (city_xs_end-city_xs)/2
CITY_NUMZS		= (city_zs_end-city_zs)/2
CITY_NUMPOINTS 	= (city_points_end-city_points)/8
CITY_NUMINDICES = (city_indices_end-city_indices)/16
	
city_xs:
		incbin "../data/city/xcoords.dat"
city_xs_end:

city_zs:
		incbin "../data/city/zcoords.dat"
city_zs_end:
		
city_destxs:
		ds.w	CITY_NUMXS*4
city_destzs:
		ds.w	CITY_NUMZS*4
		
city_points:
		incbin "../data/city/vertices.dat"
city_points_end:
		
city_indices:
		incbin "../data/city/indices.dat"
city_indices_end:
		
city_rotate:
		move.w	city_ry(pc),d7
		move.w	city_movey(pc),d6
		move.w	city_movez(pc),d5
		move.w	city_movex(pc),d4
		andi.w	#$ffe,d4
		andi.w	#$ffe,d5
		andi.w	#$ffe,d6
		andi.w	#$ffe,d7
		
		lea		city_sintab,a0
		
		move.w	(a0,d6.w),d6
		asr.w	#8,d6
		addi.w	#$58,d6
		move.w	d6,city_ypos
		
		move.w	(a0,d5.w),d5
		addi.w	#$4000,d5
		lsr.w	#7,d5
		move.w	d5,city_zpos
	
		move.w	(a0,d4.w),d4
		asr.w	#6,d4
		move.w	d4,city_xpos
		
		move.w	(a0,d7.w),d0
		addi.w	#$400,d7
		andi.w	#$ffe,d7
		move.w	(a0,d7.w),d1
		
		lea		city_xs,a0
		lea		city_destxs,a1
		moveq	#CITY_NUMXS-1,d7
.l0:
		move.w	(a0)+,d2
		move.w	d2,d3
		muls.w	d0,d2
		muls.w	d1,d3
		swap	d2
		swap	d3
		move.w	d2,(a1)+
		move.w	d3,(a1)+
		neg.w	d2
		neg.w	d3
		move.w	d2,(a1)+
		move.w	d3,(a1)+
		dbra	d7,.l0
		
		lea		city_zs,a0
		lea		city_destzs,a1
		moveq	#CITY_NUMZS-1,d7
.l1:
		move.w	(a0)+,d2
		move.w	d2,d3
		muls.w	d0,d2
		muls.w	d1,d3
		swap	d2
		swap	d3
		move.w	d2,(a1)+
		move.w	d3,(a1)+
		neg.w	d2
		neg.w	d3
		move.w	d2,(a1)+
		move.w	d3,(a1)+
		dbra	d7,.l1

		lea		city_points,a0
		lea		city_dstpoints,a1
		lea		city_destxs,a2
		lea		city_destzs,a3
		lea		city_persptab,a4
		lea		$dff002,a5
		lea		city_scrambletab,a6
		move.w	#CITY_AU+CITY_TF,d0
		add.w	city_zpos(pc),d0
		move.w	city_centerx(pc),d1
.l2:
		move.w	(a0)+,d6	;x
		bmi.b	.end
		move.w	(a0)+,d4	;z

		movem.w	(a2,d6.w),d2/d6	;x*cy/x*sy
		movem.w	(a3,d4.w),d3/d4	;z*sy/z*cy
		
		add.w	d4,d2		;x*sy+z*cy
		sub.w	d3,d6		;x*cy-z*sy
		
		move.w	city_ypos(pc),d3
		move.w	(a0)+,d4	;y1
		move.w	(a0)+,d5	;y2
		add.w	d3,d4
		add.w	d3,d5
		
		add.w	d0,d6		;z+au+tf

		add.w	d6,d6
		move.w	(a4,d6.w),d7	;au/(z+au+tf)
	
		add.w	city_xpos(pc),d2
	
		add.w	d2,d2
		add.w	d2,d2		;x*=4
						
		muls.w	d7,d2
		muls.w	d7,d4
		muls.w	d7,d5
		swap	d2			;x*au/(z+au+tf)
		swap	d4			;y1*au/(z+au+tf)
		swap	d5			;y1*au/(z+au+tf)
		
		add.w	d1,d2
							;x*au/(z+au+tf)+centerx/2
		add.w	#CITY_HEIGHT/2,d4		;y1*au/(z+au+tf)+centery/2
		add.w	#CITY_HEIGHT/2,d5		;y2*au/(z+au+tf)+centery/2
		
		movem.w	d2/d4-d6,(a1)	;x/y1/y2/z
		addq	#8,a1

		bra.b	.l2
.end:
		REPT	4
		move.w	#CITY_ENDMARK,(a1)+
		ENDR
		
		move.w	#(160-CITY_NUMPOINTS)-1,d7
.l3:	
		dbra	d7,.l3
		rts
		
;--------------------------------------------------------------------

city_sort:
		lea		city_dstpoints+6,a0
		lea		city_polyzs,a1
		moveq	#0,d1
.l0:
		move.w	(a0),d0
		cmpi.w	#CITY_ENDMARK,d0
		beq.b	.end

		add.w	CITY_VERTEX_STRIDE*1(a0),d0
		add.w	CITY_VERTEX_STRIDE*2(a0),d0
		add.w	CITY_VERTEX_STRIDE*3(a0),d0
		lsr.w	#7,d0
		add.w	d0,d0
		move.w	d0,(a1)+
		addq	#1,d1
		
		adda.w	#CITY_VERTEX_STRIDE*4,a0
		bra.b	.l0
.end:
		clr.w	(a1)+
		
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		lea		city_sortbuf1+128*2+4,a0
		REPT	128/16
		movem.l	d0-d7,-(a0)
		ENDR
		move.l	d0,-(a0)	
			
		lea		city_polyzs,a0
		lea		city_sortbuf1,a1
.l1:
		move.w	(a0)+,d0
		beq.b	.end2
		addq.w	#2,(a1,d0.w)
		bra.b	.l1
.end2:

		moveq	#0,d0
		lea		city_sortbuf1,a0
		lea		city_sortbuf2,a1
		moveq	#128-1,d7
.l2:
		move.w	d0,(a1)+
		add.w	(a0)+,d0
		dbra	d7,.l2
		
		lea		city_polyzs,a0
		lea		city_sortbuf2,a1
		lea		city_sortbuf3,a2
		moveq	#0,d3
		moveq	#0,d2
.l3:		
		move.w	(a0)+,d0
		beq.w	.end3
		move.w	(a1,d0.w),d1
		move.w	d3,(a2,d1.w)
		addi.w	#16,d3
		addq	#2,d1
		move.w	d1,(a1,d0.w)
		bra.b	.l3
.end3:
		lsr.w	#3,d3
		move.w	#$ffff,(a2,d3.w)
		rts

;--------------------------------------------------------------------

city_clear:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a5
		move.w	#$ffff,BLTAFWM(a5)
		move.w	#$ffff,BLTALWM(a5)
		move.w	#CITY_PATCHMOD-2,BLTDMOD(a5)
		move.l	#$01f00000,BLTCON0(a5)
		clr.w	BLTADAT(a5)
		
		lea		BLTBASE+2,a5
		lea		city_scrambletab,a6
		lea		city_clipbuf,a0
		lea		city_clipbuf+CITY_WIDTH*2,a4
		lea		city_offsettab,a1
		lea		city_heighttab,a2
	
		move.w	#160-1,d7
.l0:
		move.w	(a0)+,d0
		beq.b	.skip1
		clr.b	d0
		lsr.w	#6,d0
		move.w	#(CITY_HEIGHT-1)*4,d1
		sub.w	d0,d1
		lsr.w	#1,d1
		move.l	(a6),a3
		adda.l	(a1,d0.w),a3
		move.w	(a2,d1.w),d1
		beq.b	.skip1
	
		move.w	#$8400,$96-2(a5)
.bltwait1:
		btst	#$0e,(a5)
		bne.b	.bltwait1
		move.w	#$0400,$96-2(a5)
		
		move.l	a3,BLTDPTR-2(a5)
		move.w	d1,BLTSIZE-2(a5)
.skip1:		
		move.w	(a4)+,d0
		clr.b	d0
		lsr.w	#7,d0
		move.l	(a6)+,a3
		move.w	(a2,d0.w),d0
		beq.b	.skip2
		
		move.w	#$8400,$96-2(a5)
.bltwait2:
		btst	#$0e,(a5)
		bne.b	.bltwait2
		move.w	#$0400,$96-2(a5)
		
		move.l	a3,BLTDPTR-2(a5)
		move.w	d0,BLTSIZE-2(a5)
.skip2:		
		dbra	d7,.l0
	
city_clearclip:
		lea		city_clipbuf+CITY_WIDTH*4,a0
		move.w	#(CITY_HEIGHT-1)*256,d0
		move.w	d0,d1
		swap	d0
		move.w	d1,d0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		move.l	d0,d5
		move.l	d0,d6
		move.l	d0,d7
		
		REPT	CITY_WIDTH/16
		movem.l	d0-d7,-(a0)
		ENDR

		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		
		REPT	CITY_WIDTH/16
		movem.l	d0-d7,-(a0)
		ENDR
		rts

;--------------------------------------------------------------------

city_startdraw:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a5
		move.w	#$ffff,BLTAFWM(a5)
		move.w	#$ffff,BLTALWM(a5)
		move.w	#CITY_PATCHMOD-2,BLTDMOD(a5)
		clr.w	BLTAMOD(a5)
		move.l	#$09fa0000,BLTCON0(a5)
		rts
		
;--------------------------------------------------------------------

city_stopdraw:
		move.l	fw_jumptable(pc),a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a5
		clr.w	BLTDMOD(a5)
		move.w	#$ffff,BLTAFWM(a5)
		move.w	#$ffff,BLTALWM(a5)
		move.w	#2,BLTAMOD(a5)
		move.w	#2,BLTCMOD(a5)
		clr.w	BLTCON1(a5)
		move.w	#$ff00,BLTBDAT(a5)
		rts

;--------------------------------------------------------------------

city_draw:
		bsr.w	city_startdraw
		
		lea		city_sortbuf3,a1		
.l0:
		move.w	(a1)+,d0
		bmi.b	.end
		lea		city_indices,a0
		adda.w	d0,a0
		move.l	a1,-(sp)
		bsr.w	city_dohouse
		move.l	(sp)+,a1
		bra.b	.l0
.end:	
		rts
		
;--------------------------------------------------------------------

city_dohouse:
		move.w	#$0100,d6
		bsr.b	city_doline
		move.w	#$8100,d6
		bsr.b	city_doline
		move.w	#$0100,d6
		bsr.b	city_doline
		move.w	#$8100,d6
		bra.b	city_doline
		
;--------------------------------------------------------------------

CITY_PATCHMOD	= CITY_WIDTH*4+CITY_WIDTH/32*4

		cnop	0,2
city_stepu:
		dc.w	0

city_doline:
		lea		city_dstpoints,a6
		move.w	(a0)+,d7
		movem.w	(a6,d7.w),d0/d1/d4
		move.w	(a0)+,d7
		movem.w	(a6,d7.w),d2/d3/d5
		move.l	a0,-(sp)
	
		cmp.w	d0,d2
		ble.w	.skip
		
		tst.w	d2
		bmi.w	.skip
		cmpi.w	#CITY_WIDTH-1,d0
		bge.w	.skip
		
		move.w	d2,a5
		sub.w	d0,d2
		sub.w	d1,d3
		sub.w	d4,d5
		
		lea		city_reciproctab,a0
		add.w	d2,d2
		move.w	(a0,d2.w),d7
		
		muls.w	d7,d3
		muls.w	d7,d5
		asr.l	#7,d3
		asr.l	#7,d5
		
		lsl.w	#8,d1
		lsl.w	#8,d4
		move.b	#$80,d1
		move.b	d1,d4
		move.w	d7,city_stepu
		
		move.w	a5,d2
		cmpi.w	#CITY_WIDTH,d2
		blt.b	.noclipright
		move.w	#CITY_WIDTH,d2
.noclipright:
		tst.w	d0
		bge.b	.noclipleft
		neg.w	d0
		subq	#1,d0
.cl0:
		add.w	d3,d1	;y1
		add.w	d5,d4	;y2
		add.w	d7,d6	;u
	
		dbra	d0,.cl0
		
		moveq	#0,d0
.noclipleft:

		sub.w	d0,d2
		subq	#1,d2
		bmi.w	.skip
		
		add.w	d0,d0
		lea		city_clipbuf,a6
		adda.w	d0,a6
		add.w	d0,d0
		lea		city_scrambletab,a2
		adda.w	d0,a2
			
		lea		city_lerppois,a3
		lea		city_offsettab,a4
		lea		city_heighttab,a5
		lea		BLTBASE+2,a0			
.l0:				
		move.w	(a6)+,d7
		cmp.w	d7,d4
		blt.b	.skipline

		move.w	d4,d0
		sub.w	d1,d0
		clr.b	d0
		lsr.w	#6,d0
		move.l	(a3,d0.w),a1

		move.w	d1,d0
		cmp.w	d7,d0
		bgt.b	.nocliptop
		sub.w	d7,d0
		asr.w	#7,d0
		suba.w	d0,a1
		move.w	d7,d0
.nocliptop:

		move.w	d4,d7
		cmpi.w	#(CITY_HEIGHT-1)*256,d7
		blo.b	.noclipbottom1
		move.w	#(CITY_HEIGHT-1)*256,d7
.noclipbottom1:
	
		cmp.w	-2(a6),d7
		blt.b	.nowriteclipback
		move.w	d7,-2(a6)
.nowriteclipback:

		cmp.w	CITY_WIDTH*2-2(a6),d0
		bgt.b	.nowriteclipback2
		move.w	d0,CITY_WIDTH*2-2(a6)
.nowriteclipback2:
		
		clr.b	d0
		clr.b	d7
		sub.w	d0,d7
	
		move.w	#$8400,$96-2(a0)
.bltwait:
		btst	#$0e,(a0)
		bne.b	.bltwait	
		move.w	#$0400,$96-2(a0)
		
		move.l	a1,BLTAPTR-2(a0)

		lsr.w	#6,d0
		move.l	(a2),a1
		adda.l	(a4,d0.w),a1
		move.l	a1,BLTDPTR-2(a0)
		
		move.w	d6,d0
		lsr.w	#1,d0
		clr.b	d0
		move.w	d0,BLTCDAT-2(a0)
		
		lsr.w	#7,d7
		move.w	(a5,d7.w),d7
		beq.b	.skipline
		move.w	d7,BLTSIZE-2(a0)
.skipline:
		
		addq	#4,a2
		add.w	d3,d1	;y1
		add.w	d5,d4	;y2
		add.w	city_stepu(pc),d6	;u
	
		dbra	d2,.l0
.skip:
		move.l	(sp)+,a0
		rts
			
;--------------------------------------------------------------------

city_prepareblits:
		lea		city_buffer,a0
		lea		2(a0),a1
		move.l	city_screens+4,a2
	
		move.w	#$8bb8,d0
		move.w	#$8be2,d1
		
		lea		city_bltcommands,a5
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d0,(a5)+
		
		lea		2(a0),a0
		lea		2(a1),a1
		lea		2*bltsize(a2),a2
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d1,(a5)+
		
		lea		2*bltsize-2(a0),a0
		lea		2*bltsize-2(a1),a1
		lea		-2*bltsize+bltsize(a2),a2
		
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d0,(a5)+
		
		lea		2(a0),a0
		lea		2(a1),a1
		lea		2*bltsize(a2),a2
		move.l	a1,(a5)+
		move.l	a0,(a5)+
		move.l	a2,(a5)+
		move.w	d1,(a5)+
		rts

;--------------------------------------------------------------------

city_genrender:
		lea		city_rendercode,a0
		move.w	#CITY_WIDTH*CITY_HEIGHT/32-1,d7
.l0:	
		lea		city_rendertemplate,a1
		moveq	#CITY_RENDERTEMPLATE_SIZE/2-1,d6
.l1:
		move.w	(a1)+,(a0)+
		dbra	d6,.l1

		dbra	d7,.l0
		
		move.w	#$4e75,(a0)+	;rts
		
		lea		city_rendercode,a0
		rts
				
CITY_RENDERTEMPLATE_SIZE = city_rendertemplateend-city_rendertemplate
				
city_rendertemplate:
		move.w	$0000(a0),d0
		or.w	$0000(a1),d0
		or.w	$0000(a2),d0
		or.w	$0000(a3),d0
		
		move.w	$0000(a0),d1
		or.w	$0000(a1),d1
		or.w	$0000(a2),d1
		or.w	$0000(a3),d1
		
		move.w	$0000(a0),d2
		or.w	$0000(a1),d2
		or.w	$0000(a2),d2
		or.w	$0000(a3),d2
		
		move.w	$0000(a0),d3
		or.w	$0000(a1),d3
		or.w	$0000(a2),d3
		or.w	$0000(a3),d3

		move.w	$0000(a0),d4
		or.w	$0000(a1),d4
		or.w	$0000(a2),d4
		or.w	$0000(a3),d4
		
		move.w	$0000(a0),d5
		or.w	$0000(a1),d5
		or.w	$0000(a2),d5
		or.w	$0000(a3),d5
		
		move.w	$0000(a0),d6
		or.w	$0000(a1),d6
		or.w	$0000(a2),d6
		or.w	$0000(a3),d6
		
		move.w	$0000(a0),d7
		or.w	$0000(a1),d7
		or.w	$0000(a2),d7
		or.w	$0000(a3),d7

		movem.w	d0-d7,-(a4)
city_rendertemplateend:
				
;--------------------------------------------------------------------
	
city_render:
		lea		city_texture1,a0
		lea		city_texture2,a1
		lea		city_texture3,a2
		lea		city_texture4,a3
		lea		city_buffer+CITY_WIDTH*CITY_HEIGHT/2,a4
		jmp		city_rendercode
			
;--------------------------------------------------------------------
	
city_numblits	= 4

city_blit:		
		lea		city_bltcommands,a5

		moveq	#city_numblits,d7
.l4:			
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)

		lea		$dff000,a6
		move.l  (a5)+,BLTAPTR(a6)
        move.l  (a5)+,BLTCPTR(a6)
        move.l  (a5)+,BLTDPTR(a6)
        move.w	(a5)+,BLTCON0(a6)
		move.w  #CITY_HEIGHT*CITY_WIDTH/16*64+1,BLTSIZE(a6)
		dbra	d7,.l4
	
		lea		city_buffer,a0
		lea		2(a0),a1
		move.l	city_screens+4,a2

		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		; fix first byte of high bitplane, the blitter cant reach this due to shifting
		move.b	$0(a0),0*bltsize(a2)
		move.b	$1(a0),2*bltsize(a2)
		move.b	2*bltsize+0(a0),1*bltsize(a2)
		move.b	2*bltsize+1(a0),3*bltsize(a2)
		rts

				cnop	0,2
city_sintab:
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096

				ds.w	$4000
city_texture:
	incbin "../data/city/texture.dat"

city_pal:
	incbin "../data/city/pal.dat"

;********************************************************************

				section "city_copper",data,chip
			
				cnop	0,2
city_copperlist:
				dc.l	$008e2c81,$00902cc2,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

city_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000
city_coppercols1:
				blk.l	16,$01800000

city_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01040000						;bplcon mode, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
				dc.l	$01020010								;scroll x odd and even planes

				dc.l	$0118aaaa,$011a0000						;set mask to bpl-dma of plane5 and zero bpl-dma of plane6
				
				dc.l	$2c0ffffe
city_agafix:
				dc.l	$01007200						;wait x: 15, y: 1, turn on 7 bitplanes->this displays 6 bitplanes, but only 4 are fetched via dma, the rest is constant
				dc.l	$01800000
city_copperscale:
				blk.l	14*(CITY_HEIGHT-1)+1,$01800000
				dc.l	$01000200								;turn off bitplanes
				dc.l	$01020000
				
city_coppercols2:
				blk.l	16,$01800000
				
				dc.l	$f00ffffe
city_copperbpl2:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$01004200
				
				dc.l	$009c8010								;wait x: 15, y: 33, start irq
						
				dc.l	$fffffffe 								;wait for end
				
;********************************************************************

				cnop	0,2
blur_logo:
	incbin "../data/blur/logo.ami"
	
;********************************************************************

				section "city_emptychip",bss,chip

				cnop	0,8
city_screen1:	ds.b	CITY_WIDTH*CITY_HEIGHT/2
city_screen2:	ds.b	CITY_WIDTH*CITY_HEIGHT/2
city_screen3:	ds.b	CITY_WIDTH*CITY_HEIGHT/2
city_buffer:	ds.w	CITY_WIDTH*CITY_HEIGHT/4
city_mask:		ds.b	CITY_WIDTH*CITY_HEIGHT/4
city_lerptab:	ds.w	CITY_HEIGHT*CITY_HEIGHT*2
city_rendercode:
city_smc:
				ds.b	CITY_RENDERTEMPLATE_SIZE*CITY_WIDTH*CITY_HEIGHT/32+2

;********************************************************************

				section "city_empty",bss

				cnop	0,4
city_scrambletab:
				ds.l	CITY_WIDTH
city_texture1:	
				ds.w	$4000
city_texture2:	
				ds.w	$4000
city_texture3:	
				ds.w	$4000
city_texture4:	
				ds.w	$4000
city_level:
				ds.b	16*16*16
city_bltcommands:
				ds.w	8*city_numblits
city_heighttab:	
				ds.w	CITY_HEIGHT
city_offsettab:
				ds.l	CITY_HEIGHT
city_dstpoints:
				ds.w	CITY_MAXPOINTS*4
city_sorttab:		
				ds.w	CITY_MAXPOINTS
city_lerppois:	
				ds.l	CITY_HEIGHT*2
city_polyzs:	ds.w	CITY_MAXPOINTS/4
city_sortbuf1:	ds.w	128+2
city_sortbuf2:	ds.w	128
city_sortbuf3:	ds.w	CITY_MAXPOINTS/4
city_clipbuf:	ds.w	CITY_WIDTH*2
city_persptab:
				ds.w	$4000
city_reciproctab:	
				ds.w	$1000
city_copperbarbig:
				ds.w	256
		
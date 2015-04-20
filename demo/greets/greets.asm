;TODO:	- seems, i write somewhere over the memory (fracflight is sligthly broken in build)
	
	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
		
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
			
			section	"greets_code",code 
		
entrypoint:
		bra.b	greets_start
		bra.b	greets_end

greets_start:
		move.l	a6,fw_jumptable
		
		bsr.w	greets_init
		
		lea		greets_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		bsr.w	greets_update
		bsr.w	greets_update
		bsr.w	greets_update
		
		move.w	#TIME_GREETS_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#greets_copperlist,a0
		move.l	#greets_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		rts
		
greets_end:
		rts
		tst.w	greets_finished
		beq.b	greets_end
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		rts
		
		cnop	0,4
fw_jumptable:
		dc.l	0
greets_waitframe:
		dc.w	0
		
;--------------------------------------------------------------------

 MACRO<GREETS_INITSHAPE>
		lea		\1,a5
		move.w	#\2,GREETS_SHAPE_X(a5)		
		move.w	#\3,GREETS_SHAPE_Y(a5)		
		move.w	#\4,GREETS_SHAPE_Z(a5)		
		move.l	#\5,GREETS_SHAPE_WORDBUF(a5)		
		move.l	#\6,GREETS_SHAPE_COPPERPOIS(a5)
		move.l	#\7,GREETS_SHAPE_SCREENPOIS(a5)
		move.w	#\8,GREETS_SHAPE_SCREENOFF(a5)
		bsr.w	greets_initword
 ENDM

greets_init:
		lea		greets_sintab,a0
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

		bsr.w	greets_initfont
		bsr.w	greets_initcopper
		bsr.w	greets_initscreens
	
		GREETS_INITSHAPE greets_shape1, 0, 0,   0, greets_wordbuf1, greets_copperpois1, greets_screenpois1,  0*40
		GREETS_INITSHAPE greets_shape2, 0, 0, 128, greets_wordbuf2, greets_copperpois2, greets_screenpois2, 64*40
		rts
		
;--------------------------------------------------------------------

greets_initcopper:
		lea		greets_copperstretch,a0
		lea		greets_copperpois1,a1
		lea		greets_copperpois2,a2
		move.l	#greets_empty,d1
		move.l	d1,d2
		swap	d2
		
		move.l	#$2c0ffffe,d0
		
		move.w	#256-1,d7
.l0:
		move.l	d0,(a0)+

		addq	#2,a0
		move.l	a0,(a1)+
		addq	#8,a0
		move.l	a0,(a2)+
		suba.w	#10,a0
		
		move.w	#$00e0,(a0)+
		move.w	d2,(a0)+
		move.w	#$00e2,(a0)+
		move.w	d1,(a0)+
		move.w	#$00e4,(a0)+
		move.w	d2,(a0)+
		move.w	#$00e6,(a0)+
		move.w	d1,(a0)+
		
		addi.l	#$01000000,d0
		cmpi.l	#$000ffffe,d0
		bne.b	.nowrap
		move.l	#$ffdffffe,(a0)+
.nowrap:
		
		cmpi.l	#$f00ffffe,d0
		bne.b	.noirq
		move.l	#$009c8010,(a0)+
.noirq:
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

greets_initscreens:
		moveq	#0,d0
		lea		greets_screens,a0
		lea		greets_screenpois1,a1
		bsr.w	.doinit
		bsr.w	.doinit
		bsr.w	.doinit
		
		move.w	#40*64,d0
		lea		greets_screens,a0
		lea		greets_screenpois2,a1
		bsr.w	.doinit
		bsr.w	.doinit
		bsr.w	.doinit
		rts
.doinit:
		move.l	(a0)+,a2
		move.l	(a1)+,a3
		adda.w	d0,a2
		moveq	#64-1,d7
.l0:
		move.l	a2,(a3)+
		adda.w	#40,a2
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

greets_initfont:
		lea		greets_font,a0
		lea		greets_font2,a1
		lea		greets_letters,a2
		moveq	#27-1,d7
.l0:
		move.l	a1,(a2)+

		move.w	(a0)+,d6
		subq	#1,d6
		move.w	d6,(a1)+
.l1:	
		moveq	#8-1,d5
.l2:
		move.b	(a0)+,d0
		ext.w	d0
		muls.w	#40,d0
		move.w	d0,(a1)+
		
		dbra	d5,.l2
		
		dbra	d6,.l1
		
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

greets_irq:		
		movem.l	d0-d7/a0-a6,-(sp)
		
		;move.w	#$800,$dff180
		bsr.w	greets_update
		;clr.w	$dff180

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  

;--------------------------------------------------------------------

greets_update:
		bsr.w	greets_dopage
		bsr.w	greets_clear
			
		lea		greets_shape1,a0
		bsr.w	greets_updateshape
		
		lea		greets_shape2,a0
		bsr.w	greets_updateshape
		
		bsr.w	greets_movecam
		bsr.w	greets_fill
		bsr.w	greets_updateflash
		bsr.w	greets_updateshade
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
greets_flashframe:
		dc.w	11

greets_updateflash:
		move.w	greets_flashframe(pc),d0
		addq	#1,d0
		cmpi.w	#22,d0
		bne.b	.wrap
		moveq	#0,d0
.wrap:
		move.w	d0,greets_flashframe
		rts

;--------------------------------------------------------------------

greets_movecam:
		move.w	greets_camz(pc),d1
		subq	#6,d1
		andi.w	#$ff,d1
		move.w	d1,greets_camz
	
		move.w	greets_camx(pc),d0
		addi.w	#14,d0
		andi.w	#$7fe,d0
		move.w	d0,greets_camx
		
		move.w	greets_camy(pc),d1
		addi.w	#18,d1
		andi.w	#$7fe,d1
		move.w	d1,greets_camy
		rts

;--------------------------------------------------------------------

greets_updateshape:
		move.l	a0,greets_shapepoi
		bsr.w	greets_move
		tst.w	greets_finished
		bne.b	.end
		bsr.w	greets_draw
		bsr.w	greets_updatecopper
.end:
		rts
		
;--------------------------------------------------------------------

greets_clear:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		move.l	greets_screens+4,a0
		
		lea		BLTBASE,a6
		clr.w	BLTDMOD(a6)
		clr.w	BLTADAT(a6)
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		move.l  a0,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #$2014,BLTSIZE(a6)
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		rts
		
;--------------------------------------------------------------------

greets_text:
		dc.b	" ",0
		dc.b	" ",0
		dc.b	"greetings",0
		dc.b	"fly to",0
		dc.b	"active",0
		dc.b	"algotech",0
		dc.b	"ancients",0
		dc.b	"andromeda",0
		dc.b	"arsenic",0
		dc.b	"bauknecht",0
		dc.b	"booze design",0
		dc.b	"camelot",0
		dc.b	"censor design",0
		dc.b	"checkpoint",0
		dc.b	"dekadence",0
		dc.b	"desire",0
		dc.b	"fairlight",0
		dc.b	"farbrausch",0
		dc.b	"fan",0
		dc.b	"genesis project",0
		dc.b	"hoaxers",0
		dc.b	"k2",0
		dc.b	"metalvotze",0
		dc.b	"nah kolor",0
		dc.b	"nuance",0
		dc.b	"offence",0
		dc.b	"onslaught",0
		dc.b	"plush",0
		dc.b	"powerline",0
		dc.b	"resource",0
		dc.b	"scoopex",0
		dc.b	"shape",0
		dc.b	"smash designs",0
		dc.b	"spaceballs",0
		dc.b	"starion",0
		dc.b	"success and trc",0
		dc.b	"the black lotus",0
		dc.b	"the dreams",0
		dc.b	"tek",0
		dc.b	"triad",0
		dc.b	"trsi",0
		dc.b	"welle erdball",0
		dc.b	"        ",0
		dc.b	0
		
		cnop	0,2
greets_ypos:
		dc.w	0,0
		dc.w	0,0
		dc.w	0,0
		dc.w	$1400,0
		dc.w	0,0
		dc.w	0,0
		dc.w	0,$800
		dc.w	0,-$7000
		dc.w	0,0
		dc.w	0,0
		dc.w	0,-$400
		dc.w	0,$2000
		dc.w	0,0
		dc.w	-$1400,0
		dc.w	0,-$800
		dc.w	0,0
		dc.w	0,0
		dc.w	0,0
		dc.w	0,0
		dc.w	-$1000,0
		dc.w	-$c00,0
		dc.w	$2000,0
		dc.w	0,0
		dc.w	0,0
		dc.w	0,$2e00
		dc.w	0,0
		dc.w	0,0
		dc.w	$5000,0
		dc.w	$2800,0
		dc.w	0,0
		dc.w	0,-$1000
		dc.w	-$2000,0
		dc.w	-$1c00,0
		dc.w	-$c00,0
		dc.w	$3000,0
		dc.w	$2c00,0
		dc.w	0,-$400
		dc.w	$1600,0
		dc.w	0,0
		dc.w	0,0
		dc.w	0,0
		dc.w	0,-$400
		dc.w	0,0
		dc.w	0,0
		
		cnop	0,4
greets_texpoi:
		dc.l	greets_text
greets_pospoi:
		dc.l	greets_ypos
greets_finished:
		dc.w	0
greets_space:
		blk.b	8,$ff

greets_initword:
		move.l	GREETS_SHAPE_WORDBUF(a5),a2
		move.l	greets_texpoi(pc),a0
		move.l	greets_pospoi(pc),a6
		tst.b	(a0)
		beq.b	.finish
		lea		greets_letters,a1
		moveq	#0,d4
		move.w	(a6)+,GREETS_SHAPE_X(a5)
		move.w	(a6)+,GREETS_SHAPE_Y(a5)
		move.l	a6,greets_pospoi	
.l0:			
		moveq	#0,d0
		move.b	(a0)+,d0
		beq.b	.end
		cmpi.b	#$20,d0
		beq.b	.space
		cmpi.b	#$32,d0
		bne.b	.no2
		move.b	#27,d0
.no2:
		subq	#1,d0
		andi.b	#$1f,d0
		add.w	d0,d0
		add.w	d0,d0
		move.l	(a1,d0.w),a3
		
		move.w	(a3)+,d7
.l1:
		move.l	a3,(a2)+
		addq	#1,d4
		lea		16(a3),a3
		
		dbra	d7,.l1
		
		bra.b	.l0
.end:
		move.l	a0,greets_texpoi
		clr.l	(a2)+
		move.w	d4,GREETS_SHAPE_WORDWIDTH(a5)
		rts
.space:
		move.l	#greets_space,d5
		moveq	#16-1,d6
.l2:
		move.l	d5,(a2)+
		addq	#1,d4
	
		dbra	d6,.l2
		
		bra.b	.l0
.finish:
		addq.w	#1,greets_finished
		rts
		
;--------------------------------------------------------------------
		
;structure for a shape
GREETS_SHAPE_X			=  0		
GREETS_SHAPE_Y			=  2		
GREETS_SHAPE_Z			=  4		
GREETS_SHAPE_X1			=  6		
GREETS_SHAPE_X2			=  8		
GREETS_SHAPE_Y1			= 10		
GREETS_SHAPE_Y2			= 12		
GREETS_SHAPE_OLDY1		= 14		
GREETS_SHAPE_OLDY2		= 16		
GREETS_SHAPE_WORDWIDTH	= 18
GREETS_SHAPE_WORDBUF	= 20
GREETS_SHAPE_COPPERPOIS	= 24
GREETS_SHAPE_SCREENPOIS	= 28
GREETS_SHAPE_SCREENOFF	= 32
GREETS_SHAPE_SIZE		= 34
		
		cnop	0,2
greets_camx:
		dc.w	0
greets_camy:
		dc.w	0
greets_camz:
		dc.w	255
greets_shape1:
		ds.b	GREETS_SHAPE_SIZE
greets_shape2:
		ds.b	GREETS_SHAPE_SIZE
greets_shapepoi:
		dc.l	greets_shape1
		
greets_move:
		move.l	greets_shapepoi(pc),a5
		
		move.w	greets_camz(pc),d0
		add.w	GREETS_SHAPE_Z(a5),d0
		andi.w	#$ff,d0
		cmpi.w	#250,d0
		ble.b	.nonew1
		bsr.w	greets_initword
.nonew1:
		tst.w	greets_finished
		bne.b	.end
		lea		greets_sintab,a0
		
		move.w	greets_camx(pc),d0
		move.w	greets_camy(pc),d1
		
		move.w	(a0,d0.w),d6
		move.w	(a0,d1.w),d7
				
		add.w 	GREETS_SHAPE_X(a5),d6
		add.w 	GREETS_SHAPE_Y(a5),d7
		
		move.w	greets_camz(pc),d1
		add.w	GREETS_SHAPE_Z(a5),d1
		andi.w	#$ff,d1
		addi.w	#20,d1
		
		move.l	#65535/10,d0
		divu.w	d1,d0
		
		muls.w	d0,d6
		muls.w	d0,d7
		lsl.l	#3,d6
		move.l	d7,d5
		add.l	d7,d7
		add.l	d5,d6
		add.l	d7,d7	;fast mul #6
		swap	d6
		swap	d7
		
		move.w	d0,d3
		
		mulu.w	GREETS_SHAPE_WORDWIDTH(a5),d0
		lsr.l	#8,d0
		lsr.w	#2,d3
		
		move.w	#160,d1
		add.w	d6,d1
		move.w	d1,d2
		sub.w	d0,d1		;x1
		add.w	d0,d2		;x2
		
		move.w	d1,GREETS_SHAPE_X1(a5)
		move.w	d2,GREETS_SHAPE_X2(a5)
		
		move.w	#128,d1
		add.w	d7,d1
		move.w	d1,d2
		sub.w	d3,d1
		add.w	d3,d2
		
		move.w	d1,GREETS_SHAPE_Y1(a5)
		move.w	d2,GREETS_SHAPE_Y2(a5)
.end:
		rts

;--------------------------------------------------------------------

 MACRO<GREETS_PIXEL>
		move.w	(a1)+,d1
		bmi.w	.skip
		bchg.b	d0,(a6,d1.w)
 ENDM
 
greets_draw:
		move.l	greets_shapepoi(pc),a5
		
		move.w	GREETS_SHAPE_X2(a5),d2
		bmi.w	.end
		move.w	GREETS_SHAPE_X1(a5),d1
		cmpi.w	#320,d1
		bge.w	.end
		
		move.w	d2,d7
		sub.w	d1,d2		;dx
		
		moveq	#0,d3
		move.w	GREETS_SHAPE_WORDWIDTH(a5),d3
		swap	d3
		lsr.l	#4,d3
		divu.w	d2,d3
		ext.l	d3
		lsl.l	#6,d3
		move.l	d3,d5
		swap	d3
		moveq	#2,d4
		moveq	#0,d6
		
		tst.w	d1
		bge.b	.clipleft
		neg.w	d1
		subq	#1,d1
.l0:
		add.w	d5,d6
		addx.w	d3,d4
		dbra	d1,.l0

		moveq	#0,d1
.clipleft:
		
		cmpi.w	#319,d7
		ble.b	.clipright
		move.w	#319,d7
.clipright:

		sub.w	d1,d7
		bmi.w	.end
		
		moveq	#7,d0
		sub.w	d1,d0		;start bit
		andi.w	#7,d0

		lsr.w	#3,d1

		move.l	greets_screens+4,a6
		adda.w	GREETS_SHAPE_SCREENOFF(a5),a6
		move.l	GREETS_SHAPE_WORDBUF(a5),a2
		
		adda.w	d1,a6
.l1:		
		moveq	#$fffffffc,d2
		and.w	d4,d2

		move.l	(a2,d2.w),d1
		beq.w	.end

		move.l	d1,a1
		
		REPT	8
		GREETS_PIXEL
		ENDR
.skip:
		add.w	d5,d6
		addx.w	d3,d4
	
		subq	#1,d0
		dbmi	d7,.l1
		
		subq	#1,d7
		bmi.b	.end
		
		moveq	#7,d0
		addq	#1,a6
		bra.b	.l1
.end:
		rts		

;--------------------------------------------------------------------

greets_updatecopper:		
		move.l	greets_shapepoi(pc),a5
	
		move.l	#greets_empty,d5
		move.l	d5,d6
		swap	d6
		
		move.w	GREETS_SHAPE_OLDY1(a5),d3
		bmi.b	.skipctop
		move.w	GREETS_SHAPE_Y1(a5),d1
		cmpi.w	#256,d1
		bge.b	.skipctop

		sub.w	d3,d1
		subq	#1,d1
		bmi.b	.skipctop
		
		move.l	GREETS_SHAPE_COPPERPOIS(a5),a0
		add.w	d3,d3
		add.w	d3,d3
		adda.w	d3,a0
.l0:	
		move.l	(a0)+,a1
		move.w	d6,(a1)
		move.w	d5,4(a1)
		dbra	d1,.l0
.skipctop:		

		move.w	GREETS_SHAPE_Y2(a5),d3
		bmi.b	.skipcbottom
		move.w	GREETS_SHAPE_OLDY2(a5),d1
		cmpi.w	#256,d1
		bge.b	.skipcbottom

		sub.w	d3,d1
		subq	#1,d1
		bmi.b	.skipcbottom
		
		move.l	GREETS_SHAPE_COPPERPOIS(a5),a0
		add.w	d3,d3
		add.w	d3,d3
		adda.w	d3,a0
		
.l1:	
		move.l	(a0)+,a1
		move.w	d6,(a1)
		move.w	d5,4(a1)
		dbra	d1,.l1
.skipcbottom:		

		move.w	GREETS_SHAPE_Y2(a5),d2
		move.w	GREETS_SHAPE_Y1(a5),d1
		
		move.w	d2,d7
	
		sub.w	d1,d2		;dy
		
		move.l	#64*255*16,d3
		divu.w	d2,d3
		ext.l	d3
		lsl.l	#6,d3
		move.l	d3,d5
		swap	d3
		moveq	#2,d4
		moveq	#0,d6
		
		tst.w	d1
		bge.b	.cliptop
		neg.w	d1
		subq	#1,d1
.cltl0:	
		add.w	d5,d6
		addx.w	d3,d4
		dbra	d1,.cltl0
		
		moveq	#0,d1
.cliptop:
		
		cmpi.w	#255,d7
		ble.b	.clipbottom
		move.w	#255,d7
.clipbottom:
		
		move.l	GREETS_SHAPE_COPPERPOIS(a5),a3
		move.l	GREETS_SHAPE_SCREENPOIS(a5),a4
		move.l	8(a4),a4
		move.w	d1,d2
		add.w	d1,d1
		add.w	d1,d1
		adda.w	d1,a3
	
		move.w	d2,GREETS_SHAPE_Y1(a5)
		move.w	d7,GREETS_SHAPE_Y2(a5)
		bmi.b	.skip
		cmpi.w	#256,d2
		bge.b	.skip
		
		sub.w	d2,d7
		subq	#1,d7
		bmi.b	.skip
.l2:	
		move.l	(a3)+,a6
		moveq	#$fffffffc,d1
		and.w	d4,d1
		move.w	(a4,d1.w),(a6)
		move.w	2(a4,d1.w),4(a6)
		
		add.w	d5,d6
		addx.w	d3,d4
	
		dbra	d7,.l2
.skip:
		move.w	GREETS_SHAPE_Y1(a5),GREETS_SHAPE_OLDY1(a5)
		move.w	GREETS_SHAPE_Y2(a5),GREETS_SHAPE_OLDY2(a5)
		rts

;--------------------------------------------------------------------

greets_fill:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
	
		move.l	greets_screens+4,a0		
		move.l	a0,a1
		adda.w	#40,a1
		
		lea		BLTBASE,a6
		clr.w	BLTAMOD(a6)
		clr.w	BLTCMOD(a6)
		clr.w	BLTDMOD(a6)
		move.l  a0,BLTAPTR(a6)
        move.l  a1,BLTCPTR(a6)
        move.l  a1,BLTDPTR(a6)
        move.l	#$0b5a0000,BLTCON0(a6)					;minterm $fa = a|c, channels $b = a&c&d
		move.w  #$2014,BLTSIZE(a6)
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
greets_shadetab:
		dc.w	$0111,$0222,$0222,$0333,$0444,$0444,$0555,$0666
		dc.w	$0666,$0777,$0888,$0888,$0999,$0aaa,$0aaa,$0bbb
		dc.w	$0ccc,$0ccc,$0ddd,$0eee,$0eee,$0fff
		blk.w	16,$0fff

greets_updateshade:
		move.w	greets_camz(pc),d0
		move.w	d0,d7
		not.b	d0
		move.w	d0,d1
		addi.b	#128,d1
		lsr.w	#4,d0
		add.w	d0,d0
		lsr.w	#4,d1
		add.w	d1,d1

		moveq	#8-1,d2
		sub.w	greets_flashframe(pc),d2
		bpl.b	.clamp
		moveq	#0,d2
.clamp:
		add.w	d2,d2
		add.w	d2,d2
		cmpi.w	#4,d0
		ble.b	.noadd1
		add.w	d2,d0
.noadd1:
		cmpi.w	#4,d1
		ble.b	.noadd2
		add.w	d2,d1
.noadd2:
		
		lea		greets_shadetab,a0
		lea		$dff182,a1
		move.w	(a0,d0.w),d0
		move.w	(a0,d1.w),d1
		move.w	d0,d2
		tst.b	d7
		bpl.b	.swapcols
		move.w	d1,d2
.swapcols:
		
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		move.w	d2,(a1)+
		rts
		
;--------------------------------------------------------------------

greets_screens:		
		dc.l	greets_screen1,greets_screen2,greets_screen3
greets_screenpois1:
		dc.l	greets_linepois1+64*4*0
		dc.l	greets_linepois1+64*4*1
		dc.l	greets_linepois1+64*4*2
greets_screenpois2:
		dc.l	greets_linepois2+64*4*0
		dc.l	greets_linepois2+64*4*1
		dc.l	greets_linepois2+64*4*2

greets_dopage:
		lea 	greets_screenpois1,a0
		bsr.w	.dopage
		
		lea 	greets_screenpois2,a0
		bsr.w	.dopage
		
		lea 	greets_screens,a0
		bsr.w	.dopage
		
		move.l	d2,d0
		
		move.l	d0,d1
		addi.l	#40*64,d1
		
		lea		greets_copperbpl,a6
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)
		move.w	d1,$0e(a6)
		swap	d1
		move.w	d1,$0a(a6)
		rts
.dopage:
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
			
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)
		rts
		
;********************************************************************

				section "greets_data",data
				
				cnop	0,2
greets_font:
	incbin "../data/greets/font.dat"
	
greets_sintab:
	incbin "../data/sinplots/sintab1024.dat"
				ds.b	$600
				
;********************************************************************
	
				section "greets_copper",data,chip

greets_copperlist:
				dc.l	$008e2c81,$00902cc1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

greets_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;2 bitplane pointer
				
greets_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$01002200
				dc.l	$01800000
		
			;	dc.l	$009c8010								;start irq
			
greets_copperstretch:
				blk.l	5*256+2,$01800000
		
				dc.l	$fffffffe 	

;********************************************************************

				section "greets_bss",bss
				
				cnop	0,2
greets_font2:
				ds.b	14000
				
				cnop	0,4
greets_letters:
				ds.l	27
greets_wordbuf1:
				ds.l	64*20
greets_wordbuf2:
				ds.l	64*20
greets_copperpois1:
				ds.l	256
greets_copperpois2:
				ds.l	256
greets_linepois1:
				ds.l	64*3
greets_linepois2:
				ds.l	64*3

;********************************************************************

				section "greets_bsschip",bss,chip

				cnop	0,8
greets_screen1:	ds.b	40*128
greets_screen2:	ds.b	40*128
greets_screen3:	ds.b	40*128
greets_empty:	ds.b	40
				
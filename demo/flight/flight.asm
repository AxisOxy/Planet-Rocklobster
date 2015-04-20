	include "../framework/framework.i"	
	include "../framework/hardware.i"	
	include "../launcher/timings.asm"	
			
	ifnd _DEMO
	 include "../framework/parttester.asm"
	endc	// _DEMO
	
			section	"flight_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable

		bsr.w	flight_init
		
		move.w	#TIME_GREETS_STOP,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
	
		move.l	fw_jumptable(pc),a6
		jsr		SETBASECOPPER(a6)
		
		move.l	flight_planes+4,a1
		bsr.w	flight_copyinitpic
			
		move.l	fw_jumptable,a6
		lea		flight_coppersprites,a0
		bsr.w	flight_setsprites
		
		bsr.w	flight_initpal
		
		bsr.w	flight_fadeinback
		
		lea		flight_pal,a0
		lea		$dff180,a1
		moveq	#16-1,d7
.l1:
		move.w	(a0)+,(a1)+
		dbra	d7,.l1
		
		move.l	flight_planes+4,d0
		subi.l	#FLIGHT_EFFECTOFF,d0
		lea		flight_copperbpl,a0
		bsr.w	flight_setbpl
	
		move.w	#TIME_GREETS_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	fw_jumptable,a6
		move.l	#flight_copperlist,a0
		move.l	#flight_irq,a1
		jsr		SETCOPPER(a6)

		move.w	#$8020,$dff096		;copper, bitplane & sprite dma
	
		move.l	flight_planes+4,a0
		move.l	flight_planes+0,a1
		suba.w	#FLIGHT_EFFECTOFF,a0
		suba.w	#FLIGHT_EFFECTOFF,a1
	
		move.w	#256*4*40/2-1,d7
.l0:
		move.w	(a0)+,(a1)+
		dbra	d7,.l0		
		
		bsr.w	flight_depackpic_force
		
		move.w	#1,flight_dozoom
					
flight_main:
		bsr.w	flight_depackpic
		
		move.w	flight_picid(pc),d0
		bne.b	flight_main
flight_end:
		
		clr.w	flight_dozoom
		
		bsr.w	flight_fadeoutback
	
		move.w	#TIME_FLIGHT_STOP,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.w	#$0050,$dff09a		;turn off blitter-irqs
		
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		move.w	#$0020,$dff096		;turn off sprite dma
		rts		
		
	ifd _DEMO
	 include "../framework/depacker_doynax.asm"	
	endc	// _DEMO
	
		cnop	0,4
fw_jumptable:
		dc.l	0
color:
		dc.w	0
		
;--------------------------------------------------------------------
	
flight_setsprites:
		move.l	#flight_sprite1,d0
		move.l	#flight_sprite2,d1
		movem.l	d0/d1/a0/a1,-(sp)
		jsr		CLEARSPRITES(a6)
		movem.l	(sp)+,d0/d1/a0/a1

		move.w	d0,$06(a0)
		swap	d0
		move.w	d0,$02(a0)
		move.w	d1,$0e(a0)
		swap	d1
		move.w	d1,$0a(a0)
		rts
		
;--------------------------------------------------------------------	
		
flight_init:
		bsr.w	flight_initback
		bsr.w	flight_initsprites
		bsr.w	flight_loadpics
		rts
		
;--------------------------------------------------------------------

flight_initback:
		lea		flight_planes1+10+16,a0
		lea		flight_planes2,a1
		move.w	#256-1,d7
.l1:	
		moveq	#40/4-1,d6
.l0:		
		move.l	$2800(a0),$28(a1)
		move.l	$5000(a0),$50(a1)
		clr.l	$78(a1)
		move.l	(a0)+,(a1)+
		
		dbra	d6,.l0

		lea		$78(a1),a1
		
		dbra	d7,.l1
		
		lea		flight_planes2,a0
		lea		flight_planes1+10+16,a1
		move.w	#40*256*4/4-1,d7
.l2:
		move.l	(a0)+,(a1)+
		dbra	d7,.l2
		rts

;--------------------------------------------------------------------

flight_loadpics:
	ifd _DEMO

	MACRO<FLIGHT_LOADPIC>
		lea		flight_loadbuf,a0
		move.l	fw_jumptable(pc),a6
		jsr		LOADNEXTFILETOBUFFER(a6)
		move.l	a5,-(sp)

		move.l	#32704+\3,d0
		move.l	fw_jumptable(pc),a6
		jsr		ALLOC_\2(a6)
		lea		\3(a0),a1
		move.l	a1,flight_pics+\1*4
		
		move.l	(sp)+,a0
		bsr.w	doynaxdepack		
	ENDM
		
		FLIGHT_LOADPIC 0, FAST, 224/8*4*2
		FLIGHT_LOADPIC 1, FAST, 0
		FLIGHT_LOADPIC 2, FAST, 0
		FLIGHT_LOADPIC 3, FAST, 0
		FLIGHT_LOADPIC 4, FAST, 0
		FLIGHT_LOADPIC 5, FAST, 0
		FLIGHT_LOADPIC 6, FAST, 0
		FLIGHT_LOADPIC 7, FAST, 0
		FLIGHT_LOADPIC 8, FAST, 0
		FLIGHT_LOADPIC 9, FAST, 0
		FLIGHT_LOADPIC 10, FAST, 0
		FLIGHT_LOADPIC 11, FAST, 0
		FLIGHT_LOADPIC 12, CHIP, 0
		FLIGHT_LOADPIC 13, CHIP, 0
		move.l	flight_pics+13*4,flight_pics+14*4
		;FLIGHT_LOADPIC 14, CHIP
		;FLIGHT_LOADPIC 15, CHIP
		
		addq.w	#1,flight_picsready
		rts	
	else
		addq.w	#1,flight_picsready
		rts
	
	endc	// _DEMO

;--------------------------------------------------------------------

flight_initpal:
		lea		flight_planes1+10,a0
		lea		flight_pal,a2
		lea		$dff180,a1
		lea		$dff1a0,a5
		moveq	#8-1,d7
.l00:	
		move.w	(a0),(a2)+
		move.w	(a0),(a5)+
		move.w	(a0)+,(a1)+
		dbra	d7,.l00
		rts
		
;--------------------------------------------------------------------

flight_initsprites:
		lea		flight_planes1+10+16+8+16*40*4,a0
		lea		flight_sprite1+4,a1
		lea		flight_sprite2+4,a2
		move.w	#224-1,d7
.l0:		
		move.w	(a0),(a1)+
		move.w	$28(a0),(a1)+
		move.w	$50(a0),(a2)+
		move.w	$78(a0),(a2)+

		lea		$a0(a0),a0
		
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
flight_palframe:
		dc.w	16*2
flight_palid:
		dc.w	2
flight_picsready:
		dc.w	0

FLIGHT_NUMPICS	= 15

		cnop	0,4
flight_rowpoi:
		dc.l	0
flight_colpoi:
		dc.l	0
		
flight_pics:
		dc.l	flight_pic0
		dc.l	flight_pic1
		dc.l	flight_pic2
		dc.l	flight_pic3
		dc.l	flight_pic4
		dc.l	flight_pic5
		dc.l	flight_pic6
		dc.l	flight_pic7
		dc.l	flight_pic8
		dc.l	flight_pic9
		dc.l	flight_pic10
		dc.l	flight_pic11
		dc.l	flight_pic12
		dc.l	flight_pic13
		dc.l	flight_pic14
		dc.l	flight_pic15
		
flight_picid:
		dc.w	0
flight_needspic:
		dc.w	0
		
flight_depackpic:
		tst.w	flight_needspic
		beq.b	flight_depackpic_skip
flight_depackpic_force:
		move.w	flight_picid(pc),d0
		move.w	d0,d1
		lsl.w	#2,d1
		lea		flight_pics,a2
		move.l	(a2,d1.w),a0
		addq	#1,d0
		cmpi.w	#FLIGHT_NUMPICS,d0
		blt.b	.nowrap
		moveq	#0,d0
.nowrap:		
		move.w	d0,flight_picid
		
		move.l	flight_colbuffers+0,d0
		move.l	flight_colbuffers+4,d1

		move.l	d1,flight_colbuffers+0
		move.l	d0,flight_colbuffers+4
		
		adda.w	#16352,a0
		move.l	flight_colbuffers+4,a1
		bsr.w	flight_doc2p
	
		clr.w	flight_needspic
flight_depackpic_skip:
		rts
		
;--------------------------------------------------------------------

 ;reg1, reg2, tmpreg, shift, mask
 MACRO<FLIGHT_C2PMERGE>
		move.l	\2,\3
		lsr.l	#\4,\3
		eor.l	\1,\3
		andi.l	#\5,\3
		eor.l	\3,\1
		lsl.l	#\4,\3
		eor.l	\3,\2
 
 ENDM

flight_doc2p:
		moveq	#19-1,d5
.l2:		
		move.w	d5,-(sp)
		
		moveq	#28/4-1,d6
.l1:
		move.w	d6,-(sp)	
		
		moveq	#4-1,d7
.l0:
		move.w	d7,-(sp)

		move.l	(a0),d0
		move.l	112*1(a0),d1
		move.l	112*2(a0),d2
		move.l	112*3(a0),d3
		move.l	112*4(a0),d4
		move.l	112*5(a0),d5
		move.l	112*6(a0),d6
		move.l	112*7(a0),d7
		
		move.l	d7,a2
		FLIGHT_C2PMERGE d0, d1, d7, 1, $55555555
		FLIGHT_C2PMERGE d2, d3, d7, 1, $55555555
		FLIGHT_C2PMERGE d4, d5, d7, 1, $55555555
		move.l	a2,d7
		move.l	d0,a2
		FLIGHT_C2PMERGE d6, d7, d0, 1, $55555555
		move.l	a2,d0
		
		move.l	d7,a2
		FLIGHT_C2PMERGE d0, d2, d7, 2, $33333333
		FLIGHT_C2PMERGE d1, d3, d7, 2, $33333333
		FLIGHT_C2PMERGE d4, d6, d7, 2, $33333333
		move.l	a2,d7
		move.l	d0,a2
		FLIGHT_C2PMERGE d5, d7, d0, 2, $33333333
		move.l	a2,d0
		
		move.l	d7,a2
		FLIGHT_C2PMERGE d0, d4, d7, 4, $0f0f0f0f
		FLIGHT_C2PMERGE d1, d5, d7, 4, $0f0f0f0f
		FLIGHT_C2PMERGE d2, d6, d7, 4, $0f0f0f0f
		move.l	a2,d7
		move.l	d0,a2
		FLIGHT_C2PMERGE d3, d7, d0, 4, $0f0f0f0f
		move.l	a2,d0
		
		move.b	d0,80*24(a1)
		move.b	d1,80*25(a1)
		move.b	d2,80*26(a1)
		move.b	d3,80*27(a1)
		move.b	d4,80*28(a1)
		move.b	d5,80*29(a1)
		move.b	d6,80*30(a1)
		move.b	d7,80*31(a1)
				
		swap	d0
		swap	d1
		swap	d2
		swap	d3
		swap	d4
		swap	d5
		swap	d6
		swap	d7

		move.b	d0,80*8(a1)
		move.b	d1,80*9(a1)
		move.b	d2,80*10(a1)
		move.b	d3,80*11(a1)
		move.b	d4,80*12(a1)
		move.b	d5,80*13(a1)
		move.b	d6,80*14(a1)
		move.b	d7,80*15(a1)
		
		ror.l	#8,d0
		ror.l	#8,d1
		ror.l	#8,d2
		ror.l	#8,d3
		ror.l	#8,d4
		ror.l	#8,d5
		ror.l	#8,d6
		ror.l	#8,d7
		
		move.b	d0,(a1)
		move.b	d1,80*1(a1)
		move.b	d2,80*2(a1)
		move.b	d3,80*3(a1)
		move.b	d4,80*4(a1)
		move.b	d5,80*5(a1)
		move.b	d6,80*6(a1)
		move.b	d7,80*7(a1)
		
		swap	d0
		swap	d1
		swap	d2
		swap	d3
		swap	d4
		swap	d5
		swap	d6
		swap	d7
		
		move.b	d0,80*16(a1)
		move.b	d1,80*17(a1)
		move.b	d2,80*18(a1)
		move.b	d3,80*19(a1)
		move.b	d4,80*20(a1)
		move.b	d5,80*21(a1)
		move.b	d6,80*22(a1)
		move.b	d7,80*23(a1)

		lea		28(a0),a0
		lea		20(a1),a1		
		
		move.w	(sp)+,d7
		dbra	d7,.l0
	
		lea		4-28*4(a0),a0
		lea		4*80*8-20*4(a1),a1
	
		move.w	(sp)+,d6
		dbra	d6,.l1

		lea		112*8-28(a0),a0
		lea		1-28*80*8(a1),a1
		
		move.w	(sp)+,d5
		dbra	d5,.l2
		rts
		
;--------------------------------------------------------------------

flight_copyinitpic:
		lea		flight_basepic,a0
		
		lea		BLTBASE,a5
		move.l	fw_jumptable(pc),a6
		jsr		BLTWAIT(a6)
		
		move.w	#$ffff,BLTAFWM(a5)
		move.w	#$ffff,BLTALWM(a5)
		move.l	a0,BLTAPTR(a5)
		move.l	a1,BLTDPTR(a5)
		clr.w	BLTAMOD(a5)
		move.w	#12,BLTDMOD(a5)
		move.l	#$09f00000,BLTCON0(a5)
		move.w	#$e00e,BLTSIZE(a5)
		
		jsr		BLTWAIT(a6)
		rts
		
;--------------------------------------------------------------------
	
flight_copypic:
		move.w	flight_picid,d0
		subq	#1,d0
		move.w	d0,d1
		lsl.w	#2,d0
		lea		flight_pics,a2
		move.l	(a2,d0.w),a2
		move.l	a2,flight_rowpoi
		move.l	flight_colbuffers+4,a2
		move.l	a2,flight_colpoi
		rts
		
;--------------------------------------------------------------------

		cnop	0,4
flight_bltpoi:
		dc.l	0
flight_bltstate:
		dc.w	0
flight_bltcount:
		dc.w	0

flight_updatezoom:
		;bsr.w	bltwait
		bsr.w	flight_dopage
		
		clr.w	flight_bltstate
	
		move.w	flight_frame(pc),d0

		subq	#2,d0
		bpl.b	.wrap
		
		bsr.w	flight_copypic
		move.w	#1,flight_needspic
	
		move.w	#(FLIGHT_NUMPICFRAMES-1)*2,d0
		move.w	d0,flight_frame
		;rts
.wrap:
		move.w	d0,flight_frame
		
		bsr.w	flight_initblit
		bsr.w	flight_copycolumns

		lea		flight_bltcommands,a0
		move.l	a0,flight_bltpoi
		move.w	#1,flight_bltstate
		
		clr.w	flight_bltcount

		;bsr.w	flight_updateblitqueue

		bsr.w	flight_flushblitqueue

		bsr.w	flight_copyrows
				
.skip:
		rts

;--------------------------------------------------------------------

flight_flushblitqueue:
.l0:
		bsr.w	flight_updateblitqueue
		tst.w	flight_bltstate
		beq.b	.end
		bra.b	.l0
.end:
		rts

;--------------------------------------------------------------------

flight_updateblitqueue:
		tst.w	flight_bltstate
		beq.b	.skip
		move.l	flight_bltpoi(pc),a0
		move.w	(a0)+,d0
		bmi.b	.end
		lea		BLTBASE,a5
	
		move.w	#$8400,$096(a5)
.bl0:	
		btst	#$0e,$02(a5)
		bne.b	.bl0
		
	;	cmpi.w	#7,flight_bltcount
	;	blt.b	.nonasty
		move.w	#$0400,$096(a5)
.nonasty:		
		addq.w	#1,flight_bltcount

		move.w	d0,BLTAMOD(a5)
		move.w	(a0)+,BLTBMOD(a5)
		move.w	(a0)+,BLTCMOD(a5)
		move.w	(a0)+,BLTDMOD(a5)
		move.w	(a0)+,BLTADAT(a5)
		move.w	(a0)+,BLTBDAT(a5)
		move.w	(a0)+,BLTCDAT(a5)
		move.l	(a0)+,BLTAPTR(a5)
		move.l	(a0)+,BLTBPTR(a5)
		move.l	(a0)+,BLTCPTR(a5)
		move.l	(a0)+,BLTDPTR(a5)
		move.l	(a0)+,BLTCON0(a5)
		move.l	(a0)+,BLTAFWM(a5)
		move.w	(a0)+,BLTSIZE(a5)
		move.l	a0,flight_bltpoi
		rts
.end:
		clr.w	flight_bltstate
.skip:
		rts
		
;--------------------------------------------------------------------

;x1, x2, y1, y2, dst-yoff, src-shift, dst-xoff
 MACRO<FLIGHT_BLIT_SHIFT>
		move.w	\1,d1
		move.w	\2,d2
		move.w	\3,d3
		move.w	\4,d4

		move.l	flight_planes+4,a0
		move.l	flight_planes+0,a1

		cmp.w	d1,d2
		bmi.w	.end\@
		
		sub.w	d3,d4
		bmi.w	.end\@
		
		move.w	d1,d5
		lsr.w	#3,d5
		andi.w	#$fffe,d5
				
		lea		flight_leftmasktab,a2
		add.w	d1,d1
		move.w	(a2,d1.w),d0
		
		add.w	d2,d2
		lea		flight_rightmasktab,a2
		move.w	(a2,d2.w),d7
		
		;lsl.w	#7,d3
		mulu.w	#40*4,d3
		ext.l	d5
		add.l	d5,d3
		adda.l	d3,a0
		adda.l	#\5*40*4+\7,a1
		adda.l	d3,a1
		
		andi.w	#$1e0,d1
		andi.w	#$1e0,d2
		sub.w	d1,d2
		move.w	d2,d1
		asr.w	#5,d2
	if \7<0 
		move.w	#$7fff,d0
		move.w	#$8000,d7
		addq	#2,d2
	else
		addq	#1,d2
	endc 
		bmi.w	.verysmall\@
		beq.w	.small\@
				
		addq	#1,d4
		lsl.w	#8,d4
		or.w	d2,d4

		moveq	#$10+4,d6
		sub.w	d2,d6
		add.w	d6,d6
		
		move.w	d4,d5
		andi.w	#$ffc0,d5
		addq	#1,d5

		move.w	d6,(a5)+			;BLTAMOD
		clr.l	(a5)+				;BLTBMOD/BLTCMOD
		move.w	d6,(a5)+			;BLTDMOD
		clr.l	(a5)+				;BLTADAT/BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
		clr.l	(a5)+				;BLTBPTR
		clr.l	(a5)+				;BLTCPTR
		move.l  a1,(a5)+			;BLTDPTR
        move.l	#$10000000*\6+$09f00000,(a5)+	;BLTCON0/BLTCON1
		move.w	d0,(a5)+			;BLTAFWM
		move.w	d7,(a5)+			;BLTALWM
		move.w  d4,(a5)+			;BLTSIZE

		bra.w	.end\@
		
.small\@:
		addq	#1,d4
		lsl.w	#8,d4
		ori.w	#$0001,d4

		move.w	#$1e+8,(a5)+		;BLTAMOD
		clr.l	(a5)+				;BLTBMOD/BLTCMOD
		move.w	#$1e+8,(a5)+		;BLTDMOD
		clr.l	(a5)+				;BLTADAT/BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
		clr.l	(a5)+				;BLTBPTR
		clr.l	(a5)+				;BLTCPTR
		move.l  a1,(a5)+			;BLTDPTR
        move.l	#$10000000*\6+$09f00000,(a5)+	;BLTCON0/BLTCON1
		move.w	d0,(a5)+			;BLTAFWM
		move.w	d7,(a5)+			;BLTALWM
		move.w  d4,(a5)+			;BLTSIZE
	
		bra.b	.end\@
		
.verysmall\@:
		addq	#1,d4
		lsl.w	#8,d4
		addq	#1,d4
		
		move.w	#$1e+8,(a5)+		;BLTAMOD
		clr.l	(a5)+				;BLTBMOD/BLTCMOD
		move.w	#$1e+8,(a5)+		;BLTDMOD
		clr.l	(a5)+				;BLTADAT/BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
		clr.l	(a5)+				;BLTBPTR
		clr.l	(a5)+				;BLTCPTR
		move.l  a1,(a5)+			;BLTDPTR
        move.l	#$10000000*\6+$09f00000,(a5)+	;BLTCON0/BLTCON1
		move.w	d0,(a5)+			;BLTAFWM
		move.w	d7,(a5)+			;BLTALWM
		move.w  d4,(a5)+			;BLTSIZE
		
.end\@:
 ENDM

;params:
;x1, x2, y1, y2, dst-yoff
 MACRO<FLIGHT_BLIT_ORA>
		move.w	\1,d1
		move.w	\2,d2
		move.w	\3,d3
		move.w	\4,d4

		move.l	flight_planes+4,a0
		move.l	flight_planes+0,a1

		cmp.w	d1,d2
		bmi.w	.end\@
		
		sub.w	d3,d4
		bmi.w	.end\@
		
		move.w	d1,d5
		lsr.w	#3,d5
		andi.w	#$fffe,d5
				
		lea		flight_leftmasktab,a2
		add.w	d1,d1
		move.w	(a2,d1.w),d0
		
		add.w	d2,d2
		lea		flight_rightmasktab,a2
		move.w	(a2,d2.w),d7
		
		mulu.w	#40*4,d3
		ext.l	d5
		add.l	d5,d3
		adda.l	d3,a0
		adda.l	#\5*40*4,a1
		adda.l	d3,a1
		
		andi.w	#$1e0,d1
		andi.w	#$1e0,d2
		sub.w	d1,d2
		move.w	d2,d1
		asr.w	#5,d2
		addq	#1,d2
		
		bmi.w	.verysmall\@
		beq.w	.small\@

		moveq	#$10+4,d6
		sub.w	d2,d6
		add.w	d6,d6

		addq	#1,d4
		lsl.w	#8,d4
		
		move.w	d4,d5
		andi.w	#$ffc0,d5
		addq	#1,d5

		move.w	#$1e+8,(a5)+		;BLTAMOD
		clr.w	(a5)+				;BLTBMOD
		move.l	#$00260026,(a5)+	;BLTCMOD/;BLTDMOD
		clr.w	(a5)+				;BLTADAT
		move.w	d0,(a5)+			;BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
        clr.l	(a5)+				;BLTBPTR
        move.l  a1,(a5)+			;BLTCPTR
        move.l  a1,(a5)+			;BLTDPTR
        move.l	#$0be20000,(a5)+	;BLTCON0/BLTCON1
		move.l	#$ffffffff,(a5)+	;BLTAFWM/BLTALWM
		move.w  d5,(a5)+			;BLTSIZE

		addq	#2,a0
		addq	#2,a1

		subq	#2,d2
		ble.b	.skipcenter\@
		andi.w	#$ffc0,d4
		or.w	d2,d4
		
		addq	#4,d6

		move.w	d6,(a5)+			;BLTAMOD
		clr.l	(a5)+				;BLTBMOD/BLTCMOD
		move.w	d6,(a5)+			;BLTDMOD
		clr.l	(a5)+				;BLTADAT/BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
        clr.l	(a5)+				;BLTBPTR
		clr.l	(a5)+				;BLTCPTR
		move.l  a1,(a5)+			;BLTDPTR
        move.l	#$09f00000,(a5)+	;BLTCON0/BLTCON1
		move.l	#$ffffffff,(a5)+	;BLTAFWM/BLTALWM
		move.w  d4,(a5)+			;BLTSIZE
.skipcenter\@:

		add.w	d2,d2
		adda.w	d2,a0
		adda.w	d2,a1
		
		move.w	#$1e+8,(a5)+		;BLTAMOD
		clr.w	(a5)+				;BLTBMOD
		move.l	#$00260026,(a5)+	;BLTCMOD/BLTDMOD
		clr.w	(a5)+				;BLTADAT
		move.w	d7,(a5)+			;BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
        clr.l 	(a5)+				;BLTBPTR
        move.l  a1,(a5)+			;BLTCPTR
        move.l  a1,(a5)+			;BLTDPTR
        move.l	#$0be20000,(a5)+	;BLTCON0/BLTCON1
		move.l	#$ffffffff,(a5)+	;BLTAFWM/BLTALWM
		move.w  d5,(a5)+			;BLTSIZE

		bra.w	.end\@
		
.small\@:

		addq	#1,d4
		lsl.w	#8,d4
		ori.w	#$0001,d4

		and.w	d7,d0

		move.w	#$1e+8,(a5)+		;BLTAMOD
		clr.w	(a5)+				;BLTBMOD
		move.l	#$00260026,(a5)+	;BLTCMOD/BLTDMOD
		clr.w	(a5)+				;BLTADAT
		move.w	d0,(a5)+			;BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
        clr.l	(a5)+				;BLTBPTR
		move.l  a1,(a5)+			;BLTCPTR
        move.l  a1,(a5)+			;BLTDPTR
        move.l	#$0be20000,(a5)+	;BLTCON0/BLTCON1
		move.l	#$ffffffff,(a5)+	;BLTAFWM/BLTALWM
		move.w  d4,(a5)+			;BLTSIZE
	
		bra.b	.end\@
		
.verysmall\@:

		addq	#1,d4
		lsl.w	#8,d4
		addq	#1,d4

		and.w	d7,d0
		
		move.w	#$1e+8,(a5)+		;BLTAMOD
		clr.w	(a5)+				;BLTBMOD
		move.l	#$00260026,(a5)+	;BLTCMOD/BLTDMOD
		clr.w	(a5)+				;BLTADAT
		move.w	d0,(a5)+			;BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l  a0,(a5)+			;BLTAPTR
        clr.l	(a5)+				;BLTBPTR
		move.l  a1,(a5)+			;BLTCPTR
        move.l  a1,(a5)+			;BLTDPTR
        move.l	#$0be20000,(a5)+	;BLTCON0/BLTCON1
		move.l	#$ffffffff,(a5)+	;BLTAFWM/BLTALWM
		move.w  d4,(a5)+			;BLTSIZE
		
.end\@:
 ENDM
 
;--------------------------------------------------------------------
		
FLIGHT_NUMPICFRAMES = 73
		
		cnop	0,2
flight_frame:
		dc.w	0
		
flight_leftmasktab:
		REPT	16
		dc.w	$ffff,$7fff,$3fff,$1fff,$0fff,$07ff,$03ff,$01ff
		dc.w	$00ff,$007f,$003f,$001f,$000f,$0007,$0003,$0001
		ENDR
flight_rightmasktab:
		REPT	16
		dc.w	$8000,$c000,$e000,$f000,$f800,$fc00,$fe00,$ff00
		dc.w	$ff80,$ffc0,$ffe0,$fff0,$fff8,$fffc,$fffe,$ffff
		ENDR

flight_xs:
		blk.w	8
flight_ys:
		blk.w	8
		
flight_initblit:	
		move.w	flight_frame(pc),d0
		
		lea		flight_zoomxs,a4
		move.w	(a4,d0.w),d1
		subi.w	#$8f,d1

		move.w	#222,d2
		sub.w	d1,d2

		moveq	#0,d0
		move.w	#222,d3
		move.w	d0,flight_xs+0
		addq	#1,d0
		move.w	d0,flight_xs+2
		subq	#1,d1
		move.w	d1,flight_xs+4
		addq	#1,d1
		move.w	d1,flight_xs+6
		addq	#1,d2
		move.w	d2,flight_xs+8
		addq	#1,d2
		move.w	d2,flight_xs+10
		move.w	d3,flight_xs+12
		addq	#1,d3
		move.w	d3,flight_xs+14
	
		lea		flight_xs,a0
		lea		flight_ys,a1
		movem.w	(a0),d0-d7
		movem.w	d0-d7,(a1)
		subq	#1,4(a0)
	
		lea		flight_bltcommands,a5
		
		FLIGHT_BLIT_SHIFT flight_xs+0, flight_xs+4, flight_ys+2, flight_ys+4, -1, 15, -2
		FLIGHT_BLIT_SHIFT flight_xs+10, flight_xs+12, flight_ys+2, flight_ys+4, -1, 1, 0
		
		FLIGHT_BLIT_SHIFT flight_xs+2, flight_xs+4, flight_ys+6, flight_ys+8, 0, 15, -2
		FLIGHT_BLIT_SHIFT flight_xs+10, flight_xs+12, flight_ys+6, flight_ys+8, 0, 1, 0
		
		FLIGHT_BLIT_SHIFT flight_xs+0, flight_xs+4, flight_ys+10, flight_ys+12, 1, 15, -2
		FLIGHT_BLIT_SHIFT flight_xs+10, flight_xs+12, flight_ys+10, flight_ys+12, 1, 1, 0

		FLIGHT_BLIT_ORA flight_xs+6, flight_xs+8, flight_ys+2, flight_ys+4, -1
		FLIGHT_BLIT_ORA flight_xs+6, flight_xs+8, flight_ys+6, flight_ys+8, 0
		FLIGHT_BLIT_ORA flight_xs+6, flight_xs+8, flight_ys+10, flight_ys+12, 1
		rts

;--------------------------------------------------------------------
		
flight_copyrows:	
		moveq	#0,d0
		move.w	flight_ys+4,d0
		move.l	flight_rowpoi(pc),a0
		adda.w	#28*4*0,a0
		bsr.w	flight_copyrow
	
		moveq	#0,d0
		move.w	flight_ys+10,d0
		move.l	flight_rowpoi(pc),a0
		adda.w	#28*4*1,a0
		bsr.w	flight_copyrow
		
		move.l	flight_rowpoi(pc),a0
		adda.w	#28*4*2,a0
		move.l	a0,flight_rowpoi
		rts

flight_copyrow:
		move.l	flight_planes+0,a6
		
		mulu.w	#40*4,d0
		adda.l	d0,a6
		
		movem.l	(a0),d0-d6
		movem.l	d0-d6,(a6)
		movem.l	$1c*1(a0),d0-d6
		movem.l	d0-d6,$28(a6)
		movem.l	$1c*2(a0),d0-d6
		movem.l	d0-d6,$50(a6)
		movem.l	$1c*3(a0),d0-d6
		movem.l	d0-d6,$78(a6)
		rts
		
;--------------------------------------------------------------------
		
flight_copycolumns:	
		move.w	flight_ys+4,d0
		moveq	#0,d1
		bsr.w	flight_copycolumn
	
		move.w	flight_ys+10,d0
		moveq	#1,d1
		bsr.w	flight_copycolumn
		
		move.w	#$ffff,(a5)+
		rts

		cnop	0,2
flight_bittab:
		dc.w	$8000,$4000,$2000,$1000,$0800,$0400,$0200,$0100
		dc.w	$0080,$0040,$0020,$0010,$0008,$0004,$0002,$0001
		
flight_copycolumn:
		lea		flight_bittab(pc),a0

		move.w	#(FLIGHT_NUMPICFRAMES-1)*2,d2
		sub.w	flight_frame(pc),d2
		add.w	d1,d2
		move.w	d2,d3
		lsr.w	#3,d2
		andi.w	#$fffe,d2
		move.l	flight_colpoi(pc),a3
		
		adda.w	d2,a3					;source addr
		andi.w	#$0f,d3
		move.w	d3,d5					;source xfrac
		add.w	d3,d3
		move.w	(a0,d3.w),d3			;source bit
	
		move.l	flight_planes+0,a4
		move.w	d0,d6
		lsr.w	#3,d0
		andi.w	#$fffe,d0
		adda.w	d0,a4					;dest addr
	
		andi.w	#$0f,d6
		move.w	d6,d7					;dest xfrac
		add.w	d6,d6
		move.w	(a0,d6.w),d0			;dest bit
		
		sub.w	d5,d7					;shift
		bpl.b	.bla
		lea		-$28(a4),a4
.bla:
		andi.w	#$0f,d7
		ror.w	#4,d7
		move.w	d7,d6
		ori.w	#$0be2,d7
	
		move.l	#$ffffffff,d3
		
		move.w	#$12,(a5)+			;BLTAMOD
		clr.w	(a5)+				;BLTBMOD
		move.l	#$00260026,(a5)+	;BLTCMOD/BLTDMOD
		clr.w	(a5)+				;BLTADAT
		move.w	d0,(a5)+			;BLTBDAT
		clr.w	(a5)+				;BLTCDAT
		move.l	a3,(a5)+			;BLTAPTR
		clr.l	(a5)+				;BLTBPTR
		move.l	a4,(a5)+			;BLTCPTR
		move.l	a4,(a5)+			;BLTDPTR
		move.w	d7,(a5)+			;BLTCON0
		clr.w	(a5)+				;BLTCON1
		move.w	d3,(a5)+
		move.w	d3,(a5)+
		move.w	#$e001,(a5)+		;BLTSIZE
		rts
	
;--------------------------------------------------------------------

FLIGHT_EFFECTOFF	= 16*4*40+10

		cnop	0,4
flight_planes:
		dc.l	flight_planes1+10+16+FLIGHT_EFFECTOFF,flight_planes2+FLIGHT_EFFECTOFF
flight_colbuffers:
		dc.l	flight_colbuffer1,flight_colbuffer2

flight_dopage:
		move.l	fw_jumptable(pc),a6
		jsr		BLTWAIT(a6)
		
		move.l	flight_planes+0,d0
		move.l	flight_planes+4,d1
		
		move.l	d1,flight_planes+0
		move.l	d0,flight_planes+4
		
		;move.l	d1,d0
		
		subi.l	#FLIGHT_EFFECTOFF,d0
		
		lea		flight_copperbpl,a0
		;bra.b	flight_setbpl
		
;--------------------------------------------------------------------
		
flight_setbpl:
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		addi.l	#40*1,d1
		addi.l	#40*2,d2
		addi.l	#40*3,d3
		move.w	d0,$06(a0)
		move.w	d1,$0e(a0)
		move.w	d2,$16(a0)
		move.w	d3,$1e(a0)
		swap	d0
		swap	d1
		swap	d2
		swap	d3
		move.w	d0,$02(a0)
		move.w	d1,$0a(a0)
		move.w	d2,$12(a0)
		move.w	d3,$1a(a0)
		rts

;--------------------------------------------------------------------

		cnop	0,2
flight_dozoom:
		dc.w	0

flight_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		;move.w	#$800,$dff180
		tst.w	flight_dozoom
		beq.b	.skip
		bsr.w	flight_updatezoom
.skip:

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		;clr.w	$dff180
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;--------------------------------------------------------------------

flight_fadeoutback:
		moveq	#16-1,d0
.l0:
		move.w	#$fff,d4
		bsr.w	flight_fade

		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		jsr		VSYNC(a6)
		
		subq	#1,d0
		bpl.b	.l0
		rts

;--------------------------------------------------------------------

flight_fade:
		lea 	flight_planes1+10,a0
		
		move.w	d4,d5
		move.w	d5,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6
		
		lea		$dff180,a1
		lea		$dff1a0,a2
		
		moveq	#16-1,d7
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
		move.w	d1,(a2)+
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

flight_fadeinback:
		lea		vectrans_sintab,a0
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

		lea		flight_fadecopperbpl,a0
		move.l	flight_planes+0,d0
		subi.l	#FLIGHT_EFFECTOFF,d0
		
		move.l	#flight_colbuffer1,d4
		
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		addi.l	#40*256*1,d1
		addi.l	#40*256*2,d2
		addi.l	#40*256*3,d3
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
		
		move.l	flight_planes+4,a0
		move.l	flight_planes+0,a1
		suba.w	#FLIGHT_EFFECTOFF,a0
		suba.w	#FLIGHT_EFFECTOFF,a1
		
		move.w	#256-1,d7
.l0:
		moveq	#40/2-1,d6
.l1:
		move.w	$28(a0),$2800(a1)
		move.w	$50(a0),$5000(a1)
		move.w	$78(a0),$7800(a1)
		move.w	(a0)+,(a1)+
		
		dbra	d6,.l1

		adda.w	#$78,a0
		
		dbra	d7,.l0
				
		bsr.w	updatefadeback
		bsr.w	updatefadeback
		
		lea		flight_fadecoppersprites,a0
		jsr		CLEARSPRITES(a6)
			
		move.l	fw_jumptable,a6
		move.l	#flight_fadecopperlist,a0
		move.l	#flight_irq,a1
		jsr		SETCOPPER(a6)
	
fademain:
		bsr.w	updatefadeback
		
		cmpi.w	#64,fadeframe
		bne.b	fademain
				
fademain2:
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		
		bsr.w	flight_updatefadecols
		
		addq.w	#1,fadeframe
		cmpi.w	#64+32,fadeframe
		bne.b	fademain2
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
flight_pal:
		ds.w	8
		dc.w	$0fb7,$0ea6,$0d85,$0c74,$0a63,$0852,$0853,$0562

flight_updatefadecols:
		move.w	fadeframe(pc),d0
		subi.w	#64,d0
		lsr.w	#1,d0
		
		move.w	#$fff,d4
		move.w	d4,d5
		move.w	d4,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6
		
		lea		flight_pal,a0
		lea		$dff1a0,a1
		moveq	#16-1,d7
.l00:	
		move.w	(a0)+,d1
		move.w	d1,d2
		move.w	d1,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		sub.w	d4,d1
		sub.w	d5,d2
		sub.w	d6,d3
		muls.w	d0,d1
		muls.w	d0,d2
		muls.w	d0,d3
		asr.w	#4,d1
		asr.w	#4,d2
		asr.w	#4,d3
		add.w	d4,d1
		add.w	d5,d2
		add.w	d6,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		or.w	d2,d1
		or.w	d3,d1
		move.w	d1,(a1)+

		dbra	d7,.l00
		rts
		
;--------------------------------------------------------------------

width	= 320
height	= 256
minx	= 0
maxx	= width-1
miny	= 0
maxy	= height-1

linemod		= width/8
planemod	= linemod*height

xstart		= 105-128
ystart		= 4
zstart		= 300
xspeed		= 2
yspeed		= $00
zspeed		= 4
xscale		= 800
yscale		= 600
rotstart	= 6*128
rotspeed	= $04

updatefadeback:
		addq.w	#1,fadeframe
		
		bsr.w	vectrans_clear
		bsr.w	vectrans_transform
		bsr.w	vectrans_clip
		bsr.w	vectrans_dolines
		bsr.w	vectrans_fill
		bsr.w	vectrans_page
		
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		
		bsr.w	vectrans_updatefade
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
vectrans_fadetab:
		dc.w	$0fff,$0eee,$0ddd,$0ccc,$0bbb,$0aaa,$0999,$0888
		dc.w	$0777,$0666,$0555,$0444,$0333,$0222,$0111,$0000

vectrans_updatefade:
		moveq	#64,d0
		sub.w	fadeframe(pc),d0
		lsr.w	#2,d0
		add.w	d0,d0
		lea		vectrans_fadetab,a0
		move.w	(a0,d0.w),d0		

		lea		$dff1a0,a0
		moveq	#16-1,d7
.l2:
		move.w	d0,(a0)+
		dbra	d7,.l2
		rts

;--------------------------------------------------------------------

		cnop	0,4
vectrans_screens:
		dc.l	flight_colbuffer1,flight_colbuffer2
			
vectrans_clear:
		move.l	vectrans_screens+4,a0
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTAFWM(a6)
		clr.w	BLTADAT(a6)
		clr.w	BLTBDAT(a6)
		clr.w	BLTCDAT(a6)
		move.w	#$0,BLTDMOD(a6)
		move.l  a0,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #height*64+linemod/2,BLTSIZE(a6)	;$4010
		
		;bsr.w	bltwait
		rts

;--------------------------------------------------------------------

numpoints	= 5
maxpoints	= 9

			cnop 	0,2
fadeframe:	dc.w	0
movex:		dc.w	xstart
movey:		dc.w	ystart
zpos:		dc.w	zstart
rotz:		dc.w	rotstart
			
points:		dc.w	-16384,-16384
			dc.w	 16384,-16384
			dc.w	 16384, 16384
			dc.w	-16384, 16384
			dc.w	-16384,-16384
			dc.w	$8000
				
dstpoints1:	ds.w	maxpoints*2+1
dstpoints2:	ds.w	maxpoints*2+1
dstpoints3:	ds.w	maxpoints*2+1
dstpoints4:	ds.w	maxpoints*2+1
dstpoints5:	ds.w	maxpoints*2+1

vectrans_transform:
		move.w	rotz(pc),d0
		addi.w	#rotspeed,d0
		andi.w	#$ffe,d0
		move.w	d0,rotz
		
		move.w	movex(pc),d1
		addi.w	#xspeed,d1
		andi.w	#$ffe,d1
		move.w	d1,movex
		
		move.w	movey(pc),d2
		addi.w	#yspeed,d2
		andi.w	#$ffe,d2
		move.w	d2,movey
		
		lea		vectrans_sintab,a0
		move.w	(a0,d0.w),d6
		addi.w	#$400,d0
		move.w	(a0,d0.w),d7

		move.w	(a0,d1.w),d4
		move.w	(a0,d2.w),d5

		lea		dstpoints1,a1		

		move.w	zpos(pc),d0
		addi.w	#zspeed,d0
		move.w	d0,zpos
		
		bpl.b	.nozclip
		moveq	#0,d0
.nozclip:
		addq	#1,d0
				
		move.l	#1000000,d1
		divs.w	d0,d1
		
		muls.w	d1,d6
		muls.w	d1,d7
		swap	d6
		swap	d7
		
		muls.w	#xscale,d4
		muls.w	#yscale,d5
		swap	d4
		swap	d5
		addi.w	#width/2,d4
		addi.w	#height/2,d5
		
		lea		points,a0
.l0:
		move.w	(a0)+,d0
		cmpi.w	#$8000,d0
		beq.b	.end
		move.w	(a0)+,d1
		
		move.w	d0,d2
		move.w	d1,d3
		
		muls.w	d6,d0	;x*sz
		muls.w	d6,d1	;y*sz
		muls.w	d7,d2	;x*cz
		muls.w	d7,d3	;y*cz
		add.l	d3,d0	;x*sz+y*cz
		sub.l	d1,d2	;x*cz-y*sz
		
		swap	d0
		swap	d2
		add.w	d4,d0
		add.w	d5,d2
		move.w	d0,(a1)+
		move.w	d2,(a1)+
		
		bra.b	.l0
.end:
		move.w	#$8000,(a1)+
		rts
		
;--------------------------------------------------------------------

vectrans_clip:
		lea		dstpoints1,a0
		lea		dstpoints2,a1
		move.l	a1,a2
.l0:
		movem.w	(a0),d0-d3
		addq	#4,a0
		cmpi.w	#$8000,d2
		beq.b	.endright

		moveq	#0,d4
		cmpi.w	#maxx,d0
		bgt.b	.noclipright1
		bset	#0,d4
		move.w	d0,(a1)+		;if p1 is inside -> add it to output
		move.w	d1,(a1)+
		
.noclipright1:
		cmpi.w	#maxx,d2
		bgt.b	.noclipright2
		bchg	#0,d4
.noclipright2:

		tst.w	d4
		beq.b	.skipclipright	;if states for p1 and p2 are the same no clipping is needed

		sub.w	d0,d2		;x2-x1
		sub.w	d1,d3		;y2-y1
		move.w	#maxx,d4
		sub.w	d0,d4		;maxx-x1
		
		muls.w	d4,d3		;(y2-y1)*(maxx-x1)
		divs.w	d2,d3		;(y2-y1)*(maxx-x1)/(x2-x1)
		add.w	d3,d1		;y1+(y2-y1)*(maxx-x1)/(x2-x1)
		
		move.w	#maxx,(a1)+	;add clippoint
		move.w	d1,(a1)+

.skipclipright:
		
		bra.b	.l0
.endright:		
		move.w	(a2)+,(a1)+
		move.w	(a2)+,(a1)+	;add first point as last to make loop perfect
		
		move.w	#$8000,(a1)+
		
		
		lea		dstpoints2,a0
		lea		dstpoints3,a1
		move.l	a1,a2
.l1:
		movem.w	(a0),d0-d3
		addq	#4,a0
		cmpi.w	#$8000,d2
		beq.b	.endleft

		moveq	#0,d4
		cmpi.w	#minx,d0
		blt.b	.noclipleft1
		bset	#0,d4
		move.w	d0,(a1)+		;if p1 is inside -> add it to output
		move.w	d1,(a1)+
.noclipleft1:

		cmpi.w	#minx,d2
		blt.b	.noclipleft2
		bchg	#0,d4
.noclipleft2:

		tst.w	d4
		beq.b	.skipclipleft	;if states for p1 and p2 are the same no clipping is needed

		sub.w	d0,d2		;x2-x1
		sub.w	d1,d3		;y2-y1
		move.w	#minx,d4
		sub.w	d0,d4		;minx-x1
		
		muls.w	d4,d3		;(y2-y1)*(minx-x1)
		divs.w	d2,d3		;(y2-y1)*(minx-x1)/(x2-x1)
		add.w	d3,d1		;y1+(y2-y1)*(minx-x1)/(x2-x1)
		
		move.w	#minx,(a1)+	;add clippoint
		move.w	d1,(a1)+

.skipclipleft:
		
		bra.b	.l1
.endleft:		
		move.w	(a2)+,(a1)+
		move.w	(a2)+,(a1)+	;add first point as last to make loop perfect
	
		move.w	#$8000,(a1)+

		
		lea		dstpoints3,a0
		lea		dstpoints4,a1
		move.l	a1,a2
.l2:
		movem.w	(a0),d0-d3
		addq	#4,a0
		cmpi.w	#$8000,d2
		beq.b	.endbottom

		moveq	#0,d4
		cmpi.w	#maxy,d1
		bgt.b	.noclipbottom1
		bset	#0,d4
		move.w	d0,(a1)+		;if p1 is inside -> add it to output
		move.w	d1,(a1)+
		
.noclipbottom1:
		cmpi.w	#maxy,d3
		bgt.b	.noclipbottom2
		bchg	#0,d4
.noclipbottom2:

		tst.w	d4
		beq.b	.skipclipbottom	;if states for p1 and p2 are the same no clipping is needed

		sub.w	d1,d3		;y2-y1
		sub.w	d0,d2		;x2-x1
		move.w	#maxy,d4
		sub.w	d1,d4		;maxy-y1
		
		muls.w	d4,d2		;(x2-x1)*(maxy-y1)
		divs.w	d3,d2		;(x2-x1)*(maxy-y1)/(y2-y1)
		add.w	d2,d0		;x1+(x2-x1)*(maxy-y1)/(y2-y1)
		
		move.w	d0,(a1)+	;add clippoint
		move.w	#maxy,(a1)+	
		
.skipclipbottom:
		
		bra.b	.l2
.endbottom:		
		move.w	(a2)+,(a1)+
		move.w	(a2)+,(a1)+	;add first point as last to make loop perfect
		
		move.w	#$8000,(a1)+

		
		lea		dstpoints4,a0
		lea		dstpoints5,a1
		move.l	a1,a2
.l3:
		movem.w	(a0),d0-d3
		addq	#4,a0
		cmpi.w	#$8000,d2
		beq.b	.endtop

		moveq	#0,d4
		cmpi.w	#miny,d1
		blt.b	.nocliptop1
		bset	#0,d4
		move.w	d0,(a1)+		;if p1 is inside -> add it to output
		move.w	d1,(a1)+
.nocliptop1:

		cmpi.w	#miny,d3
		blt.b	.nocliptop2
		bchg	#0,d4
.nocliptop2:

		tst.w	d4
		beq.b	.skipcliptop	;if states for p1 and p2 are the same no clipping is needed

		sub.w	d1,d3		;y2-y1
		sub.w	d0,d2		;x2-x1
		move.w	#miny,d4
		sub.w	d1,d4		;miny-y1
		
		muls.w	d4,d2		;(x2-x1)*(miny-y1)
		divs.w	d3,d2		;(x2-x1)*(miny-y1)/(y2-y1)
		add.w	d2,d0		;x1+(x2-x1)*(miny-y1)/(y2-y1)
		
		move.w	d0,(a1)+	;add clippoint
		move.w	#miny,(a1)+	
		
.skipcliptop:
		
		bra.b	.l3
.endtop:		
		move.w	(a2)+,(a1)+
		move.w	(a2)+,(a1)+	;add first point as last to make loop perfect
	
		move.w	#$8000,(a1)+
		rts

;--------------------------------------------------------------------

vectrans_dolines:
		move.l	vectrans_screens+4,a5
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		$dff000,a6
		
		move.l 	#$ffffffff,BLTAFWM(a6) 	; first and last mask
		move.w 	#$8000,BLTADAT(a6)		; starting bit
		move.w 	#$ffff,BLTBDAT(a6)		
		move.w 	#linemod,BLTCMOD(a6) 	; screen modulo

		lea		BLTCON0(a6),a6			; smallest offet into blitter registers
		lea		octanttab,a0
		lea		dstpoints5,a2
.l0:
		movem.w	(a2),d0-d3
		tst.w	d2
		bmi.b	.end
		addq	#4,a2
		bsr.w	vectrans_doline
		
		bra.b	.l0
.end:
		rts

;--------------------------------------------------------------------

vectrans_doline:
		moveq	#0,d6				; octant

		sub.w 	d1,d3				; dy
		beq.b	.skip
		bpl.b	.oct2
		exg		d0,d2				
									; d3=p2-p1
									; d1=p1
		neg.w	d3					; d3=p1-p2
									; d1=p1
		sub.w	d3,d1				; d1=p1-p1+p2=p2
.oct2:
		subq	#1,d3

		move.w	d0,d4
		lsr.w	#3,d4				
		mulu.w	#linemod,d1
		add.w	d4,d1
		lea		(a5,d1.w),a1
		
		sub.w	d0,d2				; dx
		bpl.b	.oct1
		neg.w	d2
		addq	#2,d6
.oct1:
		cmp.w	d2,d3
		bmi.b	.oct3
		addq	#1,d6					
		exg		d2,d3
.oct3:
		move.w	d3,d4				; dy
		add.w	d4,d4				; 2*dy
		move.w	d3,d5
		sub.w	d2,d5				; dy-dx
		add.w	d5,d5				; 2*(dy-dx)
		
		add.w	d3,d3
		sub.w	d2,d3				; 2*dy-dx		
		addx.w	d6,d6
		
		add.w	d0,d0
		
		move.b	(a0,d6.w),d6
		andi.w	#$1e,d0
		move.w	mintermtab-octanttab(a0,d0.w),d0
		addq	#1,d2
		lsl.w	#6,d2
		addq	#2,d2
		
.bltwait1:	
		btst	#$0e,$02-BLTCON0(a6)
		bne.b	.bltwait1
		
		move.w 	d3,BLTAPTR+2-BLTCON0(a6)	; 2*dy-dx	initial error term
		movem.w d5/d4,BLTBMOD-BLTCON0(a6) 	; d6=2*dy		->BLTBMOD
											; d4=2*(dy-dx)	->BLTAMOD

		move.b	d6,BLTCON1+1-BLTCON0(a6)
		move.w	d0,BLTCON0-BLTCON0(a6)
		
		move.l  a1,BLTCPTR-BLTCON0(a6) 
		move.l  a1,BLTDPTR-BLTCON0(a6) 
		move.w	d2,BLTSIZE-BLTCON0(a6)		; size
.skip:
		rts
		
octantbase 	= 3	; 1 for normal lines or 3 for fill lines
mintermbase	= $0b5a

		cnop	0,2
octanttab:
		dc.b	$10+octantbase
		dc.b	$50+octantbase
		dc.b	$00+octantbase
		dc.b	$40+octantbase
		dc.b	$14+octantbase
		dc.b	$54+octantbase
		dc.b	$08+octantbase
		dc.b	$48+octantbase
		
mintermtab:
		dc.w	mintermbase+$0000
		dc.w	mintermbase+$1000
		dc.w	mintermbase+$2000
		dc.w	mintermbase+$3000
		dc.w	mintermbase+$4000
		dc.w	mintermbase+$5000
		dc.w	mintermbase+$6000
		dc.w	mintermbase+$7000
		dc.w	mintermbase+$8000
		dc.w	mintermbase+$9000
		dc.w	mintermbase+$a000
		dc.w	mintermbase+$b000
		dc.w	mintermbase+$c000
		dc.w	mintermbase+$d000
		dc.w	mintermbase+$e000
		dc.w	mintermbase+$f000
		
;--------------------------------------------------------------------

vectrans_fill:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6

        move.l	vectrans_screens+4,a0
		adda.w	#planemod-2,a0
		
        move.w	#0,BLTAMOD(a6)
        move.w	#0,BLTDMOD(a6)
        move.w	#$09f0,BLTCON0(a6)	; minterm $f0 = a, channels $9 = a&d
		move.w	#$0012,BLTCON1(a6)	; descending and fill mode
		move.l	a0,BLTAPTR(a6)        			
        move.l	a0,BLTDPTR(a6)        			
        move.w	#height*64+linemod/2,BLTSIZE(a6)
	    rts
		
;--------------------------------------------------------------------
	
vectrans_page:
		lea 	vectrans_screens,a0
	
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		
		move.l	d0,$04(a0)
		move.l	d1,$00(a0)

		lea		flight_fadecopperbpl+4*8,a6
		move.w	d1,$06(a6)
		swap	d1
		move.w	d1,$02(a6)
		rts

;********************************************************************
				
				section "flight_data",data
				
				cnop	0,2
vectrans_sintab:			
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096
				
			ifnd _DEMO
				cnop	0,2
flight_pic0:	
	incbin "../data/flight/pic_0.dat"
				cnop	0,2
flight_pic1:	
	incbin "../data/flight/pic_1.dat"
				cnop	0,2
flight_pic2:	
	incbin "../data/flight/pic_2.dat"
				cnop	0,2
flight_pic3:	
	incbin "../data/flight/pic_3.dat"
				cnop	0,2
flight_pic4:	
	incbin "../data/flight/pic_4.dat"
				cnop	0,2
flight_pic5:	
	incbin "../data/flight/pic_5.dat"
				cnop	0,2
flight_pic6:	
	incbin "../data/flight/pic_6.dat"
				cnop	0,2
flight_pic7:	
	incbin "../data/flight/pic_7.dat"
				cnop	0,2
flight_pic8:	
	incbin "../data/flight/pic_8.dat"
				cnop	0,2
flight_pic9:	
	incbin "../data/flight/pic_9.dat"
			else
flight_pic0:	
flight_pic1:	
flight_pic2:	
flight_pic3:	
flight_pic4:	
flight_pic5:	
flight_pic6:	
flight_pic7:	
flight_pic8:	
flight_pic9:	
flight_pic10:	
flight_pic11:	
flight_pic12:	
flight_pic13:	
flight_pic14:	
flight_pic15:	
			endc	// _DEMO

flight_zoomxs:
	incbin "../data/flight/zoomxs.dat"

;********************************************************************

				section "flight_empty",bss
				
				cnop	0,8
flight_bltcommands:
				ds.b	16*256
				
		ifd _DEMO
flight_loadbuf:
				ds.b	25965+512	
		endc	// _DEMO

;********************************************************************	

				section "flight_emptychip",bss,chip
				
				cnop	0,8
flight_colbuffer1:
				ds.b	17920
flight_colbuffer2:
				ds.b	17920
				
				ds.b	40
flight_planes2:	ds.b	40*256*4
				ds.b	40
				
;********************************************************************

				section "flight_copper",data,chip

flight_copperlist:	
				dc.l	$008e2c82,$00902cc1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

flight_copperbpl:
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000

flight_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040038			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080078,$010a0078						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01004200						;wait x: 15, y: 1, turn on 4 bitplanes

				;dc.l	$ffdffffe
				dc.l	$ef0ffffe,$009c8010						;wait x: 15, y: 33, start irq
				
				dc.l	$fffffffe 								;wait for end

;--------------------------------------------------------------------

flight_fadecopperlist:	
				dc.l	$008e2c82,$00902cc1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

flight_fadecopperbpl:
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000

flight_fadecoppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01005200						;wait x: 15, y: 1, turn on 5 bitplanes
				dc.l	$009c8010								;wait x: 15, y: 33, start irq

				dc.l	$fffffffe 								;wait for end
			
;--------------------------------------------------------------------
	
				cnop	0,8
flight_sprite1:
				dc.w	$3c60,$1c02             ;VSTART, HSTART, VSTOP
				REPT	224
				dc.l	$ffff0000
				ENDR
				dc.l	0
				
				cnop	0,8
flight_sprite2:
				dc.w	$3c60,$1c82             ;VSTART, HSTART, VSTOP
				REPT	224
				dc.l	$ff000000
				ENDR
				dc.l	0

	cnop	0,2
flight_basepic:	
	incbin "../data/flight/basepic.dat"

				ds.b	40
flight_planes1:	
	incbin "../data/flight/screen.ami"
				ds.b	$2828
	
	ifnd _DEMO
				cnop	0,2
flight_pic10:	
	incbin "../data/flight/pic_10.dat"
				cnop	0,2
flight_pic11:	
	incbin "../data/flight/pic_11.dat"
				cnop	0,2
flight_pic12:	
	incbin "../data/flight/pic_12.dat"
				cnop	0,2
flight_pic13:	
flight_pic14:	
flight_pic15:	
				ds.b	32704
	endc	// _DEMO

;TODO:	- 
	
VECTORIZER_NUMFRAMES1 	= 258
VECTORIZER_NUMFRAMES2 	= 254
VECTORIZER_NUMFRAMES 	= VECTORIZER_NUMFRAMES1+VECTORIZER_NUMFRAMES2+64
	
	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
			
			section	"vectorizer_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable
				
		lea		vectorizer_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)

		bsr.w	vectorizer_init

		lea		morph_mesh1,a0
		lea		morph_mesh2,a1
		bsr.w	morph_init
	
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#VECTORIZER_NUMFRAMES1,d0
		move.w	d0,vectorizer_endframe1
		
		move.l	#vectorizer_data1,d0
		move.l	#vectorizer_dataend1,d1
		bsr.w	vectorizer_initobject
		bsr.w	vectorizer_update

		move.w	#TIME_WIREFRAME_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#vectorizer_copperlist,a0
		move.l	#vectorizer_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
vectorizer_main1:
		bsr.w	vectorizer_update
		
		btst	#$06,$bfe001
		beq.w	vectorizer_end
		
		move.w	#TIME_MORPH1_START,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	vectorizer_main1

		jsr		morph_start
				
		move.l	#vectorizer_data2,d0
		move.l	#vectorizer_dataend2,d1
		bsr.w	vectorizer_initobject

		bsr.w	vectorizer_update
		bsr.w	vectorizer_update
	
		move.l	#vectorizer_copperlist,a0
		move.l	#vectorizer_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#VECTORIZER_NUMFRAMES2,d0
		move.w	d0,vectorizer_endframe2
		
vectorizer_main2:
		bsr.w	vectorizer_update
		
		btst	#$06,$bfe001
		beq.b	vectorizer_end
		
		move.w	#TIME_MORPH2_INIT,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	vectorizer_main2

		lea		morph_mesh2,a0
		lea		morph_mesh3,a1
		bsr.w	morph_init
	
		move.w	#TIME_MORPH2_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		jsr		morph_start

vectorizer_end:
		;move.l	fw_jumptable,a6
		;jsr		SETBASECOPPER(a6)
		rts		

		cnop	0,4
fw_jumptable:
		dc.l	0
vectorizer_endframe1:
		dc.w	0
vectorizer_endframe2:
		dc.w	0
		
;--------------------------------------------------------------------
		
vectorizer_init:
		lea		vectorizer_lsl6add66tab,a2
		moveq	#0,d7
.l1:			
		move.w	d7,d0
		lsl.w	#6,d0
		add.w	#66,d0
		move.w	d0,(a2)+
		addq	#1,d7
		cmpi.w	#256,d7
		bne.b	.l1
		rts
		
;--------------------------------------------------------------------

vectorizer_update:
		bsr.w	vectorizer_clear
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		bsr.w	vectorizer_dolines
		
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
	
		bsr.w	vectorizer_fadecol
			
		bsr.w	vectorizer_page
		rts
		
;--------------------------------------------------------------------
		
vectorizer_fadeframe:
		dc.w	0
		
vectorizer_colfadetab:
		dc.w	$0fff,$0eee,$0ddd,$0ccc,$0bbb,$0aaa,$0999,$0888,$0777,$0666,$0555,$0444,$0333,$0222,$0111,$0000
		dc.w	$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff
	
vectorizer_pal:
		dc.w	$0000,$0fff,$0aaa,$0fff,$0555,$0fff,$0aaa,$0fff

vectorizer_fadecol:
		move.w	vectorizer_fadeframe(pc),d0
		cmpi.w	#15*2,d0
		blt.b	.fadein
		rts		

.fadein:
		lsr.w	#1,d0
		add.w	d0,d0
		
		lea		vectorizer_colfadetab(pc),a0
		adda.w	d0,a0
		lea		$dff180,a1
		
		move.w	32*0(a0),d0
		move.w	32*1(a0),d1
		
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		rts

;--------------------------------------------------------------------

vectorizer_clear:
		move.l	vectorizer_screens+4,a0
		adda.w	#64*100,a0
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6
		move.w	#24,BLTDMOD(a6)
		clr.w	BLTADAT(a6)
		move.l  a0,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #$1914,BLTSIZE(a6)

		move.l	vectorizer_screens+4,a6
		adda.w	#40,a6
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		move.l	d0,a0
		move.l	d0,a1
		move.l	d0,a2
		
		move.w	#100/10-1,d7
.l0:
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		movem.l	d0-d6/a0-a2,-(a6)
		lea		104(a6),a6
		dbra	d7,.l0
		rts
						
;--------------------------------------------------------------------
	
octantbase 	= 1	; 1 for normal lines or 3 for fill lines
mintermbase	= $0bea

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
		REPT 20
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
		ENDR

;--------------------------------------------------------------------

		MACRO<VECTORIZER_DOLINE>
		move.l	a2,a5
		
		moveq	#0,d6				; octant

		sub.w 	d1,d3				; dy
		bpl.b	.oct2\@
		exg		d0,d2				
									; d3=p2-p1
									; d1=p1
		neg.w	d3					; d3=p1-p2
									; d1=p1
		sub.w	d3,d1				; d1=p1-p1+p2=p2
.oct2\@:
		move.w	d0,d4
		lsr.w	#3,d4				
		lsl.w	#6,d1
		add.w	d4,d1
		adda.w	d1,a5
		
		sub.w	d0,d2				; dx
		bpl.b	.oct1\@
		neg.w	d2
		addq	#2,d6
.oct1\@:
		cmp.w	d2,d3
		bmi.b	.oct3\@
		addq	#1,d6					
		exg		d2,d3
.oct3\@:
		move.w	d3,d4				; dy
		add.w	d4,d4				; 2*dy
		move.w	d3,d5
		sub.w	d2,d5				; dy-dx
		add.w	d5,d5				; 2*(dy-dx)
		
		add.w	d3,d3
		sub.w	d2,d3				; 2*dy-dx		
		addx.w	d6,d6
		
		add.w	d0,d0
		add.w	d2,d2
		
		move.b	(a0,d6.w),d6
		move.w	mintermtab-octanttab(a0,d0.w),d0
		move.w	(a4,d2.w),d2

.bltwait2\@:
		btst	#$0e,$02-BLTCON0(a6)
		bne.b	.bltwait2\@
		
		move.w 	d3,BLTAPTR+2-BLTCON0(a6)	; 2*dy-dx		initial error term
		movem.w d5/d4,BLTBMOD-BLTCON0(a6) 	; d6=2*dy		->BLTBMOD
											; d4=2*(dy-dx)	->BLTAMOD

		move.b	d6,BLTCON1+1-BLTCON0(a6)
		move.w	d0,BLTCON0-BLTCON0(a6)
		
		move.l  a5,BLTCPTR-BLTCON0(a6) 
		move.l  a5,BLTDPTR-BLTCON0(a6) 
		move.w	d2,BLTSIZE-BLTCON0(a6)		; size
		
		bra.w	vectorizer_dlloop
		ENDM
		
;--------------------------------------------------------------------

		MACRO<VECTORIZER_FETCHHIX>
		add.b	d7,d7
		bne.b	.skip\@
		move.b	(a3)+,d7
		addx.b	d7,d7
.skip\@:
		ENDM
		
;--------------------------------------------------------------------
		
			cnop	0,4
vectorizer_datapoi:
		dc.l	vectorizer_data1
vectorizer_datastartpoi:
		dc.l	vectorizer_data1
vectorizer_dataendpoi:
		dc.l	vectorizer_dataend1

;--------------------------------------------------------------------

vectorizer_initobject:
		move.l	d0,vectorizer_datapoi
		move.l	d0,vectorizer_datastartpoi
		move.l	d1,vectorizer_dataendpoi
		rts
	
;--------------------------------------------------------------------
			
		cnop	0,2
vectorizer_oldcoords:
		ds.w	4
		
vectorizer_dolines:
		move.l	vectorizer_screens+4,a2
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		$dff000,a6
		
		move.l 	#$ffffffff,BLTAFWM(a6) 	; first and last mask
		move.w 	#$8000,BLTADAT(a6)
		move.w 	#$ffff,BLTBDAT(a6)
		move.w 	#64,BLTCMOD(a6) 	

		lea		BLTCON0(a6),a6			; smallest offet into blitter registers
		lea		octanttab,a0
		lea		vectorizer_lsl6add66tab,a4
		lea		vectorizer_oldcoords,a1
	
		move.l	vectorizer_datapoi,a3
		move.w	#$80,d7		;initial byte for xhi-stream
		
vectorizer_dlloop:
		moveq	#0,d1		
		move.b	(a3)+,d1	;y1
		cmpi.b	#$c8,d1
		beq.w	vectorizer_sharep1
		cmpi.b	#$c9,d1
		beq.w	vectorizer_sharep2
		cmpi.b	#$ff,d1		
		beq.w	vectorizer_endlines
vectorizer_noshare:
		moveq	#0,d0		
		move.b	(a3)+,d0	;x1lo
		VECTORIZER_FETCHHIX
		addx.w	d0,d0
.nohix11:
		
		moveq	#0,d2		
		moveq	#0,d3		
		move.b	(a3)+,d3	;y2
		move.b	(a3)+,d2	;x2lo
		VECTORIZER_FETCHHIX
		addx.w	d2,d2
.nohix12:
		movem.w	d0-d3,(a1)
		VECTORIZER_DOLINE
		
vectorizer_sharep1:
		movem.w	(a1),d0-d1
		moveq	#0,d2		
		moveq	#0,d3		
		move.b	(a3)+,d3	;y2
		move.b	(a3)+,d2	;x2lo
		VECTORIZER_FETCHHIX
		addx.w	d2,d2
.nohix2:
		movem.w	d2-d3,4(a1)
		VECTORIZER_DOLINE
		
vectorizer_sharep2:
		movem.w	4(a1),d2-d3
		moveq	#0,d0		
		moveq	#0,d1		
		move.b	(a3)+,d1	;y1
		move.b	(a3)+,d0	;x1lo
		VECTORIZER_FETCHHIX
		addx.w	d0,d0
.nohix3:
		movem.w	d0-d1,(a1)
		VECTORIZER_DOLINE
		
vectorizer_endlines:
		move.l	vectorizer_dataendpoi(pc),a0
		cmp.l	a0,a3
		bne.b	.nowrap
		move.l	vectorizer_datastartpoi(pc),a3
.nowrap:
		move.l	a3,vectorizer_datapoi
		rts

;--------------------------------------------------------------------

		cnop	0,4
vectorizer_screens:
		dc.l	vectorizer_screen1,vectorizer_screen2,vectorizer_screen3,vectorizer_screen4
vectorizer_screen:
		dc.l	vectorizer_screen1

vectorizer_page:
		lea 	vectorizer_screens,a0
		
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		move.l	$0c(a0),d3
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$0c(a0)
		move.l	d3,$00(a0)
		
		move.l	d2,d0
		
		lea		vectorizer_copperbpl,a6
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)
		rts

;--------------------------------------------------------------------

		cnop	0,2
vectorizer_sync:
		dc.w	0

vectorizer_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		
		addq.w	#1,vectorizer_sync
		addq.w	#1,vectorizer_fadeframe
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  

;********************************************************************

morph_start:
		lea		morph_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		move.l	#morph_copperlist,a0
		move.l	#morph_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		jsr		GETFRAME(a6)
		addi.w	#64,d0
		move.w	d0,morph_endframe
		
morph_main:
		bsr.w	morph_update
		
		move.w	morph_endframe,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	morph_main
		rts
		
		cnop	0,2
morph_endframe:
		dc.w	0
		
;--------------------------------------------------------------------
		
		cnop	0,4
morph_pois:
		ds.l	2
		
morph_init:
		movem.l	a0/a1,morph_pois
		bsr.w	morph_initplots
		bsr.w	morph_initmorph
		clr.w	morph_frame
	
		bsr.w	morph_update
		rts
				
;--------------------------------------------------------------------

morph_initpal:
		lea		$dff180,a0
		move.w	#$000,(a0)+
		move.w	#$fff,(a0)+
		rts
		
;--------------------------------------------------------------------

morph_initplots:
		movem.l	morph_pois(pc),a0/a1
		lea		morph_plotcode,a2
		move.w	#MORPH_NUMPLOTS-1,d7
.l0:
		move.w	(a0)+,d0
		move.w	(a0)+,d1
		move.w	(a1)+,d4
		addq	#2,a1
		
		lsl.w	#6,d1
		move.w	d0,d2
		not.b	d2
		andi.w	#$07,d2
		sub.w	d0,d4
		bpl.b	.noneg
		ori.w	#$f8,d2
.noneg:
		lsr.w	#3,d0
		add.w	d0,d1
		
		move.w	#$08ee,(a2)+	;bset.b	#$xx,$xx(a6)
		move.w	d2,(a2)+		;bit to set
		move.w	d1,(a2)+		;offset into bitmap
		
		dbra	d7,.l0
		
		move.w	#$4e75,(a2)+	;rts
		rts

;--------------------------------------------------------------------
		
 MACRO<MORPH_CHECKBIT_X>
		btst	#6-\1,d2
		beq.b	.skip\@
		move.l	4*\1(a3),a2
		
		move.w	d7,d5
		add.w	d5,d5
		
		tst.w	d1
		bpl.b	.noneg\@
		
		move.w	#$d328,(a2)+	;add.b	d1,$1234(a0)
		addq	#1,d5
		move.w	d5,(a2)+		;offset
		move.w	#$6b08,(a2)+	;bmi.b	.nonewbyte
		move.w	#$1143,(a2)+	;move.b	d3,$1234(a0)
		move.w	d5,(a2)+		;offset
		move.w	#$5368,(a2)+	;subq.w	#1,$1234(a0)
		addq	#1,d5
		move.w	d5,(a2)+		;offset+2
		
		bra.b	.endneg\@
.noneg\@:
		move.w	#$9328,(a2)+	;sub.b	d1,$1234(a0)
		addq	#1,d5
		move.w	d5,(a2)+		;offset
		move.w	#$6a08,(a2)+	;bpl.b	.nonewbyte
		move.w	#$1142,(a2)+	;move.b	d2,$1234(a0)
		move.w	d5,(a2)+		;offset
		move.w	#$5268,(a2)+	;addq.w	#1,$1234(a0)
		addq	#1,d5
		move.w	d5,(a2)+		;offset+2
		
.endneg\@:
		move.l	a2,4*\1(a3)
.skip\@:
 ENDM
 
 MACRO<MORPH_CHECKBIT_Y>
		btst	#6-\1,d2
		beq.b	.skip\@
		move.l	4*\1(a3),a2
		
		move.w	#$d168,d4		;add.w	d0,xx(a0)
		tst.w	d1
		bpl.b	.noneg\@
		move.w	#$9168,d4		;sub.w	d0,xx(a0)
.noneg\@:
		move.w	d7,d5
		add.w	d5,d5
		
		move.w	d4,(a2)+
		move.w	d5,(a2)+
		move.l	a2,4*\1(a3)
.skip\@:
 ENDM

morph_initmorph:
		movem.l	morph_pois(pc),a0/a1
		
		lea		morph_speedcodes,a2
		lea		morph_speedends,a3
		moveq	#7-1,d7
.l00:
		move.l	(a2)+,(a3)+
		dbra	d7,.l00
		
		lea		morph_speedends,a3
		moveq	#0,d7
.l0:
		addq	#1,d7
		
		move.w	(a0)+,d0
		move.w	(a1)+,d1
		sub.w	d0,d1
		move.w	d1,d2
		bpl.b	.noneg1
		neg.w	d2
.noneg1:
		MORPH_CHECKBIT_X 0
		MORPH_CHECKBIT_X 1
		MORPH_CHECKBIT_X 2
		MORPH_CHECKBIT_X 3
		MORPH_CHECKBIT_X 4
		MORPH_CHECKBIT_X 5
		MORPH_CHECKBIT_X 6
		
		addq	#1,d7
		
		move.w	(a0),d0
		move.w	(a1)+,d1
		sub.w	d0,d1
		lsl.w	#6,d0
		move.w	d0,(a0)+
		move.w	d1,d2
		bpl.b	.noneg2
		neg.w	d2
.noneg2:
		MORPH_CHECKBIT_Y 0
		MORPH_CHECKBIT_Y 1
		MORPH_CHECKBIT_Y 2
		MORPH_CHECKBIT_Y 3
		MORPH_CHECKBIT_Y 4
		MORPH_CHECKBIT_Y 5
		MORPH_CHECKBIT_Y 6
		
		addq	#1,d7
		cmpi.w	#MORPH_NUMPLOTS*3,d7
		bne.w	.l0
		
		moveq	#7-1,d7
.l1:
		move.l	(a3),a2
		move.w	#$4e75,(a2)+	;rts
		move.l	a2,(a3)+
		
		dbra	d7,.l1
		rts
		
;--------------------------------------------------------------------

morph_update:
		bsr.w	morph_clear
		bsr.w	morph_morph
		bsr.w	morph_morph
		bsr.w	morph_plot
		bsr.w	morph_page
		
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		rts
		
;--------------------------------------------------------------------

morph_clear:
		move.l	morph_screens+0,a0
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#24,BLTDMOD(a6)
		clr.w	BLTADAT(a6)
		move.l  a0,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #$3214,BLTSIZE(a6)
		rts
		
;--------------------------------------------------------------------

			cnop 0,2
morph_frame:
			dc.w	0
morph_morphtab:
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,5
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,6	
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,5
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4
			dc.w	0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,7
			
morph_morph:
		move.w	morph_frame(pc),d7
		addq	#1,d7
		move.w	d7,morph_frame
		
		cmpi.w	#127,d7
		ble.b	.do
		rts
			
.do:		
		lea		morph_plotcode,a0
		moveq	#64,d0
		moveq	#1,d1
		moveq	#$07,d2
		move.w	#$f8,d3
		
		lea		morph_morphtab,a2
		subq	#1,d7
		add.w	d7,d7
		move.w	(a2,d7.w),d7
		add.w	d7,d7
		add.w	d7,d7
		lea		morph_speedcodes,a1
		move.l	(a1,d7.w),a1
		jmp 	(a1)
		
;--------------------------------------------------------------------

MORPH_NUMPLOTS	= 2261
				
morph_plot:
		move.l	morph_screens+4,a6
		jmp 	morph_plotcode
		
;--------------------------------------------------------------------

morph_screens:
		dc.l	morph_screen1,morph_screen2,morph_screen3

morph_page:
		lea 	morph_screens,a0

		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)
		
		lea		morph_copperbpl,a6
		
		move.l	d1,d0
		
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)
		rts

;--------------------------------------------------------------------
		
		cnop	0,4
morph_regsave:	
		ds.l	$10
		
morph_irq:		
		movem.l	d0-d7/a0-a6,morph_regsave

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
	
		addq.w	#1,vectorizer_fadeframe
		
		move.w	#$0010,$dff09c
		movem.l	morph_regsave(pc),d0-d7/a0-a6
		rte  

;--------------------------------------------------------------------
		
morph_speedcodes:
				dc.l	morph_speedcode1
				dc.l	morph_speedcode2
				dc.l	morph_speedcode3
				dc.l	morph_speedcode4
				dc.l	morph_speedcode5
				dc.l	morph_speedcode6
				dc.l	morph_speedcode7
morph_speedends:
				dc.l	morph_speedcode1
				dc.l	morph_speedcode2
				dc.l	morph_speedcode3
				dc.l	morph_speedcode4
				dc.l	morph_speedcode5
				dc.l	morph_speedcode6
				dc.l	morph_speedcode7
				
;********************************************************************
			
				section "vectorizer_data",data

				cnop	0,2
vectorizer_data1:		
	incbin "../data/vectorizer/lobster.dat"
vectorizer_dataend1:

vectorizer_data2:	
	incbin "../data/vectorizer/donut6lines.dat"
vectorizer_dataend2:

;********************************************************************
			
				cnop	0,2
morph_mesh1:		
	incbin "../data/morph/mesh1.dat"
	
morph_mesh2:		
	incbin "../data/morph/mesh2.dat"

morph_mesh3:		
	incbin "../data/morph/mesh3.dat"
				
;********************************************************************
			
				section "vectorizer_empty",bss
				
				cnop	0,2
vectorizer_lsl6add66tab:
				ds.w	256
				
;********************************************************************

				cnop	0,2
morph_speedcode1:
				ds.w	MORPH_NUMPLOTS*5+1
morph_speedcode2:                      
				ds.w	MORPH_NUMPLOTS*5+1
morph_speedcode3:                      
				ds.w	MORPH_NUMPLOTS*5+1
morph_speedcode4:                      
				ds.w	MORPH_NUMPLOTS*5+1
morph_speedcode5:                      
				ds.w	MORPH_NUMPLOTS*5+1
morph_speedcode6:                      
				ds.w	MORPH_NUMPLOTS*5+1
morph_speedcode7:                      
				ds.w	MORPH_NUMPLOTS*5+1
morph_plotcode:
				ds.w	MORPH_NUMPLOTS*3+1

;********************************************************************
			
				section "vectorizer_emptychip",bss,chip

				cnop	0,8
vectorizer_screen1:	ds.b	$3200*1
vectorizer_screen2:	ds.b	$3200*1
vectorizer_screen3:	ds.b	$3200*1
vectorizer_screen4:	ds.b	$3200*1

;********************************************************************
		
				cnop	0,8
morph_screen1:	ds.b	$3200
morph_screen2:	ds.b	$3200
morph_screen3:	ds.b	$3200

;********************************************************************

				section "vectorizer_copper",data,chip

vectorizer_copperlist:
				dc.l	$008e4c81,$009014c1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

vectorizer_copperbpl:	
				dc.l	$00e00000,$00e20000						;1 bitplane pointer
				
vectorizer_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080018,$010a0018						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01001200						;wait x: 15, y: 1, turn on 3 bitplanes

				dc.l	$b00ffffe,$009c8010						;wait x: 15, y: 33, start irq
			
				dc.l	$fffffffe 								;wait for end

;********************************************************************

				cnop	0,8
morph_copperlist:
				dc.l	$008e4c81,$009014c1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

morph_copperbpl:	
				dc.l	$00e00000,$00e20000						;1 bitplane pointer
				
morph_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080018,$010a0018						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01001200						;wait x: 15, y: 1, turn on 1 bitplanes

				dc.l	$009c8010								;start irq

				dc.l	$fffffffe 								;wait for end
				
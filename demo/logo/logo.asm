;TODO: 	- save chip-mem (only triple-buffer)
;		- put logo into fastmem and copy into buffer
	
	include "../framework/framework.i"	
	include "../framework/hardware.i"	
	include "../launcher/timings.asm"	
			
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

logo_width	= 320
logo_height	= 113
logo_depth	= 4
logo_bplsize= logo_width*logo_height/8

	
			section	"logo_code",code 
		
entrypoint:
		bra.b	logo_start
		bra.b	logo_end
		
logo_start:
		move.l	a6,fw_jumptable
	
		jsr		intro_do
		
		bsr.w	logo_init

		lea		logo_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		move.w	#TIME_LOGO_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
	
		move.l	#logo_copperlist,a0
		move.l	#logo_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)

		bsr.w	logo_fadein

		move.w	#TIME_LOGO_STOP,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
	
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#400,d0
		move.w	d0,logo_endframe
 		rts
		
logo_end:	
		move.l	fw_jumptable,a6
		move.w	logo_endframe(pc),d0
		jsr		WAITFORFRAME(a6)	

		bsr.w	logo_fadeout
		
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)	
		rts
			
		cnop	0,4
fw_jumptable:
		dc.l	0
logo_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

logo_init:
		lea 	logo_image,a0
		move.w	(a0)+,d0	;palette size in entries
		move.w	(a0)+,d1	;width of bitplane in bytes
		move.w	(a0)+,d2	;size of bitplane in bytes
		move.l	(a0)+,d3	;size of image in bytes
		
		lea		$dff180,a1
		ext.l	d0
		subq.l	#1,d0
.l0:	
		clr.w	(a1)+
		addq	#2,a0
		dbra	d0,.l0
		
		move.l	a0,d0
		
		lea		logo_copperbpl,a0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		addi.l	#logo_bplsize*1,d1
		addi.l	#logo_bplsize*2,d2
		addi.l	#logo_bplsize*3,d3
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

;d4 - col
logo_updatecopper:
		move.l	#$8addfffe,d0
		move.l	#$8b41fffe,d1
		move.l	#$01000000,d2
		move.w	#$0180,d3
		lea		logo_coppercols,a0
		
		move.l	#$8a0ffffe,(a0)+
		move.w	d3,(a0)+
		move.w	d4,(a0)+
		
		moveq	#73-1,d7
.l0:
		move.l	d0,(a0)+
		move.w	d3,(a0)+
		move.w	d4,(a0)+
.l1:
		move.l	d1,(a0)+
		move.w	#$0180,(a0)+
		move.w	d5,(a0)+
		
		add.l	d2,d0
		add.l	d2,d1
		dbra	d7,.l0

		move.l	d0,(a0)+
		move.w	d3,(a0)+
		move.w	d4,(a0)+
		move.l	#$d40ffffe,(a0)+
		move.w	#$0180,(a0)+
		move.w	d5,(a0)+
		rts

;--------------------------------------------------------------------

logo_fadein:
		move.w	#$fff,logo_fadecol
		
		moveq	#1,d4
		
		suba.l	a5,a5
		moveq	#0,d0
		move.w	#68,d5
		bsr.w	logo_fadeloop
		rts
		
;--------------------------------------------------------------------

logo_fadeout:
		clr.w	logo_fadecol
		
		moveq	#-1,d4
		
		suba.l	a5,a5
		moveq	#67,d0
		move.w	#0,d5
		bsr.w	logo_fadeloop
		rts

;--------------------------------------------------------------------
		
logo_waitloop:
.l0:
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
 	
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------
		
logo_fadeloop:
.l0:		
		movem.w	d0/d4/d5,-(sp)
		bsr.w	logo_fade
		movem.w	(sp)+,d0/d4/d5
		
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
 	
		add.w	d4,d0
		cmp.w	d5,d0
		bne.b	.l0
		rts

;--------------------------------------------------------------------

		cnop	0,2
logo_tmpcols:
		ds.w	16
logo_fadecol:
		dc.w	0

logo_fade:
		lsr.w	#2,d0

		lea 	logo_image+10,a0
		lea		$dff180,a1
		lea		logo_tmpcols,a2
		adda.l	a5,a0
		adda.l	a5,a1
		
		move.w	logo_fadecol(pc),d4
		move.w	d4,d5
		move.w	d4,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6

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
		move.w	d1,(a2)+
		dbra	d7,.l0
		
		move.w	logo_tmpcols+0,d5
		move.w	logo_tmpcols+2,d4
		bra.w	logo_updatecopper
		
;--------------------------------------------------------------------

logo_irq:		
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
		
			
width	= 368
height	= 285
minx	= 0
maxx	= width-1
miny	= 0
maxy	= height-1

linemod		= width/8
planemod	= linemod*height
			
;********************************************************************
	
intro_do:
		lea		intro_sintab,a0
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

		lea		intro_oxyron,a0
		bsr.w	intro_init

		addq.w	#1,frame

		moveq	#3-1,d7
.l0:
		move.w	d7,-(sp)
		move.w	#1,intro_sync
		bsr.w	intro_doframe
		move.w	(sp)+,d7
		dbra	d7,.l0		
	
		move.l	#intro_copperlist,a0
		move.l	#intro_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)

		bsr.w	intro_setpal
		addq	#1,frame

intro_main:
		addq.w	#1,frame

		bsr.w	intro_doframe
					
		btst	#$06,$bfe001
		beq.b	intro_end
		
		cmp.w	#128,frame
		bne.b	intro_main
intro_end:
		rts		
		
;--------------------------------------------------------------------

intro_setpal:
		lea		$dff180,a1
		clr.w	(a1)+
		move.w	#$fff,(a1)+
		rts

;--------------------------------------------------------------------

intro_doframe:
		;move.w	#$0800,$dff180
		bsr.w	intro_clear
		;move.w	#$0080,$dff180
		bsr.w	intro_transform
		;move.w	#$0008,$dff180
		bsr.w	intro_fill
		;move.w	#$0880,$dff180
		bsr.w	intro_clip

.vsync:
		tst.w	intro_sync
		beq.b	.vsync
		clr.w	intro_sync
		
		;move.l	fw_jumptable,a6
		;jsr		VSYNC(a6)

		bsr.w	intro_page
		;move.w	#$0088,$dff180
		
		bsr.w	intro_dolines
		;move.w	#$0000,$dff180
		rts
	
;--------------------------------------------------------------------

intro_clear:
		move.l	intro_screens+$04,a0
		
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
		rts

;--------------------------------------------------------------------

intro_init:
		bsr.w	intro_initlogo
	
		lea		linemodtab,a0
		moveq	#0,d0
		move.w	#height-1,d7
.l0:		
		move.w	d0,(a0)+
		addi.w	#linemod,d0
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

;a0 - datapointer
intro_initlogo:
		move.w	(a0)+,d0
		move.w	d0,numpoints
		move.l	a0,points
		lsl.w	#2,d0
		adda.w	d0,a0
		move.w	(a0)+,d0
		move.w	d0,numedges
		move.l	a0,edges
		rts

;--------------------------------------------------------------------

maxpoints	= 200
maxlines	= 300

			cnop 	0,4
points:		dc.l	0
edges:		dc.l	0
numpoints:	dc.w	0
numedges:	dc.w	0

frame:		dc.w	0
rotz:		dc.w	$0400
scale:		dc.w	1700

lerpx:		ds.w	128
lerpy:		ds.w	128

intro_transform:
		move.w	rotz(pc),d0
		addi.w	#16,d0
		andi.w	#$ffe,d0
		move.w	d0,rotz
		
		lea		intro_sintab,a0
		move.w	(a0,d0.w),d6
		addi.w	#$400,d0
		move.w	(a0,d0.w),d7

		move.w	frame(pc),d0
		andi.w	#$ff,d0
		addq	#1,d0
		move.l	#32767,d1
		divs.w	d0,d1
		add.w	d1,d1
				
		muls.w	d1,d6
		muls.w	d1,d7
		lsl.l	#2,d6
		lsl.l	#2,d7
		move.l	d6,d4
		move.l	d7,d5
		neg.l	d4
		neg.l	d5
		sub.l	d4,d6
		sub.l	d5,d7
		asr.l	#7,d6
		asr.l	#7,d7
		swap	d4
		swap	d5
		swap	d6
		swap	d7
		add.w	#0,d0
		
		lea		lerpx,a0
		moveq	#128/8-1,d3
.l0:
		REPT	8
		move.w	d4,(a0)+
		addx.l	d6,d4
		ENDR
		dbra	d3,.l0

		lea		lerpy,a0
		moveq	#128/8-1,d3
.l1:
		REPT	8
		move.w	d5,(a0)+
		addx.l	d7,d5
		ENDR
		dbra	d3,.l1
		
		move.w	#width/2,d4
		move.w	#height/2,d6

		lea		lerpx,a3
		lea		lerpy,a4

		move.l	points(pc),a0
		lea		dstpoints,a1	
		move.w	numpoints(pc),d5
		subq	#1,d5
.l2:
		move.w	(a0)+,d0
		move.w	(a0)+,d1

		move.w	2(a3,d0.w),d2	;x*sz
		add.w	2(a4,d1.w),d2	;x*sz+y*cz

		move.w	2(a4,d0.w),d3	;x*cz
		sub.w	2(a3,d1.w),d3	;x*cz-y*sz

		asr.w	#2,d2
		asr.w	#2,d3
		
		add.w	d4,d2
		add.w	d6,d3
		move.w	d2,(a1)+
		move.w	d3,(a1)+
		
		dbra	d5,.l2
.end:
		rts
		
;--------------------------------------------------------------------
		
intro_clip:
		move.l	edges(pc),a0
		lea		dstpoints,a1
		lea		dstlines,a2
		
		move.w	numedges(pc),d7
		subq	#1,d7
.l0:
		move.w	(a0)+,d4
		move.w	(a0)+,d5
		movem.w	(a1,d4.w),d0-d1
		movem.w	(a1,d5.w),d2-d3
		
		cmp.w	d1,d3
		bpl.b	.noswap1
		exg		d0,d2
		exg		d1,d3
.noswap1:

		moveq	#miny,d4
		move.w	#maxy,d5

		cmp.w	d4,d3
		blt.w	.skip

		cmp.w	d5,d1
		bgt.w	.skip
		
		cmp.w	d4,d1
		bge.b	.clipy1
		
		sub.w	d2,d0		;x1-x2
		sub.w	d3,d1		;y1-y2
		move.w	d4,d6
		sub.w	d3,d6		;miny-y2
		
		muls.w	d6,d0		;(x1-x2)*(miny-y2)
		divs.w	d1,d0		;(x1-x2)*(miny-y2)/(y1-y2)
		add.w	d2,d0		;x2+(x1-x2)*(miny-y2)/(y1-y2)
		
		move.w	d4,d1		
.clipy1:

		cmp.w	d5,d3
		ble.b	.clipy2

		sub.w	d0,d2		;x2-x1
		sub.w	d1,d3		;y2-y1
		move.w	d5,d6
		sub.w	d1,d6		;maxy-y1
		
		muls.w	d6,d2		;(x2-x1)*(maxy-y1)
		divs.w	d3,d2		;(x2-x1)*(maxy-y1)/(y2-y1)
		add.w	d0,d2		;x1+(x2-x1)*(maxy-y1)/(y2-y1)
		
		move.w	d5,d3		
.clipy2:

		cmp.w	d0,d2
		bpl.b	.noswap2
		exg		d0,d2
		exg		d1,d3
.noswap2:

		moveq	#minx,d4
		move.w	#maxx,d5

		cmp.w	d4,d2
		bge.b	.clipx1
		
		move.w	d4,d0
		move.w	d4,d2
		bra.w	.skipclip
.clipx1:

		cmp.w	d5,d0
		ble.b	.clipx2
		
		move.w	d5,d0
		move.w	d5,d2
		bra.b	.skipclip
.clipx2:
		cmp.w	d4,d0
		bge.b	.clipx3

		move.w	d4,(a2)+
		move.w	d1,(a2)+
				
		sub.w	d2,d0		;x1-x2
		sub.w	d3,d1		;y1-y2
		move.w	d4,d6
		sub.w	d2,d6		;minx-x2
		
		muls.w	d6,d1		;(y1-y2)*(minx-x2)
		divs.w	d0,d1		;(y1-y2)*(minx-x2)/(x1-x2)
		add.w	d3,d1		;y2+(y1-y2)*(minx-x2)/(x1-x2)
		
		move.w	d4,d0
		
		move.w	d0,(a2)+
		move.w	d1,(a2)+
.clipx3:		

		cmp.w	d5,d2
		ble.b	.clipx4
		
		move.w	d5,(a2)+
		move.w	d3,(a2)+
		
		sub.w	d0,d2		;x2-x1
		sub.w	d1,d3		;y2-y1
		move.w	d5,d6
		sub.w	d0,d6		;maxx-x1
		
		muls.w	d6,d3		;(y2-y1)*(maxx-x1)
		divs.w	d2,d3		;(y2-y1)*(maxx-x1)/(x2-x1)
		add.w	d1,d3		;y1+(y2-y1)*(maxx-x1)/(x2-x1)
		
		move.w	d5,d2
		
		move.w	d2,(a2)+
		move.w	d3,(a2)+
.clipx4:				
		
.skipclip:
		movem.w	d0-d3,(a2)
		addq	#8,a2

.skip:		
		dbra	d7,.l0
		
		move.w	#$8000,(a2)+
		rts

;--------------------------------------------------------------------

intro_dolines:
		move.l	intro_screens+$08,a5
		lea		linemodtab,a3
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		$dff000,a6
		
		move.l 	#$ffffffff,BLTAFWM(a6) 	; first and last mask
		move.w 	#$8000,BLTADAT(a6)		; starting bit
		move.w 	#$ffff,BLTBDAT(a6)		
		move.w 	#linemod,BLTCMOD(a6) 		; screen modulo

		lea		BLTCON0(a6),a6			; smallest offet into blitter registers
		lea		octanttab,a0
		lea		dstlines,a2
.l0:	
		movem.w	(a2)+,d0-d3
		cmpi.w	#$8000,d0
		beq.w	.end
		
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
		add.w	d1,d1
		add.w	(a3,d1.w),d4		;mulu #height
		lea		(a5,d4.w),a1
		
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
		
		bra.w	.l0
.end:
		rts

;--------------------------------------------------------------------
		
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

intro_fill:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6

        move.l	intro_screens+$08,a0
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
		
		cnop	0,4
intro_screens:
		dc.l	intro_screen+planemod*0
		dc.l	intro_screen+planemod*1
		dc.l	intro_screen+planemod*2
		dc.l	intro_screen+planemod*3
		
intro_page:
		lea 	intro_screens,a0
	
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		move.l	$0c(a0),d3

		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$0c(a0)
		move.l	d3,$00(a0)
		
		move.l	d2,d0
		
		lea		intro_copperbpl,a6
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)
		rts

;--------------------------------------------------------------------
		
		cnop	0,2
intro_sync:
		dc.w	0
		
intro_irq:		
		movem.l	d0-d7/a0-a6,-(sp)
		
		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)

		addq.w	#1,intro_sync
		
		move.w	#$0010,$dff09c
		movem.l	(sp)+,d0-d7/a0-a6
		rte  
		
;********************************************************************

				section "logo_copper",data,chip

logo_COPSTART	= $008eac81-logo_height/2*256
logo_COPEND		= $0090acd1+logo_height/2*256
				
logo_copperlist:	dc.l	logo_COPSTART,logo_COPEND,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

logo_copperbpl:	dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
			
logo_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01004200						;wait x: 15, y: 1, turn on 4 bitplanes

				dc.l	$210ffffe,$009c8010						;wait x: 15, y: 33, start irq
				
logo_coppercols:
				blk.l	73*4+6,$01800000
				
				dc.l	$fffffffe 								;wait for end

;--------------------------------------------------------------------
			
				cnop	0,8
logo_image:
	incbin "../data/logo/logo.ami"

;********************************************************************
				
				cnop	0,8
intro_copperlist:
				dc.l	$008e1c81,$00903cc9,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
								
intro_copperbpl:	
				dc.l	$00e00000,$00e20000						;1 bitplane pointer
								
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
				dc.l	$1c0ffffe,$01001200						;wait x: 15, y: 1, turn on 1 bitplanes

				dc.l	$800ffffe
				dc.l	$009c8010								;start irq
				
				dc.l	$fffffffe 								;wait for end

;********************************************************************

				section "intro_data",data

				cnop	0,2
intro_sintab:		
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096

intro_oxyron:
	incbin "../data/intro/oxyron.dat"

;********************************************************************
			
				section "intro_emptychip",bss,chip

				cnop	0,8
intro_screen:	ds.b	planemod*4

;********************************************************************
			
				section "intro_empty",bss
				
				cnop	0,2
dstpoints:		ds.w	maxpoints*2+1
dstlines:		ds.w	maxlines*4+1
linemodtab:		ds.w	height

				
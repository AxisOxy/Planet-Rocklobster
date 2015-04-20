width	= 368
height	= 285
minx	= 0
maxx	= width-1
miny	= 0
maxy	= height-1

linemod		= width/8
planemod	= linemod*height


	include "../framework/hardware.i"
	include "../framework/framework.i"
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

			
			section	"vectrans_code",code 
		
entrypoint:
		bra.b	vectrans_start
		bra.b	vectrans_end
		
vectrans_start:
		move.l	a6,fw_jumptable
		
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

		move.w	#waitname,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		jsr		GETFRAME(a6)
		addi.w	#numframes,d0
		move.w	d0,vectrans_endframe

		moveq	#2-1,d7
.l0:
		move.w	d7,-(sp)
		bsr.w	vectrans_doframe
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		move.w	(sp)+,d7
		dbra	d7,.l0		

		move.l	#vectrans_copperlist,a0
		move.l	#vectrans_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)

		bsr.w	vectrans_setpal
	
		;ifd _DEMO
		if dowait=0
		rts
		endc // dowait
		;endc // _DEMO
		
vectrans_end:
		move.l	fw_jumptable,a6
		move.w	vectrans_endframe(pc),d0
		jsr		WAITFORFRAME(a6)

		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)

		move.w	#endcol,$dff180
		rts		

		cnop	0,4
fw_jumptable:
		dc.l	0
vectrans_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

		cnop	0,2
pal:
		dc.w	col1,col2

vectrans_setpal:
		lea		pal,a0
		lea		$dff180,a1
		moveq	#2-1,d7
.l0:		
		move.w	(a0)+,(a1)+
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

vectrans_doframe:
		move.l	fw_jumptable,a6
		move.w	vectrans_endframe(pc),d0
		jsr		ISFRAMEOVER(a6)
		bmi.b	.skip
	
		;move.w	#$0800,$dff180
		bsr.w	vectrans_clear
		bsr.w	vectrans_transform
		bsr.w	vectrans_clip
		bsr.w	vectrans_dolines
		bsr.w	vectrans_fill
		bsr.w	vectrans_page
		;move.w	#$000,$dff180
.skip:
		rts
	
;--------------------------------------------------------------------

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
		
		cnop	0,4
vectrans_screens:
		dc.l	vectrans_screen1,vectrans_screen2
		
vectrans_page:
		lea 	vectrans_screens,a0
	
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		
		move.l	d0,$04(a0)
		move.l	d1,$00(a0)

		lea		vectrans_copperbpl,a6
		move.w	d1,$06(a6)
		swap	d1
		move.w	d1,$02(a6)
		rts

;--------------------------------------------------------------------
		
vectrans_irq:		
		movem.l	d0-d7/a0-a6,-(sp)
		
		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
	
		bsr.w	vectrans_doframe
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;********************************************************************
			
				section "vectrans_data",data

				cnop	0,2
vectrans_sintab:		
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096

;********************************************************************
			
				section "vectrans_emptychip",bss,chip

				cnop	0,8
					ds.b	400
vectrans_screen1:	ds.b	planemod
vectrans_screen2:	ds.b	planemod
					ds.b	400

;********************************************************************

				section "vectrans_copper",data,chip

vectrans_copperlist:
				dc.l	$008e1c81,$00903cc9,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
								
vectrans_copperbpl:	
				dc.l	$00e00000,$00e20000						;1 bitplane pointer
								
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
				dc.l	$1c0ffffe,$01001200						;wait x: 15, y: 1, turn on 1 bitplanes

				dc.l	$009c8010								;start irq
				
				dc.l	$fffffffe 								;wait for end

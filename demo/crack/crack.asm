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

			
			section	"crack_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable

		move.l	a6,fw_jumptable
		jsr		GETFRAME(a6)
		addi.w	#100,d0
		move.w	d0,crack_endframe

		bsr.w	crack_init
		
		moveq	#2-1,d7
.l0:
		move.w	d7,-(sp)
		bsr.w	crack_doframe
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		move.w	(sp)+,d7
		dbra	d7,.l0		

		move.w	#TIME_CRACK_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#crack_copperlist,a0
		move.l	#crack_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		bsr.w	crack_setpal
		
crack_main:
		;move.w	#$0008,$dff180
		bsr.w	crack_doframe
		;move.w	#$000,$dff180
				
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		
		btst	#$06,$bfe001
		beq.b	crack_end
		
		move.w	#TIME_CRACK_END,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	crack_main
crack_end:

		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		rts		

		cnop	0,4
fw_jumptable:
		dc.l	0
crack_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

crack_init:
		lea		crack_sintab,a0
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

		bsr.w	crack_initrnd
		bsr.w	crack_initbodies
		rts
		
;--------------------------------------------------------------------

crack_initrnd:
		lea     crack_rndtab,a0
        move.l  #12345678,d0
        move.w  #256-1,d7
.l0:    
		divu.w  #4433,d0
		move.w	d0,d1
		andi.w	#$7e,d1
		subi.w	#$40,d1
        move.w  d1,(a0)+
        dbra    d7,.l0
        rts
		
;--------------------------------------------------------------------

		cnop	0,2
pal:
		dc.w	$0000,$09a8

crack_setpal:
		lea		pal,a0
		lea		$dff180,a1
		moveq	#2-1,d7
.l0:		
		move.w	(a0)+,(a1)+
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

crack_doframe:
		move.l	fw_jumptable,a6
		move.w	crack_endframe(pc),d0
		jsr		ISFRAMEOVER(a6)
		bmi.b	.skip
	
		;move.w	#$0800,$dff180
		bsr.w	crack_fill
		bsr.w	crack_clear
		bsr.w	crack_page2
		bsr.w	crack_updatebodies
		bsr.w	crack_page1
		;move.w	#$000,$dff180
.skip:
		rts
	
;--------------------------------------------------------------------

crack_clear:
		move.l	crack_screens+4,a0
		adda.w	#height*linemod,a0

		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		move.l	d0,a1
		move.l	d0,a2
		move.l	d0,a3
		move.l	d0,a4
		move.l	d0,a5
		move.l	d0,a6
		REPT	height*linemod/14/4
		movem.l	d0-d7/a1-a6,-(a0)
		ENDR
		move.l	d0,-(a0)
		move.w	d0,-(a0)
		rts

;--------------------------------------------------------------------
		
			cnop 0,4
cracks:
			dc.l	crack1
			dc.l	crack2
			dc.l	crack3
			dc.l	crack4
			dc.l	crack5
			dc.l	crack6
			dc.l	crack7
			dc.l	crack8

crack1:
			dc.w	  0,  0
			dc.w	176,  0
			dc.w	206, 48
			dc.w	  0, 62
			dc.w	  0,  0
			dc.w	$8000

crack2:
			dc.w	176,  0
			dc.w	319,  0
			dc.w	319, 22
			dc.w	206, 48
			dc.w	176,  0
			dc.w	$8000

crack3:
			dc.w	206, 48
			dc.w	319, 22
			dc.w	319,157
			dc.w	206, 48
			dc.w	$8000

crack4:
			dc.w	206, 48
			dc.w	319,157
			dc.w	319,184
			dc.w	128,167
			dc.w	206, 48
			dc.w	$8000

crack5:
			dc.w	128,167
			dc.w	319,184
			dc.w	319,199
			dc.w	138,199
			dc.w	128,167
			dc.w	$8000

crack6:
			dc.w	128,167
			dc.w	138,199
			dc.w	 21,199
			dc.w	128,167
			dc.w	$8000

crack7:
			dc.w	  0,104
			dc.w	128,167
			dc.w	 21,199
			dc.w	  0,199
			dc.w	  0,104
			dc.w	$8000
		
crack8:
			dc.w	  0, 62
			dc.w	206, 48
			dc.w	128,167
			dc.w	  0,104
			dc.w	  0, 62
			dc.w	$8000
		
			cnop 	0,2
movex:		dc.w	0
movey:		dc.w	0
zpos:		dc.w	100
rotz:		dc.w	0

;struct for a body
BODY_X			= 0
BODY_Y			= 2
BODY_Z			= 4
BODY_RX			= 6
BODY_RY			= 8
BODY_RZ			= 10
BODY_XSPEED		= 12
BODY_YSPEED		= 14
BODY_ZSPEED		= 16
BODY_RXSPEED	= 18
BODY_RYSPEED	= 20
BODY_RZSPEED	= 22
BODY_VERTICES	= 24
BODY_SIZE		= 28

crack_initbodies:
		lea		cracks,a0
		lea		bodies,a1
		moveq	#8-1,d7
.l0:
		move.l	(a0)+,a2
		
		bsr.w	crack_initbody
		
		lea		BODY_SIZE(a1),a1
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

		cnop	0,2
crack_rndpoi:
		dc.l	crack_rndtab+36
	
crack_initbody:
		move.l	crack_rndpoi(pc),a6
		
		move.l	a2,BODY_VERTICES(a1)
		
		move.w	#500,BODY_Z(a1)
		clr.w	BODY_RX(a1)
		clr.w	BODY_RY(a1)
		clr.w	BODY_RZ(a1)
		move.w	(a6)+,d0
		asr.w	#2,d0
		move.w	d0,BODY_XSPEED(a1)
		move.w	(a6)+,d0
		asr.w	#1,d0
		move.w	d0,BODY_YSPEED(a1)
		move.w	#-3,BODY_ZSPEED(a1)
		move.w	(a6)+,BODY_RXSPEED(a1)
		move.w	(a6)+,BODY_RYSPEED(a1)
		move.w	(a6)+,BODY_RZSPEED(a1)
		
		move.l	a6,crack_rndpoi
		
		moveq	#0,d0
		moveq	#0,d1
		
		move.l	a2,a3
		
.l00:
		tst.w	(a2)
		bmi.b	.end0
		move.w	(a2),d0
		move.w	2(a2),d1

		mulu.w	#368,d0
		divu.w	#320,d0
		mulu.w	#285,d1
		divu.w	#200,d1
		
		move.w	d0,(a2)+
		move.w	d1,(a2)+
		bra.b	.l00
.end0:		

		move.l	a3,a2
		
		move.w	(a2)+,d0
		move.w	(a2)+,d1
		moveq	#1,d4		

		move.w	d0,d2
		move.w	d1,d3
.l0:
		move.w	(a2)+,d5
		move.w	(a2)+,d6
		
		cmp.w	d5,d2
		bne.b	.do
		cmp.w	d6,d3
		beq.b	.end1
.do:
		add.w	d5,d0
		add.w	d6,d1
		
		addq	#1,d4
		bra.b	.l0
.end1:		
		ext.l	d0
		ext.l	d1
		divu.w	d4,d0
		divu.w	d4,d1
		
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#2,d2
		lsl.w	#2,d3
		move.w	d2,BODY_X(a1)
		move.w	d3,BODY_Y(a1)
		subi.w	#368*4/2,d2
		muls.w	#8,d2
		asr.l	#8,d2
		move.w	d2,BODY_XSPEED(a1)
		subi.w	#285*4/2+450,d3
		muls.w	#8,d3
		asr.l	#8,d3
		move.w	d3,BODY_YSPEED(a1)
		
.l1:		
		tst.w	(a3)
		bmi.b	.end2
		move.w	(a3),d2
		move.w	2(a3),d3
		sub.w	d0,d2
		sub.w	d1,d3
		lsl.w	#2,d2
		lsl.w	#2,d3
		move.w	d2,(a3)+
		move.w	d3,(a3)+
		bra.b	.l1
.end2:		
		rts

;--------------------------------------------------------------------

		cnop	0,2
crack_frame:	
		dc.w	0

crack_updatebodies:
		addq.w	#1,crack_frame

		lea		bodies,a6
		moveq	#8-1,d7
.l0:
		move.w	d7,-(sp)
		move.l	a6,-(sp)
		
		bsr.w	crack_updatebody
	
		move.l	(sp)+,a6
		move.w	(sp)+,d7
		
		lea		BODY_SIZE(a6),a6
	
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------
	
crack_updatebody:
		cmpi.w	#3,crack_frame
		blt.b	.skip
		bsr.w	crack_step
.skip:
		bsr.w	crack_transform
		bsr.w	crack_clip
		bra.w	crack_dolines
		
;--------------------------------------------------------------------
	
GRAVITY	=	1

crack_step:	
		addq.w	#GRAVITY,BODY_YSPEED(a6)

		move.w	BODY_XSPEED(a6),d0
		add.w	d0,BODY_X(a6)
	
		move.w	BODY_YSPEED(a6),d0
		add.w	d0,BODY_Y(a6)
		
		move.w	BODY_ZSPEED(a6),d0
		add.w	d0,BODY_Z(a6)

		move.w	BODY_RX(a6),d0
		add.w	BODY_RXSPEED(a6),d0
		andi.w	#$ffe,d0
		move.w	d0,BODY_RX(a6)
				
		move.w	BODY_RY(a6),d1
		add.w	BODY_RYSPEED(a6),d1
		andi.w	#$ffe,d1
		move.w	d1,BODY_RY(a6)
		
		move.w	BODY_RZ(a6),d2
		add.w	BODY_RZSPEED(a6),d2
		andi.w	#$ffe,d2
		move.w	d2,BODY_RZ(a6)
		rts

;--------------------------------------------------------------------
	
crack_transform:
		move.w	BODY_RX(a6),d0
		move.w	BODY_RY(a6),d1
		move.w	BODY_RZ(a6),d2
		
		lea		crack_sintab,a0
		lea		$400(a0),a1
		lea		tmps,a2
		lea		mat,a3
		move.w	(a0,d0.w),d3	;sx
		move.w	(a1,d0.w),d0	;cx
		move.w	(a0,d1.w),d4	;sy
		move.w	(a1,d1.w),d1	;cy
		move.w	(a0,d2.w),d5	;sz
		move.w	(a1,d2.w),d2	;cz
		
		move.w	d4,d6
		muls.w	d3,d6
		lsl.l	#2,d6
		swap	d6
		move.w	d6,0(a2)		;sx*sy
		
		move.w	d0,d6
		muls.w	d5,d6			
		lsl.l	#2,d6
		swap	d6
		move.w	d6,2(a2)		;cx*sz
		
		move.w	d0,d6
		muls.w	d2,d6			
		lsl.l	#2,d6
		swap	d6
		move.w	d6,4(a2)		;cx*cz
		
		move.w	d1,d6
		muls.w	d2,d6			
		lsl.l	#2,d6
		swap	d6
		move.w	d6,0(a3)		;cy*cz

		move.w	d1,d6
		muls.w	d5,d6			
		lsl.l	#2,d6
		swap	d6
		move.w	d6,2(a3)		;cy*sz
		
		move.w	d4,d6
		move.w	d6,4(a3)		;sy

		move.w	0(a2),d6
		muls.w	d2,d6	
		lsl.l	#2,d6
		swap	d6
		neg.w	d6
		sub.w	2(a2),d6
		move.w	d6,6(a3)		;-a*cz-b
		
		move.w	0(a2),d6
		muls.w	d5,d6					
		lsl.l	#2,d6
		swap	d6
		neg.w	d6
		add.w	4(a2),d6
		move.w	d6,8(a3)		;-a*sz+c
		
		move.w	d3,d6
		muls.w	d1,d6			
		lsl.l	#2,d6
		swap	d6
		move.w	d6,10(a3)		;sx*cy
		
		move.w	4(a2),d6
		muls.w	d4,d6		
		lsl.l	#2,d6
		move.w	d3,d7
		muls.w	d5,d7			
		lsl.l	#2,d7
		sub.l	d7,d6
		swap	d6
		move.w	d6,12(a3)		;c*sy-sx*sz
		
		move.w	2(a2),d6
		muls.w	d4,d6			
		lsl.l	#2,d6
		move.w	d3,d7
		muls.w	d2,d7			
		lsl.l	#2,d7
		add.l	d7,d6
		swap	d6
		move.w	d6,14(a3)		;b*sy+sx*cz
		
		move.w	d0,d6
		muls.w	d1,d6			
		lsl.l	#2,d6
		swap	d6
		neg.w	d6
		move.w	d6,16(a3)		;-cx*cy
	
		lea		dstpoints1,a1		
	
		move.l	BODY_VERTICES(a6),a0
.l0:
		move.w	(a0)+,d0
		cmpi.w	#$8000,d0
		beq.b	.end
		
		move.w	(a0)+,d3
		move.w	d0,d1
		move.w	d0,d2
		move.w	d3,d4
		move.w	d3,d5
		
		muls.w	(a3)+,d0
		muls.w	(a3)+,d1
		muls.w	(a3)+,d2
		muls.w	(a3)+,d3
		muls.w	(a3)+,d4
		muls.w	(a3)+,d5
		lea		-12(a3),a3
		
		add.l	d3,d0
		add.l	d4,d1
		add.l	d5,d2
		lsl.l	#4,d0
		lsl.l	#4,d1
		swap	d0
		swap	d1
		swap	d2
		
		add.w	BODY_Z(a6),d2
		move.l	#125*65536,d3
		divu.w	d2,d3
		muls.w	d3,d0
		muls.w	d3,d1
		swap	d0
		swap	d1
		add.w	BODY_X(a6),d0
		add.w	BODY_Y(a6),d1
		asr.w	#2,d0
		asr.w	#2,d1
		
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		
		bra.b	.l0
.end:
		move.w	#$8000,(a1)+
		rts
		
;--------------------------------------------------------------------

crack_clip:
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

crack_dolines:
		move.l	crack_screens+4,a5
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		$dff000,a6
		
		move.l 	#$ffffffff,BLTAFWM(a6) 	; first and last mask
		move.w 	#$8000,BLTADAT(a6)		; starting bit
		move.w 	#$ffff,BLTBDAT(a6)		
		move.w 	#linemod,BLTCMOD(a6) 		; screen modulo

		lea		BLTCON0(a6),a6			; smallest offet into blitter registers
		lea		octanttab,a0
		lea		dstpoints5,a2
.l0:
		movem.w	(a2),d0-d3
		tst.w	d2
		bmi.b	.end
		addq	#4,a2
		bsr.w	crack_doline
		
		bra.b	.l0
.end:
		rts

;--------------------------------------------------------------------

crack_doline:
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

crack_fill:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6

        move.l	crack_screens+8,a0
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
crack_screens:
		dc.l	crack_screen1,crack_screen2,crack_screen3
		
crack_page1:
		lea 	crack_screens,a0
	
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)
		rts

;--------------------------------------------------------------------

crack_page2:
		move.l	crack_screens+8,d1
		
		lea		crack_copperbpl,a6
		move.w	d1,$06(a6)
		swap	d1
		move.w	d1,$02(a6)
		rts

;--------------------------------------------------------------------
		
crack_irq:		
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
			
				section "crack_data",data

				cnop	0,2
crack_sintab:		
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096

;********************************************************************
			
				section "crack_emptychip",bss,chip

				cnop	0,8
crack_screen1:	ds.b	planemod
crack_screen2:	ds.b	planemod
crack_screen3:	ds.b	planemod
				
				cnop	0,2
tmps:			ds.w	3
mat:			ds.w 	9
				
crack_rndtab:	ds.w	256
dstpoints1:		ds.w	10*2+1
dstpoints2:		ds.w	10*2+1
dstpoints3:		ds.w	10*2+1
dstpoints4:		ds.w	10*2+1
dstpoints5:		ds.w	10*2+1

bodies:			ds.b	BODY_SIZE*8

;********************************************************************

				section "crack_copper",data,chip

crack_copperlist:
				dc.l	$008e1c81,$00903cc9,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
								
crack_copperbpl:	
				dc.l	$00e00000,$00e20000						;1 bitplane pointer
								
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
				dc.l	$1c0ffffe,$01001200						;wait x: 15, y: 1, turn on 1 bitplanes

				dc.l	$009c8010								;start irq
				
				dc.l	$fffffffe 								;wait for end

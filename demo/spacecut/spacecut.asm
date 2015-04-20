	include "../framework/hardware.i"
	include "../framework/framework.i"
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
			
			section	"cut_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable
			
		lea		cut_screens,a0
		move.l	#cut_screenbuf,d0
		move.l	d0,(a0)+
		addi.l	#cut_COLMOD*4,d0
		move.l	d0,(a0)+
		addi.l	#cut_COLMOD*4,d0
		move.l	d0,(a0)+
		move.l	d0,cut_fillregsl+12
		addi.l	#cut_COLMOD*4,d0
		move.l	d0,(a0)+
			
		lea		cut_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
	
		jsr		cut_page
		bsr.w	cut_clear
		jsr		cut_page
		bsr.w	cut_clear
		jsr		cut_page
		
		bsr.w	cut_setpal

		move.w	#TIME_SPACECUTFADE_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#cut_copperlist,a0
		move.l	#cut_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)

		bsr.w	cut_fadeinlogo

		bsr.w	cut_init
		
		move.w	#1,running
	
		move.w	#TIME_SPACECUT_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#820,d0
		move.w	d0,cut_endframe1
		addi.w	#700,d0
		move.w	d0,cut_endframe2
				
		;bra.b	skipfirst
		
cut_main1:
		cmpi.w	#$337,stepframe
		bge.b	.skip
		bsr.w	cut_update1
.skip:
		
		btst	#$06,$bfe001
		beq.b	cut_end
		
		move.w	cut_endframe1,d0
		move.l	fw_jumptable(pc),a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	cut_main1
	
skipfirst:		
		bsr.w	cut_fadeoutlogo
	
cut_end:
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		rts	
		
		cnop	0,4
fw_jumptable:
		dc.l	0
cut_endframe1:
		dc.w	0
cut_endframe2:
		dc.w	0
		
;--------------------------------------------------------------------
		
cut_fadeinlogo:
			moveq	#0,d0
.l0:
			lea		cut_logo+10,a0
			move.w	#$fff,d4
			bsr.w	cut_dofadelogo
			
			move.l	fw_jumptable(pc),a6
			jsr		VSYNC(a6)
	
			addq	#1,d0
			cmpi.w	#16,d0
			bne.b	.l0
			rts
			
;--------------------------------------------------------------------

cut_fadeoutlogo:
			moveq	#15,d0
.l0:
			lea		cut_logo+10,a0
			move.w	(a0),d4
			bsr.w	cut_dofadelogo
			
			move.l	fw_jumptable(pc),a6
			jsr		VSYNC(a6)
	
			dbra	d0,.l0
			rts
			
;--------------------------------------------------------------------

cut_dofadelogo:
			lea		$dff180,a1
		
			move.w	d4,d5
			move.w	d5,d6
			andi.w	#$f00,d4
			andi.w	#$0f0,d5
			andi.w	#$00f,d6
		
			moveq	#8-1,d7
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

cut_init:
		lea		cut_exptab2comp,a0
		lea		cut_exptab,a1
		lea		cut_exptab2compend-2,a6
		moveq	#0,d5
		moveq	#2,d4
		bsr.w	convtab

		lea		cut_exptabcomp,a0
		lea		cut_exptab2,a1
		lea		cut_exptabcompend-2,a6
		move.w	#$fffe,d5
		moveq	#-2,d4
		bsr.w	convtab

		lea		cut_logtabcomp,a0
		lea		cut_logtab,a1
		lea		cut_logtabcompend-2,a6
		moveq	#0,d5
		moveq	#2,d4
		bsr.w	convtab

		; multiply all math tables with 2 to get valid word-offsets
		lea		cut_logtab-$8000,a0
		lea		cut_exptab2-$8000,a2
		move.w	#$7fff,d7
.l21:
		move.w	(a0),d0
		add.w	d0,d0
		move.w	d0,(a0)+

		move.w	(a2),d0
		addi.w	#128-32,d0
		move.w	d0,(a2)+

		dbra	d7,.l21	

		lea		cut_squaretab9,a0
		lea		cut_squaretab9,a1
		moveq	#0,d0
		move.w	#$1ff,d7
.l5:	
		move.w	d0,d2
		add.w	d2,d2
		addi.w	#$fc00,d2
		
		move.w	d0,d1
		mulu.w	d0,d1
		lsr.l	#2,d1
		move.w	d1,(a1)+
		
		move.w	#$200,d3
		sub.w	d0,d3
		move.w	d3,d4
		mulu.w	d3,d4
		lsr.l	#2,d4		
		move.w	d4,(a0,d2.w)
		
		addq	#1,d0
		dbra	d7,.l5
		
		lea		cut_sintab,a0
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
		bsr.w	cut_initfilltab
		rts
		
;--------------------------------------------------------------------

convtab:	
.l0:		
		move.w	(a0)+,d0	;x1
		move.w	(a0)+,d1	;y1
		move.l	(a0)+,d3	;ystep
		move.w	(a0),d2		;x2
		subq	#1,d2
		
		sub.w	d0,d2		;dx=x2-x1
		swap	d1
		move.w	#$8000,d1
.l1:
		move.l	d1,d0
		swap	d0
		
		move.w	d0,(a1,d5.w)
		add.w	d4,d5

		add.l	d3,d1
		dbra	d2,.l1		
	
		cmp.l	a0,a6
		bne.b	.l0
.end:
		rts

;--------------------------------------------------------------------

cut_setpal:
		lea		cut_logo+10,a0
		
		lea		$dff180,a1
		moveq	#8-1,d7
.l0:
		move.w	(a0),(a1)+
		dbra	d7,.l0
		
		lea		cut_pal,a0
		moveq	#8-1,d7
.l1:
		move.w	(a0)+,(a1)+
		dbra	d7,.l1
		rts

;--------------------------------------------------------------------

		cnop	0,2
cut_filltabsrcleft:
		dc.w	$ffff,$7fff,$3fff,$1fff,$0fff,$07ff,$03ff,$01ff
		dc.w	$00ff,$007f,$003f,$001f,$000f,$0007,$0003,$0001
		
cut_filltabsrcright:
		dc.w	$0000,$8000,$c000,$e000,$f000,$f800,$fc00,$fe00
		dc.w	$ff00,$ff80,$ffc0,$ffe0,$fff0,$fff8,$fffc,$fffe

cut_initfilltab:
		lea		cut_filltabsrcleft,a0
		lea		cut_filltabsrcright,a1
		lea		leftrightmasks,a2
		moveq	#0,d7
		moveq	#0,d1
.l1:
		moveq	#0,d0
.l0:		
		move.w	d0,d2
		move.w	d1,d3
		andi.w	#$0f,d2
		andi.w	#$0f,d3
		add.w	d2,d2
		add.w	d3,d3
		move.w	(a0,d2.w),d2
		move.w	(a1,d3.w),d3
		
		move.w	d3,0(a2,d7.w)
		move.w	d2,2(a2,d7.w)
		addq	#4,d7
		
		addq	#1,d0
		cmpi.w	#256,d0
		bne.b	.l0
		
		addq	#1,d1
		cmpi.w	#64,d1
		bne.b	.l1		
		
		lea		jmpoffsets,a2
		lea		filloffsets,a3
		
		moveq	#0,d7
		moveq	#0,d1
.l3:
		moveq	#0,d0
.l2:		
		move.w	d0,d4
		move.w	d1,d5
		lsr.w	#3,d4
		lsr.w	#4,d5
		andi.w	#$0f,d4
		andi.w	#$0f,d5
			
		lsl.w	#4,d5
		or.w	d4,d5
		add.w	d5,d5
		
		move.w	(a3,d5.w),(a2,d7.w)
		addq	#2,d7
	
		addq	#1,d0
		cmpi.w	#128,d0
		bne.b	.l2
		
		addq	#1,d1
		cmpi.w	#256,d1
		bne.b	.l3		
		rts
		
;--------------------------------------------------------------------

cut_update1:
		;move.w	#$800,$dff180

		bsr.w	cut_clear
		
		bsr.w	cut_rotate1
		bsr.w	cut_cull1
		bsr.w	cut_createplanes
		bsr.w	cut_buildpolys1
		
		bsr.w	cut_rotate2
		bsr.w	cut_cull2
		bsr.w	cut_buildpolys2

		bsr.w	cut_clippolys
		bsr.w	cut_drawpolyssplit
		
		;move.w	#$000,$dff180

		bsr.w	cut_vsync
		bsr.w	cut_shade		

		jsr		cut_page
		rts
		
;--------------------------------------------------------------------
		
cut_vsync:
.wait:
		cmpi.w	#2,cut_sync
		blt.b	.wait
		clr.w	cut_sync
		rts
		
;--------------------------------------------------------------------

cut_clear:
		move.l	cut_screens+4,a1

		bsr.w	cut_bltwait

		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		clr.w	BLTADAT(a6)
		move.w	#60,BLTDMOD(a6)
		move.l  a1,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #$c002,BLTSIZE(a6)
				
		adda.w	#44,a1
		
		bsr.w	cut_bltwait

		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		clr.w	BLTADAT(a6)
		move.w	#62,BLTDMOD(a6)
		move.l  a1,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #$c001,BLTSIZE(a6)
				
		lea		cut_logo+10+16,a0
		suba.w	#40,a1
		
		bsr.w	cut_bltwait

		lea		BLTBASE,a6
		clr.w	BLTAMOD(a6)
		move.w	#24,BLTDMOD(a6)
		move.l	a0,BLTAPTR(a6)
		move.l  a1,BLTDPTR(a6)
        move.l	#$09f00000,BLTCON0(a6)
		move.w  #$c014,BLTSIZE(a6)
		;bsr.w	bltwait
		rts
		
;--------------------------------------------------------------------

cut_bltwait:
		;move.w	#$fff,$dff180
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		;clr.w	$dff180
		rts
		
;--------------------------------------------------------------------

 MACRO<CUT_ROTPOINT>
		movem.w	$00+\1(a4),d0-d2
		
		lea		$06+\2(a4),a6
		add.w	(a6)+,d0
		add.w	(a6)+,d1
		add.w	(a6),d2
		
		lea		$0c+\3(a4),a6
		add.w	(a6)+,d0
		add.w	(a6)+,d1
		add.w	(a6),d2

		add.w	d5,d0
		add.w	d6,d1
		add.w	d7,d2
				
		movem.w	d0-d2,\4(a0)
		subi.w	#ZGUARD,d2

		asr.w	#3,d2
		add.w	d2,d2
		
		move.w	(a3,d2.w),d2		; d2=-log(z)
		move.w	d2,d4				; d4=-log(z)
		
		sub.w	(a2,d0.w),d2		; d2+=log(x)
		sub.w	(a2,d1.w),d4		; d4+=log(y)
		
		move.w	(a5,d2.w),d2		
		add.w	d3,d2
		move.w	d2,\4(a1)			
		move.w	(a5,d4.w),\4+2(a1)	; y=exp(log(y)-log(z))	
 ENDM

;--------------------------------------------------------------------
 
stepy		= 24
stepz		= 28
scalestep	=  9
stepdiff	= $50
 
		cnop	0,2
stepx:	dc.w	 2
steprx:	dc.w	12 
stepry:	dc.w	14
steprz:	dc.w	10 
rx1:	dc.w 	16/2+2
ry1:	dc.w 	16/2+2
rz1:	dc.w 	16/2+2
mxpos1:	dc.w	$500
mypos1:	dc.w	$000
mzpos1:	dc.w	$000

rx2:	dc.w 	44*stepdiff+16/2
ry2:	dc.w 	44*stepdiff+16/2
rz2:	dc.w 	14*stepdiff+16/2
mxpos2:	dc.w	$cd8
mypos2:	dc.w	$800
mzpos2:	dc.w	$800
scale:	dc.w	$400*4
xoffsetnopersp:
		dc.w	32+34
xoffset2:
		dc.w	32+15+99
movescale:
		dc.w	600

frame:	dc.w	0
movex:	dc.w	0
movey:	dc.w	0
movez:	dc.w	0
tmps:	ds.w	3
mat:	ds.w 	9
lerp:	ds.w	4*9

off1		= 0*18
off2		= 1*18
off3		= 2*18
numplots	= 8
tf			= 1000*2

numpolys	= 6
pointstride	= 8		
polystride	= 2
colstride	= 4
		
polys:
		dc.w	($00+1)*pointstride, ($00+2)*pointstride, ($00+3)*pointstride, ($00+0)*pointstride
		dc.w	($00+5)*pointstride, ($00+6)*pointstride, ($00+2)*pointstride, ($00+1)*pointstride
		dc.w	($00+4)*pointstride, ($00+7)*pointstride, ($00+6)*pointstride, ($00+5)*pointstride
		dc.w	($00+0)*pointstride, ($00+3)*pointstride, ($00+7)*pointstride, ($00+4)*pointstride
		dc.w	($00+5)*pointstride, ($00+1)*pointstride, ($00+0)*pointstride, ($00+4)*pointstride
		dc.w	($00+2)*pointstride, ($00+6)*pointstride, ($00+7)*pointstride, ($00+3)*pointstride		
		dc.w	-1
polysrev:
		dc.w	($00+0)*pointstride, ($00+3)*pointstride, ($00+2)*pointstride, ($00+1)*pointstride
		dc.w	($00+1)*pointstride, ($00+2)*pointstride, ($00+6)*pointstride, ($00+5)*pointstride
		dc.w	($00+5)*pointstride, ($00+6)*pointstride, ($00+7)*pointstride, ($00+4)*pointstride
		dc.w	($00+4)*pointstride, ($00+7)*pointstride, ($00+3)*pointstride, ($00+0)*pointstride
		dc.w	($00+4)*pointstride, ($00+0)*pointstride, ($00+1)*pointstride, ($00+5)*pointstride
		dc.w	($00+3)*pointstride, ($00+7)*pointstride, ($00+6)*pointstride, ($00+2)*pointstride		
		dc.w	-1
	
polycols1:
		dc.w	0*colstride,1*colstride,0*colstride,1*colstride,2*colstride,2*colstride
polycols2:
		dc.w	3*colstride,4*colstride,3*colstride,4*colstride,5*colstride,5*colstride
		
domove:
		dc.w	1
scalexy:
		dc.w	8
scalez:
		dc.w	8
running:
		dc.w	0
stepframe:
		dc.w	0
		
cut_step:
		tst.w	running
		beq.w	.skip
		
		addq.w	#1,stepframe
		
		move.w	rx1(pc),d0
		add.w	steprx(pc),d0
		andi.w	#$ffe,d0
		move.w	d0,rx1

		move.w	ry1(pc),d1
		add.w	stepry(pc),d1
		andi.w	#$ffe,d1
		move.w	d1,ry1
		
		move.w	rz1(pc),d2
		add.w	steprz(pc),d2
		andi.w	#$ffe,d2
		move.w	d2,rz1

		move.w	mxpos1(pc),d0
		add.w	stepx(pc),d0
		andi.w	#$ffe,d0
		move.w	d0,mxpos1

		move.w	mypos1(pc),d1
		addi.w	#stepy,d1
		andi.w	#$ffe,d1
		move.w	d1,mypos1
		
		move.w	mzpos1(pc),d2
		addi.w	#stepz,d2
		andi.w	#$ffe,d2
		move.w	d2,mzpos1
		
		move.w	rx2(pc),d0
		add.w	steprx(pc),d0
		andi.w	#$ffe,d0
		move.w	d0,rx2

		move.w	ry2(pc),d1
		add.w	stepry(pc),d1
		andi.w	#$ffe,d1
		move.w	d1,ry2
		
		move.w	rz2(pc),d2
		add.w	steprz(pc),d2
		andi.w	#$ffe,d2
		move.w	d2,rz2

		move.w	mxpos2(pc),d0
		add.w	stepx(pc),d0
		andi.w	#$ffe,d0
		move.w	d0,mxpos2

		move.w	mypos2(pc),d1
		addi.w	#stepy,d1
		andi.w	#$ffe,d1
		move.w	d1,mypos2
		
		move.w	mzpos2(pc),d2
		addi.w	#stepz,d2
		andi.w	#$ffe,d2
		move.w	d2,mzpos2
		
		move.w	scale(pc),d0
		addi.w	#scalestep,d0
		move.w	d0,scale
.skip:
		rts

;--------------------------------------------------------------------

cut_rotate1:
		move.w	rx1(pc),d0
		move.w	ry1(pc),d1
		move.w	rz1(pc),d2

		move.w	mxpos1(pc),d3
		move.w	mypos1(pc),d4
		move.w	mzpos1(pc),d5
		bra.b	cut_rotate
		
;--------------------------------------------------------------------

cut_rotate2:
		move.w	rx2(pc),d0
		move.w	ry2(pc),d1
		move.w	rz2(pc),d2
	
		move.w	mxpos2(pc),d3
		move.w	mypos2(pc),d4
		move.w	mzpos2(pc),d5
		;bra.b	cut_rotate

;--------------------------------------------------------------------

cut_rotate:
		lea		cut_sintab,a0
		
		tst.w	domove
		beq.b	.skipmove
		
		move.w	scale(pc),d6
		lsr.w	#2,d6
		andi.w	#$ffe,d6
		move.w	(a0,d6.w),d6
		move.w	d6,d7
		muls.w	#138*128,d6
		lsl.l	#2,d6
		swap	d6
		muls.w	#20*128,d7
		lsl.l	#2,d7
		swap	d7
				
		move.w	(a0,d3.w),d3
		move.w	(a0,d4.w),d4
		muls.w	d6,d3
		muls.w	d7,d4
		;move.w	(a0,d5.w),d5
		;muls.w	#0*128,d5
		moveq	#0,d5
		lsl.l	#2,d3
		lsl.l	#2,d4
		swap	d3
		swap	d4
		swap	d5
		addi.w	#$500,d3
		addi.w	#$180,d4
		andi.w	#$fffe,d3
		andi.w	#$fffe,d4
		andi.w	#$fffe,d5
		bra.b	.noskipmove
		
.skipmove:
		move.w	mxpos1(pc),d3
		andi.w	#$ffe,d3
		move.w	(a0,d3.w),d3
		muls.w	movescale(pc),d3
		swap	d3
		add.w	xoffset2(pc),d3
		move.w	d3,xoffsetnopersp

		moveq	#0,d3
		moveq	#0,d4
		move.w	#-2000,d5
		
.noskipmove:
		move.w	d3,movex
		move.w	d4,movey
		move.w	d5,movez
		
		lea		cut_sintab+$400,a1
		lea		tmps(pc),a2
		lea		mat(pc),a3
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
		add.l	d6,d6
		swap	d6
		move.w	d6,0(a3)		;cy*cz

		move.w	d1,d6
		muls.w	d5,d6			
		add.l	d6,d6
		swap	d6
		move.w	d6,2(a3)		;cy*sz
	
		move.w	d4,d6
		asr.w	#1,d6
		move.w	d6,4(a3)		;sy
		
		move.w	0(a2),d6
		muls.w	d2,d6			
		lsl.l	#2,d6
		swap	d6
		neg.w	d6
		sub.w	2(a2),d6
		asr.w	#1,d6
		move.w	d6,6(a3)		;-a*cz-b
		
		move.w	0(a2),d6
		muls.w	d5,d6			
		lsl.l	#2,d6
		swap	d6
		neg.w	d6
		add.w	4(a2),d6
		asr.w	#1,d6
		move.w	d6,8(a3)		;-a*sz+c
		
		move.w	d3,d6
		muls.w	d1,d6			
		swap	d6
		add.w	d6,d6
		move.w	d6,10(a3)		;sx*cy
		
		move.w	4(a2),d6
		muls.w	d4,d6			
		move.w	d3,d7
		muls.w	d5,d7			
		sub.l	d7,d6
		add.l	d6,d6
		swap	d6
		move.w	d6,12(a3)		;c*sy-sx*sz
		
		move.w	2(a2),d6
		muls.w	d4,d6			
		move.w	d3,d7
		muls.w	d2,d7			
		add.l	d7,d6
		add.l	d6,d6
		swap	d6
		move.w	d6,14(a3)		;b*sy+sx*cz
	
		move.w	d0,d6
		muls.w	d1,d6			
		swap	d6
		neg.w	d6
		add.w	d6,d6
		move.w	d6,16(a3)		;-cx*cy

		move.w	0(a3),d0
		muls.w	scalexy(pc),d0
		asr.l	#3,d0
		move.w	d0,0(a3)

		move.w	2(a3),d0
		muls.w	scalexy(pc),d0
		asr.l	#3,d0
		move.w	d0,2(a3)

		move.w	4(a3),d0
		muls.w	scalexy(pc),d0
		asr.l	#3,d0
		move.w	d0,4(a3)	
		
		move.w	6(a3),d0
		muls.w	scalexy(pc),d0
		asr.l	#3,d0
		move.w	d0,6(a3)

		move.w	8(a3),d0
		muls.w	scalexy(pc),d0
		asr.l	#3,d0
		move.w	d0,8(a3)

		move.w	10(a3),d0
		muls.w	scalexy(pc),d0
		asr.l	#3,d0
		move.w	d0,10(a3)		
		
		move.w	12(a3),d0
		muls.w	scalez(pc),d0
		asr.l	#3,d0
		move.w	d0,12(a3)

		move.w	14(a3),d0
		muls.w	scalez(pc),d0
		asr.l	#3,d0
		move.w	d0,14(a3)

		move.w	16(a3),d0
		muls.w	scalez(pc),d0
		asr.l	#3,d0
		move.w	d0,16(a3)
		
		lea		lerp+0,a4
		lea		lerp+18,a5
		
		moveq	#9-1,d7
.l00:
		move.w	(a3)+,d0
		asr.w	#3,d0
		
		add.w	d0,d0
		move.w	d0,(a4)+
		neg.w	d0
		move.w	d0,(a5)+

		dbra	d7,.l00
				
		lea		plotsdst,a0
		lea		plotsdstproj,a1
		lea		cut_logtab,a2
		lea		tf*2(a2),a3
		lea		lerp,a4
		lea		cut_exptab2,a5

		move.w	movex(pc),d5
		move.w	movey(pc),d6
		move.w	movez(pc),d7
		addi.w	#ZGUARD,d7
	
		move.w	xoffsetnopersp(pc),d3
		
		CUT_ROTPOINT off1,off1,off1, 0*8
		CUT_ROTPOINT off2,off1,off1, 1*8
		CUT_ROTPOINT off2,off2,off1, 2*8
		CUT_ROTPOINT off1,off2,off1, 3*8
		CUT_ROTPOINT off1,off1,off2, 4*8
		CUT_ROTPOINT off2,off1,off2, 5*8
		CUT_ROTPOINT off2,off2,off2, 6*8
		CUT_ROTPOINT off1,off2,off2, 7*8
		rts
		
;--------------------------------------------------------------------
	
 MACRO<CUT_CULL>
		movem.w	\1(a1),d3/d4	;x1/y1
		movem.w	\2(a1),d1/d5 	;x2/y2
		movem.w	\3(a1),d0/d2	;x3/y3
		
		sub.w	d3,d1			;x2-x1
		sub.w	d4,d2			;y3-y1
		sub.w	d4,d5			;y2-y1
		sub.w	d3,d0			;x3-x1
		
.slow\@:
		add.w	d1,d1
		add.w	d0,d0
		add.w	d2,d2
		add.w	d5,d5

		move.w	d1,d4
		add.w	d2,d4
		sub.w	d2,d1
		
		move.w	(a4,d4.w),d4
		sub.w	(a4,d1.w),d4
		
		move.w	d0,d1
		add.w	d5,d1
		sub.w	d5,d0
		
		sub.w	(a4,d1.w),d4
		add.w	(a4,d0.w),d4
		bmi.b	.invisible\@
		
		move.w	(a2),(a3)+
		move.w	(a2)+,(a5)+
		move.w	d4,(a5)+
		bra.b	.end\@
	
.invisible\@:
		move.w	d6,(a3)+
		addq	#2,a2
.end\@:

 ENDM
		
		cnop	0,4
cut_shadeinfopoi:
		dc.l	0
		
cut_cull1:
		lea		cut_shadeinfo,a5
		lea		polycols1,a2
		bsr.b	cut_cull
		moveq	#-1,d0
		move.w	d0,(a5)+
		move.l	a5,cut_shadeinfopoi
		rts
		
;--------------------------------------------------------------------

cut_cull2:
		move.l	cut_shadeinfopoi(pc),a5
		lea		polycols2,a2
		bsr.b	cut_cull
		moveq	#-1,d0
		move.w	d0,(a5)+
		rts
		
;--------------------------------------------------------------------
		
cut_cull:
		lea		plotsdstproj,a1
		lea		polycolsdst,a3
		lea		cut_squaretab9,a4
		moveq	#-1,d6
		
		CUT_CULL ($00+1)*pointstride,($00+2)*pointstride,($00+3)*pointstride
		CUT_CULL ($00+5)*pointstride,($00+6)*pointstride,($00+2)*pointstride
		CUT_CULL ($00+4)*pointstride,($00+7)*pointstride,($00+6)*pointstride
		CUT_CULL ($00+0)*pointstride,($00+3)*pointstride,($00+7)*pointstride
		CUT_CULL ($00+5)*pointstride,($00+1)*pointstride,($00+0)*pointstride
		CUT_CULL ($00+2)*pointstride,($00+6)*pointstride,($00+7)*pointstride
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
cut_shadetab1:
		dc.w	$0112,$0223,$0224,$0335,$0446,$0547
		dc.w	$0658,$0769,$076a,$087b,$098c,$098d,$0a9e,$0baf
	;	dc.w	$0cbf,$0dcf,$0edf,$0fef
	;	blk.w	16,$fff
		blk.w	16,$baf
		
cut_shadetab2:
		dc.w	$0211,$0322,$0422,$0533,$0644,$0754
		dc.w	$0865,$0976,$0a76,$0b87,$0c98,$0d98,$0ea9,$0fba
	;	dc.w	$0fcb,$0fdc,$0fed,$0ffe
	;	blk.w	16,$fff
		blk.w	16,$fba
		
cut_shade:
		lea		cut_shadeinfo,a0
		lea		$dff192,a3
		
		lea		cut_shadetab1,a2
		bsr.b	.do
		lea		cut_shadetab2,a2
		bsr.b	.do
		rts
.do:
.l0:
		move.w	(a0)+,d0
		bmi.b	.end
		lsr.w	#1,d0
		move.w	(a0)+,d1
		asr.w	#8,d1
		add.w	d1,d1
		move.w	(a2,d1.w),(a3,d0.w)
		
		bra.b	.l0
.end:	
		rts
		
;--------------------------------------------------------------------

 MACRO<CUT_CREATEPLANE>
		move.w	(a5)+,d0
		bmi.b	.skip\@
		movem.w	$00+\1(a4),d0-d2
		
		lea		$06+\2(a4),a6
		add.w	(a6)+,d0
		add.w	(a6)+,d1
		add.w	(a6),d2

		lea		$0c+\3(a4),a6
		add.w	(a6)+,d0
		add.w	(a6)+,d1
		add.w	(a6),d2
		
		move.w	d0,(a0)+
		move.w	d1,(a0)+
		move.w	d2,(a0)+
		
		move.w	d0,d3
		move.w	d1,d4
		move.w	d2,d5
		
		muls.w	\4+0(a1),d3
		muls.w	\4+2(a1),d4
		muls.w	\4+4(a1),d5
		add.l	d4,d3
		add.l	d5,d3
		neg.l	d3
		swap	d3
		move.w	d3,(a0)+
		
		addq.w	#1,numplanes
.skip\@:
 ENDM
 
;--------------------------------------------------------------------

		cnop	0,2
numplanes:
		dc.w	0

cut_createplanes:
		clr.w	numplanes

		lea		planes,a0
		lea		plotsdst,a1
		lea		lerp,a4
		lea		polycolsdst,a5
	
		CUT_CREATEPLANE off3,off3,off1,1*pointstride
		CUT_CREATEPLANE off2,off3,off3,5*pointstride
		CUT_CREATEPLANE off3,off3,off2,4*pointstride
		CUT_CREATEPLANE off1,off3,off3,0*pointstride
		CUT_CREATEPLANE off3,off1,off3,5*pointstride
		CUT_CREATEPLANE off3,off2,off3,2*pointstride
		
		moveq	#0,d0
		move.w	d0,(a0)+
		move.w	d0,(a0)+
		move.w	d0,(a0)+
		rts
		
;--------------------------------------------------------------------

cut_tmp:
		dc.w	0
		dc.w	0

 MACRO<CUT_DOLINELEFT>
		sub.w	d1,d3
		beq.w	.skip\@
		bmi.w	.skip\@
		
		sub.w	d0,d2
			
		sub.w	d5,d0
		
		move.b	d2,(a6)
		move.w	(a6),d2			;fast lsl #8
		
		moveq	#$fffffffe,d6
		and.w	d2,d6
		add.w	d3,d3
		move.w	(a3,d6.w),d2
		sub.w	(a3,d3.w),d2
		move.w	(a5,d2.w),d2	;fast divs.w d1,d0 with log/exp table method
		add.w	d2,d2
		
		lea		linebuf,a7
		add.w	d1,d1
		adda.w	d1,a7
						
		move.w	#$ff,d1
		sub.w	d3,d1
		add.w	d1,d1
		move.w	d1,.smc\@+2

		move.b	d0,(a6)
		move.w	(a6),d0			;fast lsl #8
		move.b	#$80,d0	
		
.smc\@:		
		bra.w	.enter\@+4*63	;+4*255 is important to avoid that the assembler optimizates the branch away or down to .b
.enter\@:		
		REPT 128
		move.w	d0,(a7)+
		add.w	d2,d0
		ENDR
.skip\@:
 ENDM 
 
;--------------------------------------------------------------------

 MACRO<CUT_DOLINERIGHT>
		sub.w	d3,d1
		beq.w	.skip\@
		bmi.w	.skip\@
		
		sub.w	d2,d0

		lea		linebuf+1,a7

		sub.w	d5,d2

		move.b	d0,(a6)
		move.w	(a6),d0			; fast lsl #8
		
		moveq	#$fffffffe,d6
		and.w	d0,d6
		add.w	d1,d1
		
		move.w	(a3,d6.w),d0
		sub.w	(a3,d1.w),d0
		move.w	(a5,d0.w),d0	;fast divs.w d1,d0 with log/exp table method
		add.w	d0,d0
		
		add.w	d3,d3
		adda.w	d3,a7
	
		move.w	#$ff,d3
		sub.w	d1,d3
		
		add.w	d3,d3
		move.w	d3,.smc\@+2
	
		ror.w	#8,d0

		andi.w	#$ff,d2
		ori.w	#$8000,d2		; fraction part
		addi.w	#0,d2
		
.smc\@:		
		bra.w	.enter\@+4*63	;+6*255 is important to avoid that the assembler optimizates the branch away or down to .b
.enter\@:		
		REPT	128
		move.b	d2,(a7)+		;only possible with a7 (this interleaves the bytes into the words of the left lines).
		addx.w	d0,d2
		ENDR
.skip\@:
 ENDM
 		
;--------------------------------------------------------------------

cut_LINEMOD	= $40
cut_COLMOD	= cut_LINEMOD*192

	MACRO<CUT_FILLSMALL1>
		lea		\1(a6),a6
		move.w	d5,d2
		swap	d5
		and.w	d5,d2
		or.w	d2,-cut_COLMOD+0(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*3(a6)
		not.w	d2
		and.w	d2,(a6)
		and.w	d2,-cut_COLMOD+cut_COLMOD*2(a6)
		lea		cut_LINEMOD-\1(a6),a6
	ENDM

	MACRO<CUT_FILLSMALL2>
		lea		\1(a6),a6
		move.w	d5,d2
		swap	d5
		and.w	d5,d2
		or.w	d2,(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*3(a6)
		not.w	d2
		and.w	d2,-cut_COLMOD+0(a6)
		and.w	d2,-cut_COLMOD+cut_COLMOD*2(a6)
		lea		cut_LINEMOD-\1(a6),a6
	ENDM

	MACRO<CUT_FILLSMALL3>
		lea		\1(a6),a6
		move.w	d5,d2
		swap	d5
		and.w	d5,d2
		or.w	d2,-cut_COLMOD+0(a6)
		or.w	d2,(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*3(a6)
		not.w	d2
		and.w	d2,-cut_COLMOD+cut_COLMOD*2(a6)
		lea		cut_LINEMOD-\1(a6),a6
	ENDM
	
	MACRO<CUT_FILLSMALL4>
		lea		\1(a6),a6
		move.w	d5,d2
		swap	d5
		and.w	d5,d2
		or.w	d2,-cut_COLMOD+cut_COLMOD*2(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*3(a6)
		not.w	d2
		and.w	d2,-cut_COLMOD+0(a6)
		and.w	d2,(a6)
		lea		cut_LINEMOD-\1(a6),a6
	ENDM

	MACRO<CUT_FILLSMALL5>
		lea		\1(a6),a6
		move.w	d5,d2
		swap	d5
		and.w	d5,d2
		or.w	d2,-cut_COLMOD+0(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*2(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*3(a6)
		not.w	d2
		and.w	d2,(a6)
		lea		cut_LINEMOD-\1(a6),a6
	ENDM
	
	MACRO<CUT_FILLSMALL6>
		lea		\1(a6),a6
		move.w	d5,d2
		swap	d5
		and.w	d5,d2
		or.w	d2,(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*2(a6)
		or.w	d2,-cut_COLMOD+cut_COLMOD*3(a6)
		not.w	d2
		and.w	d2,-cut_COLMOD+0(a6)
		lea		cut_LINEMOD-\1(a6),a6
	ENDM
	
	MACRO<CUT_FILLSMALL7>

	ENDM
	
	MACRO<CUT_FILLWIDE1>
		lea		-cut_COLMOD+\1(a6),a6
		lea		cut_COLMOD(a6),a0
		lea		cut_COLMOD(a0),a2
		lea		cut_COLMOD(a2),a7
		or.w	d5,(a6)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a0)+
		and.w	d5,(a2)+
		REPT	\3
		move.w	d7,(a6)+
		move.w	d7,(a7)+
		move.w	d0,(a0)+
		move.w	d0,(a2)+
		ENDR
		REPT	\2
		move.l	d7,(a6)+
		move.l	d7,(a7)+
		move.l	d0,(a0)+
		move.l	d0,(a2)+
		ENDR
		swap	d5
		or.w	d5,(a6)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a0)+
		and.w	d5,(a2)+
		lea		cut_COLMOD+cut_LINEMOD-\1-\3*2-\2*4-4(a6),a6
	ENDM	
	
	MACRO<CUT_FILLWIDE2>
		lea		-cut_COLMOD+\1(a6),a6
		lea		cut_COLMOD(a6),a0
		lea		cut_COLMOD(a0),a2
		lea		cut_COLMOD(a2),a7
		or.w	d5,(a0)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a6)+
		and.w	d5,(a2)+
		REPT	\3
		move.w	d7,(a0)+
		move.w	d7,(a7)+
		move.w	d0,(a6)+
		move.w	d0,(a2)+
		ENDR
		REPT	\2
		move.l	d7,(a0)+
		move.l	d7,(a7)+
		move.l	d0,(a6)+
		move.l	d0,(a2)+
		ENDR
		swap	d5
		or.w	d5,(a0)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a6)+
		and.w	d5,(a2)+
		lea		cut_COLMOD+cut_LINEMOD-\1-\3*2-\2*4-4(a6),a6
	ENDM

	MACRO<CUT_FILLWIDE3>
		lea		-cut_COLMOD+\1(a6),a6
		lea		cut_COLMOD(a6),a0
		lea		cut_COLMOD(a0),a2
		lea		cut_COLMOD(a2),a7
		or.w	d5,(a0)+
		or.w	d5,(a7)+
		or.w	d5,(a6)+
		not.w	d5
		and.w	d5,(a2)+
		REPT	\3
		move.w	d7,(a0)+
		move.w	d7,(a7)+
		move.w	d7,(a6)+
		move.w	d0,(a2)+
		ENDR
		REPT	\2
		move.l	d7,(a0)+
		move.l	d7,(a7)+
		move.l	d7,(a6)+
		move.l	d0,(a2)+
		ENDR
		swap	d5
		or.w	d5,(a0)+
		or.w	d5,(a7)+
		or.w	d5,(a6)+
		not.w	d5
		and.w	d5,(a2)+
		lea		cut_COLMOD+cut_LINEMOD-\1-\3*2-\2*4-4(a6),a6
	ENDM
		
	MACRO<CUT_FILLWIDE4>
		lea		-cut_COLMOD+\1(a6),a6
		lea		cut_COLMOD(a6),a0
		lea		cut_COLMOD(a0),a2
		lea		cut_COLMOD(a2),a7
		or.w	d5,(a2)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a6)+
		and.w	d5,(a0)+
		REPT	\3
		move.w	d7,(a2)+
		move.w	d7,(a7)+
		move.w	d0,(a6)+
		move.w	d0,(a0)+
		ENDR
		REPT	\2
		move.l	d7,(a2)+
		move.l	d7,(a7)+
		move.l	d0,(a6)+
		move.l	d0,(a0)+
		ENDR
		swap	d5
		or.w	d5,(a2)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a6)+
		and.w	d5,(a0)+
		lea		cut_COLMOD+cut_LINEMOD-\1-\3*2-\2*4-4(a6),a6
	ENDM
	
	MACRO<CUT_FILLWIDE5>
		lea		-cut_COLMOD+\1(a6),a6
		lea		cut_COLMOD(a6),a0
		lea		cut_COLMOD(a0),a2
		lea		cut_COLMOD(a2),a7
		or.w	d5,(a2)+
		or.w	d5,(a6)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a0)+
		REPT	\3
		move.w	d7,(a2)+
		move.w	d7,(a7)+
		move.w	d7,(a6)+
		move.w	d0,(a0)+
		ENDR
		REPT	\2
		move.l	d7,(a2)+
		move.l	d7,(a7)+
		move.l	d7,(a6)+
		move.l	d0,(a0)+
		ENDR
		swap	d5
		or.w	d5,(a2)+
		or.w	d5,(a7)+
		or.w	d5,(a6)+
		not.w	d5
		and.w	d5,(a0)+
		lea		cut_COLMOD+cut_LINEMOD-\1-\3*2-\2*4-4(a6),a6
	ENDM	
	
	MACRO<CUT_FILLWIDE6>
		lea		-cut_COLMOD+\1(a6),a6
		lea		cut_COLMOD(a6),a0
		lea		cut_COLMOD(a0),a2
		lea		cut_COLMOD(a2),a7
		or.w	d5,(a2)+
		or.w	d5,(a0)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a6)+
		REPT	\3
		move.w	d7,(a2)+
		move.w	d7,(a0)+
		move.w	d7,(a7)+
		move.w	d0,(a6)+
		ENDR
		REPT	\2
		move.l	d7,(a2)+
		move.l	d7,(a0)+
		move.l	d7,(a7)+
		move.l	d0,(a6)+
		ENDR
		swap	d5
		or.w	d5,(a2)+
		or.w	d5,(a0)+
		or.w	d5,(a7)+
		not.w	d5
		and.w	d5,(a6)+
		lea		cut_COLMOD+cut_LINEMOD-\1-\3*2-\2*4-4(a6),a6
	ENDM
	
	MACRO<CUT_FILLWIDE7>

	ENDM
		
	MACRO<CUT_FETCHLINE>
		move.w	(a3)+,d5
		moveq	#$fffffffe,d6
		and.w	d5,d6		
		move.w	(a1,d6.w),d6	;jmp offsets
		add.w	d5,d5
		add.w	d5,d5
		move.l	(a5,d5.w),d5	;left & right mask
		jmp		(a4,d6.w)		;jmp tab
		REPT \1
		nop
		ENDR
	ENDM
	
 MACRO<CUT_ENDPOLY>
		jmp		cut_drawpolyend
 ENDM
 
		MACRO<CUT_FILLSPERCOL>
fill\100:
		CUT_FILLSMALL\1 0
		CUT_FETCHLINE \2*1
fill\110:
		CUT_ENDPOLY
fill\120:
		CUT_ENDPOLY
fill\130:
		CUT_ENDPOLY
fill\140:
		CUT_ENDPOLY
fill\150:
		CUT_ENDPOLY
fill\160:
		CUT_ENDPOLY
fill\170:
		CUT_ENDPOLY
fill\180:
		CUT_ENDPOLY
fill\190:
		CUT_ENDPOLY
fill\1a0:
		CUT_ENDPOLY
fill\1b0:
		CUT_ENDPOLY
fill\1c0:
		CUT_ENDPOLY
fill\1d0:
		CUT_ENDPOLY
fill\1e0:
		CUT_ENDPOLY
fill\1f0:
		CUT_ENDPOLY
		
fill\101:
		CUT_FILLWIDE\1 0,0,0
		CUT_FETCHLINE \2*2
fill\111:
		CUT_FILLSMALL\1 2
		CUT_FETCHLINE \2*1
fill\121:
		CUT_ENDPOLY
fill\131:
		CUT_ENDPOLY
fill\141:
		CUT_ENDPOLY
fill\151:
		CUT_ENDPOLY
fill\161:
		CUT_ENDPOLY
fill\171:
		CUT_ENDPOLY
fill\181:
		CUT_ENDPOLY
fill\191:
		CUT_ENDPOLY
fill\1a1:
		CUT_ENDPOLY
fill\1b1:
		CUT_ENDPOLY
fill\1c1:
		CUT_ENDPOLY
fill\1d1:
		CUT_ENDPOLY
fill\1e1:
		CUT_ENDPOLY
fill\1f1:
		CUT_ENDPOLY

fill\102:
		CUT_FILLWIDE\1 0,0,1
		CUT_FETCHLINE \2*2
fill\112:
		CUT_FILLWIDE\1 2,0,0
		CUT_FETCHLINE \2*2
fill\122:
		CUT_FILLSMALL\1 4
		CUT_FETCHLINE \2*1
fill\132:
		CUT_ENDPOLY
fill\142:
		CUT_ENDPOLY
fill\152:
		CUT_ENDPOLY
fill\162:
		CUT_ENDPOLY
fill\172:
		CUT_ENDPOLY
fill\182:
		CUT_ENDPOLY
fill\192:
		CUT_ENDPOLY
fill\1a2:
		CUT_ENDPOLY
fill\1b2:
		CUT_ENDPOLY
fill\1c2:
		CUT_ENDPOLY
fill\1d2:
		CUT_ENDPOLY
fill\1e2:
		CUT_ENDPOLY
fill\1f2:
		CUT_ENDPOLY
		
fill\103:
		CUT_FILLWIDE\1 0,1,0
		CUT_FETCHLINE \2*2
fill\113:
		CUT_FILLWIDE\1 2,0,1
		CUT_FETCHLINE \2*2
fill\123:
		CUT_FILLWIDE\1 4,0,0
		CUT_FETCHLINE \2*2
fill\133:
		CUT_FILLSMALL\1 6
		CUT_FETCHLINE \2*1
fill\143:
		CUT_ENDPOLY
fill\153:
		CUT_ENDPOLY
fill\163:
		CUT_ENDPOLY
fill\173:
		CUT_ENDPOLY
fill\183:
		CUT_ENDPOLY
fill\193:
		CUT_ENDPOLY
fill\1a3:
		CUT_ENDPOLY
fill\1b3:
		CUT_ENDPOLY
fill\1c3:
		CUT_ENDPOLY
fill\1d3:
		CUT_ENDPOLY
fill\1e3:
		CUT_ENDPOLY
fill\1f3:
		CUT_ENDPOLY
		
fill\104:
		CUT_FILLWIDE\1 0,1,1
		CUT_FETCHLINE \2*2
fill\114:
		CUT_FILLWIDE\1 2,1,0
		CUT_FETCHLINE \2*2
fill\124:
		CUT_FILLWIDE\1 4,0,1
		CUT_FETCHLINE \2*2
fill\134:
		CUT_FILLWIDE\1 6,0,0
		CUT_FETCHLINE \2*2
fill\144:
		CUT_FILLSMALL\1 8
		CUT_FETCHLINE \2*1
fill\154:
		CUT_ENDPOLY
fill\164:
		CUT_ENDPOLY
fill\174:
		CUT_ENDPOLY
fill\184:
		CUT_ENDPOLY
fill\194:
		CUT_ENDPOLY
fill\1a4:
		CUT_ENDPOLY
fill\1b4:
		CUT_ENDPOLY
fill\1c4:
		CUT_ENDPOLY
fill\1d4:
		CUT_ENDPOLY
fill\1e4:
		CUT_ENDPOLY
fill\1f4:
		CUT_ENDPOLY
		
fill\105:
		CUT_FILLWIDE\1 0,2,0
		CUT_FETCHLINE \2*2
fill\115:
		CUT_FILLWIDE\1 2,1,1
		CUT_FETCHLINE \2*2
fill\125:
		CUT_FILLWIDE\1 4,1,0
		CUT_FETCHLINE \2*2
fill\135:
		CUT_FILLWIDE\1 6,0,1
		CUT_FETCHLINE \2*2
fill\145:
		CUT_FILLWIDE\1 8,0,0
		CUT_FETCHLINE \2*2
fill\155:
		CUT_FILLSMALL\1 10
		CUT_FETCHLINE \2*1
fill\165:
		CUT_ENDPOLY
fill\175:
		CUT_ENDPOLY
fill\185:
		CUT_ENDPOLY
fill\195:
		CUT_ENDPOLY
fill\1a5:
		CUT_ENDPOLY
fill\1b5:
		CUT_ENDPOLY
fill\1c5:
		CUT_ENDPOLY
fill\1d5:
		CUT_ENDPOLY
fill\1e5:
		CUT_ENDPOLY
fill\1f5:
		CUT_ENDPOLY
		
fill\106:
		CUT_FILLWIDE\1 0,2,1
		CUT_FETCHLINE \2*2
fill\116:
		CUT_FILLWIDE\1 2,2,0
		CUT_FETCHLINE \2*2
fill\126:
		CUT_FILLWIDE\1 4,1,1
		CUT_FETCHLINE \2*2
fill\136:
		CUT_FILLWIDE\1 6,1,0
		CUT_FETCHLINE \2*2
fill\146:
		CUT_FILLWIDE\1 8,0,1
		CUT_FETCHLINE \2*2
fill\156:
		CUT_FILLWIDE\1 10,0,0
		CUT_FETCHLINE \2*2
fill\166:
		CUT_FILLSMALL\1 12
		CUT_FETCHLINE \2*1
fill\176:
		CUT_ENDPOLY
fill\186:
		CUT_ENDPOLY
fill\196:
		CUT_ENDPOLY
fill\1a6:
		CUT_ENDPOLY
fill\1b6:
		CUT_ENDPOLY
fill\1c6:
		CUT_ENDPOLY
fill\1d6:
		CUT_ENDPOLY
fill\1e6:
		CUT_ENDPOLY
fill\1f6:
		CUT_ENDPOLY
		
fill\107:
		CUT_FILLWIDE\1 0,3,0
		CUT_FETCHLINE \2*2
fill\117:
		CUT_FILLWIDE\1 2,2,1
		CUT_FETCHLINE \2*2
fill\127:
		CUT_FILLWIDE\1 4,2,0
		CUT_FETCHLINE \2*2
fill\137:
		CUT_FILLWIDE\1 6,1,1
		CUT_FETCHLINE \2*2
fill\147:
		CUT_FILLWIDE\1 8,1,0
		CUT_FETCHLINE \2*2
fill\157:
		CUT_FILLWIDE\1 10,0,1
		CUT_FETCHLINE \2*2
fill\167:
		CUT_FILLWIDE\1 12,0,0
		CUT_FETCHLINE \2*2
fill\177:
		CUT_FILLSMALL\1 14
		CUT_FETCHLINE \2*1
fill\187:
		CUT_ENDPOLY
fill\197:
		CUT_ENDPOLY
fill\1a7:
		CUT_ENDPOLY
fill\1b7:
		CUT_ENDPOLY
fill\1c7:
		CUT_ENDPOLY
fill\1d7:
		CUT_ENDPOLY
fill\1e7:
		CUT_ENDPOLY
fill\1f7:
		CUT_ENDPOLY
				
fill\108:
		CUT_FILLWIDE\1 0,3,1
		CUT_FETCHLINE \2*2
fill\118:
		CUT_FILLWIDE\1 2,3,0
		CUT_FETCHLINE \2*2
fill\128:
		CUT_FILLWIDE\1 4,2,1
		CUT_FETCHLINE \2*2
fill\138:
		CUT_FILLWIDE\1 6,2,0
		CUT_FETCHLINE \2*2
fill\148:
		CUT_FILLWIDE\1 8,1,1
		CUT_FETCHLINE \2*2
fill\158:
		CUT_FILLWIDE\1 10,1,0
		CUT_FETCHLINE \2*2
fill\168:
		CUT_FILLWIDE\1 12,0,1
		CUT_FETCHLINE \2*2
fill\178:
		CUT_FILLWIDE\1 14,0,0
		CUT_FETCHLINE \2*2
fill\188:
		CUT_FILLSMALL\1 16
		CUT_FETCHLINE \2*1
fill\198:
		CUT_ENDPOLY
fill\1a8:
		CUT_ENDPOLY
fill\1b8:
		CUT_ENDPOLY
fill\1c8:
		CUT_ENDPOLY
fill\1d8:
		CUT_ENDPOLY
fill\1e8:
		CUT_ENDPOLY
fill\1f8:
		CUT_ENDPOLY		
		
fill\109:
		CUT_FILLWIDE\1 0,4,0
		CUT_FETCHLINE \2*2
fill\119:
		CUT_FILLWIDE\1 2,3,1
		CUT_FETCHLINE \2*2
fill\129:
		CUT_FILLWIDE\1 4,3,0
		CUT_FETCHLINE \2*2
fill\139:
		CUT_FILLWIDE\1 6,2,1
		CUT_FETCHLINE \2*2
fill\149:
		CUT_FILLWIDE\1 8,2,0
		CUT_FETCHLINE \2*2
fill\159:
		CUT_FILLWIDE\1 10,1,1
		CUT_FETCHLINE \2*2
fill\169:
		CUT_FILLWIDE\1 12,1,0
		CUT_FETCHLINE \2*2
fill\179:
		CUT_FILLWIDE\1 14,0,1
		CUT_FETCHLINE \2*2
fill\189:
		CUT_FILLWIDE\1 16,0,0
		CUT_FETCHLINE \2*2
fill\199:
		CUT_FILLSMALL\1 18
		CUT_FETCHLINE \2*1
fill\1a9:
		CUT_ENDPOLY
fill\1b9:
		CUT_ENDPOLY
fill\1c9:
		CUT_ENDPOLY
fill\1d9:
		CUT_ENDPOLY
fill\1e9:
		CUT_ENDPOLY
fill\1f9:
		CUT_ENDPOLY		
		
fill\10a:
		CUT_FILLWIDE\1 0,4,1
		CUT_FETCHLINE \2*2
fill\11a:
		CUT_FILLWIDE\1 2,4,0
		CUT_FETCHLINE \2*2
fill\12a:
		CUT_FILLWIDE\1 4,3,1
		CUT_FETCHLINE \2*2
fill\13a:
		CUT_FILLWIDE\1 6,3,0
		CUT_FETCHLINE \2*2
fill\14a:
		CUT_FILLWIDE\1 8,2,1
		CUT_FETCHLINE \2*2
fill\15a:
		CUT_FILLWIDE\1 10,2,0
		CUT_FETCHLINE \2*2
fill\16a:
		CUT_FILLWIDE\1 12,1,1
		CUT_FETCHLINE \2*2
fill\17a:
		CUT_FILLWIDE\1 14,1,0
		CUT_FETCHLINE \2*2
fill\18a:
		CUT_FILLWIDE\1 16,0,1
		CUT_FETCHLINE \2*2
fill\19a:
		CUT_FILLWIDE\1 18,0,0
		CUT_FETCHLINE \2*2
fill\1aa:
		CUT_FILLSMALL\1 20
		CUT_FETCHLINE \2*1
fill\1ba:
		CUT_ENDPOLY
fill\1ca:
		CUT_ENDPOLY
fill\1da:
		CUT_ENDPOLY
fill\1ea:
		CUT_ENDPOLY
fill\1fa:
		CUT_ENDPOLY		
		
fill\10b:
		CUT_FILLWIDE\1 0,5,0
		CUT_FETCHLINE \2*2
fill\11b:
		CUT_FILLWIDE\1 2,4,1
		CUT_FETCHLINE \2*2
fill\12b:
		CUT_FILLWIDE\1 4,4,0
		CUT_FETCHLINE \2*2
fill\13b:
		CUT_FILLWIDE\1 6,3,1
		CUT_FETCHLINE \2*2
fill\14b:
		CUT_FILLWIDE\1 8,3,0
		CUT_FETCHLINE \2*2
fill\15b:
		CUT_FILLWIDE\1 10,2,1
		CUT_FETCHLINE \2*2
fill\16b:
		CUT_FILLWIDE\1 12,2,0
		CUT_FETCHLINE \2*2
fill\17b:
		CUT_FILLWIDE\1 14,1,1
		CUT_FETCHLINE \2*2
fill\18b:
		CUT_FILLWIDE\1 16,1,0
		CUT_FETCHLINE \2*2
fill\19b:
		CUT_FILLWIDE\1 18,0,1
		CUT_FETCHLINE \2*2
fill\1ab:
		CUT_FILLWIDE\1 20,0,0
		CUT_FETCHLINE \2*2
fill\1bb:
		CUT_FILLSMALL\1 22
		CUT_FETCHLINE \2*1
fill\1cb:
		CUT_ENDPOLY
fill\1db:
		CUT_ENDPOLY
fill\1eb:
		CUT_ENDPOLY
fill\1fb:
		CUT_ENDPOLY	
		
fill\10c:
		CUT_FILLWIDE\1 0,5,1
		CUT_FETCHLINE \2*2
fill\11c:
		CUT_FILLWIDE\1 2,5,0
		CUT_FETCHLINE \2*2
fill\12c:
		CUT_FILLWIDE\1 4,4,1
		CUT_FETCHLINE \2*2
fill\13c:
		CUT_FILLWIDE\1 6,4,0
		CUT_FETCHLINE \2*2
fill\14c:
		CUT_FILLWIDE\1 8,3,1
		CUT_FETCHLINE \2*2
fill\15c:
		CUT_FILLWIDE\1 10,3,0
		CUT_FETCHLINE \2*2
fill\16c:
		CUT_FILLWIDE\1 12,2,1
		CUT_FETCHLINE \2*2
fill\17c:
		CUT_FILLWIDE\1 14,2,0
		CUT_FETCHLINE \2*2
fill\18c:
		CUT_FILLWIDE\1 16,1,1
		CUT_FETCHLINE \2*2
fill\19c:
		CUT_FILLWIDE\1 18,1,0
		CUT_FETCHLINE \2*2
fill\1ac:
		CUT_FILLWIDE\1 20,0,1
		CUT_FETCHLINE \2*2
fill\1bc:
		CUT_FILLWIDE\1 22,0,0
		CUT_FETCHLINE \2*2
fill\1cc:
		CUT_FILLSMALL\1 24
		CUT_FETCHLINE \2*1
fill\1dc:
		CUT_ENDPOLY
fill\1ec:
		CUT_ENDPOLY
fill\1fc:
		CUT_ENDPOLY	
		
fill\10d:
		CUT_FILLWIDE\1 0,6,0
		CUT_FETCHLINE \2*2
fill\11d:
		CUT_FILLWIDE\1 2,5,1
		CUT_FETCHLINE \2*2
fill\12d:
		CUT_FILLWIDE\1 4,5,0
		CUT_FETCHLINE \2*2
fill\13d:
		CUT_FILLWIDE\1 6,4,1
		CUT_FETCHLINE \2*2
fill\14d:
		CUT_FILLWIDE\1 8,4,0
		CUT_FETCHLINE \2*2
fill\15d:
		CUT_FILLWIDE\1 10,3,1
		CUT_FETCHLINE \2*2
fill\16d:
		CUT_FILLWIDE\1 12,3,0
		CUT_FETCHLINE \2*2
fill\17d:
		CUT_FILLWIDE\1 14,2,1
		CUT_FETCHLINE \2*2
fill\18d:
		CUT_FILLWIDE\1 16,2,0
		CUT_FETCHLINE \2*2
fill\19d:
		CUT_FILLWIDE\1 18,1,1
		CUT_FETCHLINE \2*2
fill\1ad:
		CUT_FILLWIDE\1 20,1,0
		CUT_FETCHLINE \2*2
fill\1bd:
		CUT_FILLWIDE\1 22,0,1
		CUT_FETCHLINE \2*2
fill\1cd:
		CUT_FILLWIDE\1 24,0,0
		CUT_FETCHLINE \2*2
fill\1dd:
		CUT_FILLSMALL\1 26
		CUT_FETCHLINE \2*1
fill\1ed:
		CUT_ENDPOLY
fill\1fd:
		CUT_ENDPOLY	
				
fill\10e:
		CUT_FILLWIDE\1 0,6,1
		CUT_FETCHLINE \2*2
fill\11e:
		CUT_FILLWIDE\1 2,6,0
		CUT_FETCHLINE \2*2
fill\12e:
		CUT_FILLWIDE\1 4,5,1
		CUT_FETCHLINE \2*2
fill\13e:
		CUT_FILLWIDE\1 6,5,0
		CUT_FETCHLINE \2*2
fill\14e:
		CUT_FILLWIDE\1 8,4,1
		CUT_FETCHLINE \2*2
fill\15e:
		CUT_FILLWIDE\1 10,4,0
		CUT_FETCHLINE \2*2
fill\16e:
		CUT_FILLWIDE\1 12,3,1
		CUT_FETCHLINE \2*2
fill\17e:
		CUT_FILLWIDE\1 14,3,0
		CUT_FETCHLINE \2*2
fill\18e:
		CUT_FILLWIDE\1 16,2,1
		CUT_FETCHLINE \2*2
fill\19e:
		CUT_FILLWIDE\1 18,2,0
		CUT_FETCHLINE \2*2
fill\1ae:
		CUT_FILLWIDE\1 20,1,1
		CUT_FETCHLINE \2*2
fill\1be:
		CUT_FILLWIDE\1 22,1,0
		CUT_FETCHLINE \2*2
fill\1ce:
		CUT_FILLWIDE\1 24,0,1
		CUT_FETCHLINE \2*2
fill\1de:
		CUT_FILLWIDE\1 26,0,0
		CUT_FETCHLINE \2*2
fill\1ee:
		CUT_FILLSMALL\1 28
		CUT_FETCHLINE \2*1
fill\1fe:
		CUT_ENDPOLY	
				
fill\10f:
		CUT_FILLWIDE\1 0,7,0
		CUT_FETCHLINE \2*2
fill\11f:
		CUT_FILLWIDE\1 2,6,1
		CUT_FETCHLINE \2*2
fill\12f:
		CUT_FILLWIDE\1 4,6,0
		CUT_FETCHLINE \2*2
fill\13f:
		CUT_FILLWIDE\1 6,5,1
		CUT_FETCHLINE \2*2
fill\14f:
		CUT_FILLWIDE\1 8,5,0
		CUT_FETCHLINE \2*2
fill\15f:
		CUT_FILLWIDE\1 10,4,1
		CUT_FETCHLINE \2*2
fill\16f:
		CUT_FILLWIDE\1 12,4,0
		CUT_FETCHLINE \2*2
fill\17f:
		CUT_FILLWIDE\1 14,3,1
		CUT_FETCHLINE \2*2
fill\18f:
		CUT_FILLWIDE\1 16,3,0
		CUT_FETCHLINE \2*2
fill\19f:
		CUT_FILLWIDE\1 18,2,1
		CUT_FETCHLINE \2*2
fill\1af:
		CUT_FILLWIDE\1 20,2,0
		CUT_FETCHLINE \2*2
fill\1bf:
		CUT_FILLWIDE\1 22,1,1
		CUT_FETCHLINE \2*2
fill\1cf:
		CUT_FILLWIDE\1 24,1,0
		CUT_FETCHLINE \2*2
fill\1df:
		CUT_FILLWIDE\1 26,0,1
		CUT_FETCHLINE \2*2
fill\1ef:
		CUT_FILLWIDE\1 28,0,0
		CUT_FETCHLINE \2*2
fill\1ff:
		CUT_FILLSMALL\1 30
		CUT_FETCHLINE \2*1
		
		ENDM
				
cut_dofill:
		lea		cut_poly,a0
		move.w	(a0)+,d3	; color
		move.w	(a0)+,d5	; minx
		move.w	(a0)+,d4	; miny
		move.w	(a0)+,d7	; maxy
		
		movem.l	cut_fillregsl(pc),a3-a6
		lea		jmpoffsets,a1

		move.l	(a4,d3.w),a4
		
		add.w	d7,d7
		move.w	#$ff,2(a3,d7.w)
		
		add.w	d4,d4
		adda.w	d4,a3
		
		lsl.w	#5,d4
		lsr.w	#3,d5
		add.w	d5,d4
		adda.w	d4,a6
		
		moveq	#-1,d7
		moveq	#0,d0

		CUT_FETCHLINE 0
		
		cnop	0,4
cut_fillregsl:
		dc.l	linebuf
		dc.l	fillcolbases
		dc.l	leftrightmasks
		dc.l	0		
	
filloffsets:
		dc.w	fill100-fillbase
		dc.w	fill110-fillbase
		dc.w	fill120-fillbase
		dc.w	fill130-fillbase
		dc.w	fill140-fillbase
		dc.w	fill150-fillbase
		dc.w	fill160-fillbase
		dc.w	fill170-fillbase
		dc.w	fill180-fillbase
		dc.w	fill190-fillbase
		dc.w	fill1a0-fillbase
		dc.w	fill1b0-fillbase
		dc.w	fill1c0-fillbase
		dc.w	fill1d0-fillbase
		dc.w	fill1e0-fillbase
		dc.w	fill1f0-fillbase

		dc.w	fill101-fillbase
		dc.w	fill111-fillbase
		dc.w	fill121-fillbase
		dc.w	fill131-fillbase
		dc.w	fill141-fillbase
		dc.w	fill151-fillbase
		dc.w	fill161-fillbase
		dc.w	fill171-fillbase
		dc.w	fill181-fillbase
		dc.w	fill191-fillbase
		dc.w	fill1a1-fillbase
		dc.w	fill1b1-fillbase
		dc.w	fill1c1-fillbase
		dc.w	fill1d1-fillbase
		dc.w	fill1e1-fillbase
		dc.w	fill1f1-fillbase
		
		dc.w	fill102-fillbase
		dc.w	fill112-fillbase
		dc.w	fill122-fillbase
		dc.w	fill132-fillbase
		dc.w	fill142-fillbase
		dc.w	fill152-fillbase
		dc.w	fill162-fillbase
		dc.w	fill172-fillbase
		dc.w	fill182-fillbase
		dc.w	fill192-fillbase
		dc.w	fill1a2-fillbase
		dc.w	fill1b2-fillbase
		dc.w	fill1c2-fillbase
		dc.w	fill1d2-fillbase
		dc.w	fill1e2-fillbase
		dc.w	fill1f2-fillbase
		
		dc.w	fill103-fillbase
		dc.w	fill113-fillbase
		dc.w	fill123-fillbase
		dc.w	fill133-fillbase
		dc.w	fill143-fillbase
		dc.w	fill153-fillbase
		dc.w	fill163-fillbase
		dc.w	fill173-fillbase
		dc.w	fill183-fillbase
		dc.w	fill193-fillbase
		dc.w	fill1a3-fillbase
		dc.w	fill1b3-fillbase
		dc.w	fill1c3-fillbase
		dc.w	fill1d3-fillbase
		dc.w	fill1e3-fillbase
		dc.w	fill1f3-fillbase
		
		dc.w	fill104-fillbase
		dc.w	fill114-fillbase
		dc.w	fill124-fillbase
		dc.w	fill134-fillbase
		dc.w	fill144-fillbase
		dc.w	fill154-fillbase
		dc.w	fill164-fillbase
		dc.w	fill174-fillbase
		dc.w	fill184-fillbase
		dc.w	fill194-fillbase
		dc.w	fill1a4-fillbase
		dc.w	fill1b4-fillbase
		dc.w	fill1c4-fillbase
		dc.w	fill1d4-fillbase
		dc.w	fill1e4-fillbase
		dc.w	fill1f4-fillbase
		
		dc.w	fill105-fillbase
		dc.w	fill115-fillbase
		dc.w	fill125-fillbase
		dc.w	fill135-fillbase
		dc.w	fill145-fillbase
		dc.w	fill155-fillbase
		dc.w	fill165-fillbase
		dc.w	fill175-fillbase
		dc.w	fill185-fillbase
		dc.w	fill195-fillbase
		dc.w	fill1a5-fillbase
		dc.w	fill1b5-fillbase
		dc.w	fill1c5-fillbase
		dc.w	fill1d5-fillbase
		dc.w	fill1e5-fillbase
		dc.w	fill1f5-fillbase
		
		dc.w	fill106-fillbase
		dc.w	fill116-fillbase
		dc.w	fill126-fillbase
		dc.w	fill136-fillbase
		dc.w	fill146-fillbase
		dc.w	fill156-fillbase
		dc.w	fill166-fillbase
		dc.w	fill176-fillbase
		dc.w	fill186-fillbase
		dc.w	fill196-fillbase
		dc.w	fill1a6-fillbase
		dc.w	fill1b6-fillbase
		dc.w	fill1c6-fillbase
		dc.w	fill1d6-fillbase
		dc.w	fill1e6-fillbase
		dc.w	fill1f6-fillbase
		
		dc.w	fill107-fillbase
		dc.w	fill117-fillbase
		dc.w	fill127-fillbase
		dc.w	fill137-fillbase
		dc.w	fill147-fillbase
		dc.w	fill157-fillbase
		dc.w	fill167-fillbase
		dc.w	fill177-fillbase
		dc.w	fill187-fillbase
		dc.w	fill197-fillbase
		dc.w	fill1a7-fillbase
		dc.w	fill1b7-fillbase
		dc.w	fill1c7-fillbase
		dc.w	fill1d7-fillbase
		dc.w	fill1e7-fillbase
		dc.w	fill1f7-fillbase
	
		dc.w	fill108-fillbase
		dc.w	fill118-fillbase
		dc.w	fill128-fillbase
		dc.w	fill138-fillbase
		dc.w	fill148-fillbase
		dc.w	fill158-fillbase
		dc.w	fill168-fillbase
		dc.w	fill178-fillbase
		dc.w	fill188-fillbase
		dc.w	fill198-fillbase
		dc.w	fill1a8-fillbase
		dc.w	fill1b8-fillbase
		dc.w	fill1c8-fillbase
		dc.w	fill1d8-fillbase
		dc.w	fill1e8-fillbase
		dc.w	fill1f8-fillbase
		
		dc.w	fill109-fillbase
		dc.w	fill119-fillbase
		dc.w	fill129-fillbase
		dc.w	fill139-fillbase
		dc.w	fill149-fillbase
		dc.w	fill159-fillbase
		dc.w	fill169-fillbase
		dc.w	fill179-fillbase
		dc.w	fill189-fillbase
		dc.w	fill199-fillbase
		dc.w	fill1a9-fillbase
		dc.w	fill1b9-fillbase
		dc.w	fill1c9-fillbase
		dc.w	fill1d9-fillbase
		dc.w	fill1e9-fillbase
		dc.w	fill1f9-fillbase		
			
		dc.w	fill10a-fillbase
		dc.w	fill11a-fillbase
		dc.w	fill12a-fillbase
		dc.w	fill13a-fillbase
		dc.w	fill14a-fillbase
		dc.w	fill15a-fillbase
		dc.w	fill16a-fillbase
		dc.w	fill17a-fillbase
		dc.w	fill18a-fillbase
		dc.w	fill19a-fillbase
		dc.w	fill1aa-fillbase
		dc.w	fill1ba-fillbase
		dc.w	fill1ca-fillbase
		dc.w	fill1da-fillbase
		dc.w	fill1ea-fillbase
		dc.w	fill1fa-fillbase		
			
		dc.w	fill10b-fillbase
		dc.w	fill11b-fillbase
		dc.w	fill12b-fillbase
		dc.w	fill13b-fillbase
		dc.w	fill14b-fillbase
		dc.w	fill15b-fillbase
		dc.w	fill16b-fillbase
		dc.w	fill17b-fillbase
		dc.w	fill18b-fillbase
		dc.w	fill19b-fillbase
		dc.w	fill1ab-fillbase
		dc.w	fill1bb-fillbase
		dc.w	fill1cb-fillbase
		dc.w	fill1db-fillbase
		dc.w	fill1eb-fillbase
		dc.w	fill1fb-fillbase		
			
		dc.w	fill10c-fillbase
		dc.w	fill11c-fillbase
		dc.w	fill12c-fillbase
		dc.w	fill13c-fillbase
		dc.w	fill14c-fillbase
		dc.w	fill15c-fillbase
		dc.w	fill16c-fillbase
		dc.w	fill17c-fillbase
		dc.w	fill18c-fillbase
		dc.w	fill19c-fillbase
		dc.w	fill1ac-fillbase
		dc.w	fill1bc-fillbase
		dc.w	fill1cc-fillbase
		dc.w	fill1dc-fillbase
		dc.w	fill1ec-fillbase
		dc.w	fill1fc-fillbase		
			
		dc.w	fill10d-fillbase
		dc.w	fill11d-fillbase
		dc.w	fill12d-fillbase
		dc.w	fill13d-fillbase
		dc.w	fill14d-fillbase
		dc.w	fill15d-fillbase
		dc.w	fill16d-fillbase
		dc.w	fill17d-fillbase
		dc.w	fill18d-fillbase
		dc.w	fill19d-fillbase
		dc.w	fill1ad-fillbase
		dc.w	fill1bd-fillbase
		dc.w	fill1cd-fillbase
		dc.w	fill1dd-fillbase
		dc.w	fill1ed-fillbase
		dc.w	fill1fd-fillbase		
			
		dc.w	fill10e-fillbase
		dc.w	fill11e-fillbase
		dc.w	fill12e-fillbase
		dc.w	fill13e-fillbase
		dc.w	fill14e-fillbase
		dc.w	fill15e-fillbase
		dc.w	fill16e-fillbase
		dc.w	fill17e-fillbase
		dc.w	fill18e-fillbase
		dc.w	fill19e-fillbase
		dc.w	fill1ae-fillbase
		dc.w	fill1be-fillbase
		dc.w	fill1ce-fillbase
		dc.w	fill1de-fillbase
		dc.w	fill1ee-fillbase
		dc.w	fill1fe-fillbase		
			
		dc.w	fill10f-fillbase
		dc.w	fill11f-fillbase
		dc.w	fill12f-fillbase
		dc.w	fill13f-fillbase
		dc.w	fill14f-fillbase
		dc.w	fill15f-fillbase
		dc.w	fill16f-fillbase
		dc.w	fill17f-fillbase
		dc.w	fill18f-fillbase
		dc.w	fill19f-fillbase
		dc.w	fill1af-fillbase
		dc.w	fill1bf-fillbase
		dc.w	fill1cf-fillbase
		dc.w	fill1df-fillbase
		dc.w	fill1ef-fillbase
		dc.w	fill1ff-fillbase		
				
fillcolbases:
		dc.l	fillbase
		dc.l	fillbase2
		dc.l	fillbase3
		dc.l	fillbase4
		dc.l	fillbase5
		dc.l	fillbase6
		dc.l	fillbase7

saveregpoly:
				ds.l	4
				
;--------------------------------------------------------------------

cut_buildpolys1:
		lea		polydatasp1,a0
		lea		polycolsdst,a2
		lea		polys,a3
		bsr.w	cut_build1poly
		
		cmpi.w	#1,numplanes
		beq.b	.end

		lea		polydatasp2,a0
		bsr.w	cut_build1poly
		
		cmpi.w	#2,numplanes
		beq.b	.end
		
		lea		polydatasp3,a0
		bsr.w	cut_build1poly
.end:		
		rts
		
;--------------------------------------------------------------------

cut_buildpolys2:
		lea		polydata,a0
		lea		polys,a3
		lea		polycolsdst,a2
		;bra.b	cut_buildpolys
		
;--------------------------------------------------------------------

cut_buildpolys:
		lea		plotsdst,a1
.l0:
		movem.w	(a3)+,d1-d4
		tst.w	d1
		bmi.w	.end
		
		move.w	(a2)+,d0
		bmi.w	.skip
		
		move.w	d0,(a0)+
		
		movem.w	(a1,d1.w),d5-d7
		movem.w	d5-d7,0(a0)
		movem.w	d5-d7,24(a0)
		
		movem.w	(a1,d2.w),d5-d7
		movem.w	d5-d7,6(a0)
		
		movem.w	(a1,d3.w),d5-d7
		movem.w	d5-d7,12(a0)
		
		movem.w	(a1,d4.w),d5-d7
		movem.w	d5-d7,18(a0)
		
		move.w	#$ffff,34(a0)
		adda.w	#36,a0
		
.skip:
		bra.w	.l0
.end:
		move.w	#$ffff,0(a0)
		rts
		
;--------------------------------------------------------------------

cut_build1poly:
		lea		plotsdst,a1
.l0:
		movem.w	(a3)+,d1-d4
		tst.w	d1
		bmi.w	.end
		
		move.w	(a2)+,d0
		bmi.w	.skip
		
		move.w	d0,(a0)+
		
		movem.w	(a1,d1.w),d5-d7
		movem.w	d5-d7,0(a0)
		movem.w	d5-d7,24(a0)
		
		movem.w	(a1,d2.w),d5-d7
		movem.w	d5-d7,6(a0)
		
		movem.w	(a1,d3.w),d5-d7
		movem.w	d5-d7,12(a0)
		
		movem.w	(a1,d4.w),d5-d7
		movem.w	d5-d7,18(a0)
		
		move.w	#$ffff,34(a0)
		adda.w	#36,a0
		
		bra.b	.end
		
.skip:
		bra.w	.l0
.end:
		move.w	#$ffff,0(a0)
		rts

;--------------------------------------------------------------------
		
cut_clippolys:
		lea		polydata,a0
		lea		polydata1,a1
		lea		polydata2,a2
		lea		planes+0*8,a3
		bsr.w	cut_doclip
		
		cmpi.w	#1,numplanes
		beq.w	.end
		
		lea		polydata1,a0
		lea		polydata11,a1
		lea		polydata12,a2
		lea		planes+1*8,a3
		bsr.w	cut_doclip
		
		lea		polydata2,a0
		lea		polydata21,a1
		lea		polydata22,a2
		lea		planes+1*8,a3
		bsr.w	cut_doclip
			
		cmpi.w	#2,numplanes
		beq.w	.end
		
		lea		polydata11,a0
		lea		polydata111,a1
		lea		polydata112,a2
		lea		planes+2*8,a3
		bsr.w	cut_doclip
		
		lea		polydata12,a0
		lea		polydata121,a1
		lea		polydata122,a2
		lea		planes+2*8,a3
		bsr.w	cut_doclip
		
		lea		polydata21,a0
		lea		polydata211,a1
		lea		polydata212,a2
		lea		planes+2*8,a3
		bsr.b	cut_doclip
		
		lea		polydata22,a0
		lea		polydata221,a1
		lea		polydata222,a2
		lea		planes+2*8,a3
		bsr.b	cut_doclip
.end:
		rts
		
;--------------------------------------------------------------------

		cnop	0,4
clippoly1start:
		dc.l	0
clippoly2start:
		dc.l	0
reuse_cut:
		dc.w	0
last_cut:
		dc.w	0

cut_doclip:
.l0:
		move.w	(a0)+,d0
		move.w	d0,(a1)+
		move.w	d0,(a2)+
		bmi.w	.end
		
		move.w	4(a0),d4
		bmi.w	.skippoly		; if first point is end of poly, skip poly (its empty)
		
		move.l	a1,clippoly1start
		move.l	a2,clippoly2start

		clr.w	reuse_cut	
.l1:	
		movem.w	(a0)+,d0-d2
		movem.w	(a0),d3-d5
		
		tst.w	d5
		bmi.w	.skip
	
		tst.w	reuse_cut
		beq.b	.noreuse
.reuse:
		move.w	last_cut(pc),a5
		bra.b	.secondcut
.noreuse:				
		move.w	d0,d7
		muls.w	0(a3),d7
		move.w	d1,d6
		muls.w	2(a3),d6
		add.l	d6,d7
		move.w	d2,d6
		muls.w	4(a3),d6
		add.l	d6,d7
		swap	d7
		add.w	6(a3),d7
		move.w	d7,a5
		
.secondcut:
		addq.w	#1,reuse_cut
		
		move.w	d3,d7
		muls.w	0(a3),d7
		move.w	d4,d6
		muls.w	2(a3),d6
		add.l	d6,d7
		move.w	d5,d6
		muls.w	4(a3),d6
		add.l	d6,d7
		swap	d7
		add.w	6(a3),d7
		move.w	d7,a6
		move.w	d7,last_cut
		
		moveq	#0,d6
		
		move.w	a5,d7
		bmi.b	.noclip11

		addq	#1,d6
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		move.w	d2,(a1)+		;if p1 is inside -> add it to output1
		bra.b	.noclip1
.noclip11:
		move.w	d0,(a2)+
		move.w	d1,(a2)+
		move.w	d2,(a2)+		;else -> add it to output2
.noclip1:

		move.w	a6,d7
		bmi.b	.noclip2
		bchg	#0,d6
.noclip2:
		tst.w	d6
		beq.b	.skipclip		;if states for p1 and p2 are the same no clipping is needed
		
		sub.w	d0,d3			;x2-x1
		sub.w	d1,d4			;y2-y1
		sub.w	d2,d5			;z2-z1
		move.w	a6,d6
		sub.w	a5,d6			;d2-d1
		move.w	a5,d7			
		neg.w	d7				;-d1
		swap	d7
		clr.w	d7
		asr.l	#2,d7
		
		divs.w	d6,d7			;-d1/(d2-d1)
		moveq	#$fffffffe,d6
		
		muls.w	d7,d3			;(x2-x1)*(-d1)
		lsl.l	#2,d3
		swap	d3
		add.w	d3,d0			;x1+(x2-x1)*(-d1)/(d2-d1)
		and.w	d6,d0
	
		muls.w	d7,d4			;(y2-y1)*(-d1)
		lsl.l	#2,d4
		swap	d4
		add.w	d4,d1			;y1+(y2-y1)*(-d1)/(d2-d1)
		and.w	d6,d1

		muls.w	d7,d5			;(z2-z1)*(-d1)
		lsl.l	#2,d5
		swap	d5
		add.w	d5,d2			;z1+(z2-z1)*(-d1)/(d2-d1)
		and.w	d6,d2

		move.w	d0,(a1)+
		move.w	d1,(a1)+
		move.w	d2,(a1)+

		move.w	d0,(a2)+
		move.w	d1,(a2)+
		move.w	d2,(a2)+		;add clippoint to output2
		
.skipclip:
		bra.w	.l1
.skip:	
		clr.w	reuse_cut
		
		move.l	clippoly1start(pc),a5
		cmp.l	a5,a1
		beq.b	.nolastpoint1	;if output1 is not empty, duplicate first point to the end
		
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		subq	#6,a5
.nolastpoint1:		

		move.l	clippoly2start(pc),a5
		cmp.l	a5,a2
		beq.b	.nolastpoint2	;if output1 is not empty, duplicate first point to the end
		
		move.w	(a5)+,(a2)+
		move.w	(a5)+,(a2)+
		move.w	(a5)+,(a2)+
		subq	#6,a5
.nolastpoint2:		

		move.w	d3,(a1)+
		move.w	d4,(a1)+
		move.w	d5,(a1)+
		
		move.w	d3,(a2)+
		move.w	d4,(a2)+
		move.w	d5,(a2)+
		
		addq	#6,a0			;step to next source polygon
		
		bra.w	.l0
.end:
		rts
.skippoly:
		addq	#6,a0			;step to next source polygon
		subq	#2,a1
		subq	#2,a2
		bra.w	.l0

;--------------------------------------------------------------------

cut_drawpolyssplit:
		move.w	numplanes,d0
		cmpi.w	#1,d0
		beq.w	cut_drawpolyssplit1
		cmpi.w	#2,d0
		beq.w	cut_drawpolyssplit2
		bra.w	cut_drawpolyssplit3
	
;--------------------------------------------------------------------

cut_drawpolyssplit1:
		lea		polydata2,a1
		bsr.w	cut_drawpolys
		
		lea		polydatasp1,a1
		bsr.w	cut_drawpolys
	
		lea		polydata1,a1
		bra.w	cut_drawpolys
		
;--------------------------------------------------------------------

cut_drawpolyssplit2:
		lea		polydata22,a1
		bsr.w	cut_drawpolys

		lea		polydatasp2,a1
		bsr.w	cut_drawpolys
		
		lea		polydata21,a1
		bsr.w	cut_drawpolys
		
		lea		polydatasp1,a1
		bsr.w	cut_drawpolys
	
		lea		polydata12,a1
		bsr.w	cut_drawpolys

		lea		polydata11,a1
		bra.w	cut_drawpolys
		
;--------------------------------------------------------------------

cut_drawpolyssplit3:
		lea		polydata222,a1
		bsr.w	cut_drawpolys

		lea		polydatasp3,a1
		bsr.w	cut_drawpolys

		lea		polydata221,a1
		bsr.w	cut_drawpolys

		lea		polydatasp2,a1
		bsr.w	cut_drawpolys
	
		lea		polydata212,a1
		bsr.w	cut_drawpolys

		lea		polydata211,a1
		bsr.w	cut_drawpolys

		lea		polydatasp1,a1
		bsr.w	cut_drawpolys
	
		lea		polydata122,a1
		bsr.w	cut_drawpolys

		lea		polydata121,a1
		bsr.w	cut_drawpolys

		lea		polydata112,a1
		bsr.w	cut_drawpolys

		lea		polydata111,a1
		bra.w	cut_drawpolys
		
;--------------------------------------------------------------------

ZGUARD	= $4600		

		cnop	0,2
cut_coloffset:
		dc.w	0

cut_drawpolys:
		lea		cut_logtab,a5
		lea		cut_exptab2,a6
		lea		2*tf(a5),a2
.l0:
		move.w	(a1)+,d0
		bmi.w	.end
		
		add.w	cut_coloffset(pc),d0
		
		move.w	4(a1),d4
		bmi.b	.skippoly		; if first point is end of poly, skip poly (its empty)
		
		lea		polytmp(pc),a0
		move.l	a0,a3
		
		move.w	xoffsetnopersp(pc),d1
		move.w	#tf*2,d6
		move.w	#ZGUARD,d7
.l1:
		movem.w	(a1)+,d2-d4
		tst.w	d4
		bmi.b	.endpoly
		
		sub.w	d7,d4
		asr.w	#3,d4
		add.w	d4,d4
		
		move.w	(a2,d4.w),d4		; d3=-log(z)
		move.w	d4,d5				; d4=-log(z)
		
		sub.w	(a5,d2.w),d4		; d3+=log(x)
		sub.w	(a5,d3.w),d5		; d4+=log(y)
		
		move.w	(a6,d4.w),d4
		move.w	(a6,d5.w),d5
		add.w	d1,d4
		
		move.w	d4,(a3)+
		move.w	d5,(a3)+
		
		bra.b	.l1
.endpoly:
		move.w	#$ffff,2(a3)
		
		bsr.w	cut_drawpoly

		bra.w	.l0
.end:
		rts
		
.skippoly:
		addq	#6,a1
		bra.b	.l0
		
		cnop	0,2
polytmp:	
		ds.w	20
		
;--------------------------------------------------------------------
			
				cnop	0,2
cut_poly:		ds.w	4	; color, minx, miny, maxy

;a0 - coords (first/last point duplicated, y=-1->end)
;d0 - color
cut_drawpoly:
		movem.l	d0-d7/a0-a6,-(sp)
		move.l	a7,saveregpoly+8

		lea		cut_logtab,a3
		lea		cut_poly,a4
		lea		cut_exptab,a5
		lea		cut_tmp,a6

		move.w	d0,(a4)+
		
		move.l	a0,a1
		
		move.w	(a1)+,d5	;minx
		move.w	(a1)+,d1	;miny
		move.w	d1,d7		;maxy
		
.sortloop:
		move.w	(a1)+,d2
		move.w	(a1)+,d3
		bmi.w	.endsort
		
		cmp.w	d5,d2
		bpl.b	.skipsortx
		move.w	d2,d5
.skipsortx:

		cmp.w	d1,d3
		bpl.b	.skipsorty1
		move.w	d3,d1
.skipsorty1:

		cmp.w	d7,d3
		bmi.b	.skipsorty2
		move.w	d3,d7
.skipsorty2:

		bra.b	.sortloop
.endsort:

		subq	#1,d5
		andi.w	#$1f0,d5
	
		move.w	d5,(a4)+	;(minx-1) & 0x1f0
		move.w	d1,(a4)+	;miny
		move.w	d7,(a4)+	;maxy
		cmp.w	d1,d7
		beq.w	cut_drawpolyend
		
		move.l	a0,a1
		
.lineleftloop:		
		movem.w	(a1),d0-d3
		tst.w	d3
		bmi.w	.endlinesleft
		addq	#4,a1

		CUT_DOLINELEFT
		
		bra.w	.lineleftloop
.endlinesleft:

		move.l	a0,a1
		
.linerightloop:		
		movem.w	(a1),d0-d3
		tst.w	d3
		bmi.w	.endlinesright
		addq	#4,a1

		CUT_DOLINERIGHT
		
		bra.w	.linerightloop
.endlinesright:

		bra.w	cut_dofill
		
cut_drawpolyend:	 	
		move.l	saveregpoly+8(pc),a7
		movem.l	(sp)+,d0-d7/a0-a6
		rts
	
fillbase:
		CUT_FILLSPERCOL 1,0
fillbase2:
		CUT_FILLSPERCOL 2,0
fillbase3:
		CUT_FILLSPERCOL 3,0
fillbase4:
		CUT_FILLSPERCOL 4,0
fillbase5:
		CUT_FILLSPERCOL 5,0
fillbase6:
		CUT_FILLSPERCOL 6,0
fillbase7:
		CUT_FILLSPERCOL 7,1
		
;--------------------------------------------------------------------
		
cut_screens:
		ds.l	4

cut_page:
		lea 	cut_screens(pc),a0
		
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		move.l	$0c(a0),d3
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$0c(a0)
		move.l	d3,$00(a0)
		
		add.l	#cut_COLMOD*1,d1
		move.l	d1,cut_fillregsl+12
		
		move.l	d2,d0

		lea		cut_copperbpl,a6
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		addi.l	#cut_COLMOD*1,d1
		addi.l	#cut_COLMOD*2,d2
		addi.l	#cut_COLMOD*3,d3
		addi.l	#cut_COLMOD*4,d4
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
		move.w	d4,$26(a6)
		swap	d4
		move.w	d4,$22(a6)
		rts

;--------------------------------------------------------------------

		cnop	0,2
cut_sync:
		dc.w	0
		
cut_irq:		
		movem.l	d0-d7/a0-a6,-(sp)
     
		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		jsr		cut_step
	 
		addq.w	#1,cut_sync
	 
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
				cnop	0,2
cut_pal:
	dc.w	$0000,$0737,$0b7b,$0fbf,$0377,$07bb,$0bff,$0000
			
;********************************************************************
			
				section "cut_empty",bss

				cnop	0,2
				ds.b	$8000
cut_exptab:		ds.b	$8000
				
				ds.b	$8000		
jmpoffsets:		ds.b	$8000		

; log2-table: contains y=log2(x)
; negative values are sign corrected to access the negative part of the exp-table
; range: $c000->$3fff
; initcode will copy the negative part in front of the table for easier access
; and multiply it by 2 to get valid word-offsets into the exp-table
				ds.b	$8000
cut_logtab:		ds.b	$8000		
				
				ds.b	$8000
; exp2-table: contains y=x^2
; negative values are sign corrected to fit to the log-table
; range: $c000->$3fff
; table is premultiplied with screen size
; initcode will copy the negative part in front of the table for easier access
; and add the screen-center
cut_exptab2:	ds.b	$8000		
				
				ds.b	$8000
leftrightmasks:	ds.b	$8000	

				ds.b	$400
cut_squaretab9:	
				ds.b	$400
				
linebuf:		ds.w	256*2
plotsdst:		ds.w	numplots*4
plotsdstproj:	ds.w	numplots*4
polycolsdst:	ds.w	numpolys
polydata:		ds.w	numpolys*2*32
polydata1:		ds.w	numpolys*2*32
polydata2:		ds.w	numpolys*2*32
polydata11:		ds.w	numpolys*2*32
polydata12:		ds.w	numpolys*2*32
polydata21:		ds.w	numpolys*2*32
polydata22:		ds.w	numpolys*2*32
polydata111:	ds.w	numpolys*2*32
polydata112:	ds.w	numpolys*2*32
polydata121:	ds.w	numpolys*2*32
polydata122:	ds.w	numpolys*2*32
polydata211:	ds.w	numpolys*2*32
polydata212:	ds.w	numpolys*2*32
polydata221:	ds.w	numpolys*2*32
polydata222:	ds.w	numpolys*2*32
polydatasp1:	ds.w	numpolys*2*32
polydatasp2:	ds.w	numpolys*2*32
polydatasp3:	ds.w	numpolys*2*32
planes:			ds.w	8*numpolys+3
cut_shadeinfo:	ds.w	6*4+2
		
;********************************************************************
			
				section "cut_emptychip",bss,chip

				cnop	0,8
cut_screenbuf:	ds.b	cut_COLMOD*4*4
				
;********************************************************************

				section "cut_copper",data,chip
				
				cnop	0,8
cut_copperlist:
				dc.l	$008e4c81,$00900cc9,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
				
cut_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020033,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080012,$010a0012						;modulo odd planes, modulo even planes
				
				dc.l	$010ffffe								;wait x: 15, y: 1, 
cut_coppernbpl:
				dc.l	$01004200								;turn on 3 bitplanes
cut_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointer
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000

				dc.l	$020ffffe,$009c8010						;wait x: 15, y: 33, start irq
				
				dc.l	$fffffffe 								;wait for end
				
;********************************************************************

cut_sintab:		
	incbin "../data/sinplots/sintab2048.dat"
			;	ds.b	4096
cut_exptabcomp:	
	incbin "../data/vector/exptabcomp.dat"		
cut_exptabcompend:	
	
cut_logtabcomp:	
	incbin "../data/vector/logtabcomp.dat"		
cut_logtabcompend:	
										
cut_exptab2comp:	
	incbin "../data/vector/exptab2comp.dat"		
cut_exptab2compend:	

cut_logo:
	incbin "../data/vector/logo.ami"		
cut_logoend:
cut_logosize = cut_logoend-cut_logo
			ds.b	cut_COLMOD

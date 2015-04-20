FIELD_NUMFRAMES	= 1800

	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

			section	"field_code",code 
			
entrypoint:
		move.l	a6,fw_jumptable
		
		bsr.w	field_init
				
		bsr.w	field_page
		
		move.w	#TIME_STARFIELD_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#field_copperlist,a0
		move.l	#field_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
			
		jsr		GETFRAME(a6)
		addi.w	#FIELD_NUMFRAMES,d0
		move.w	d0,field_endframe

field_main:
		;move.w	#$0008,$dff180
		bsr.w	field_clear
		bsr.w	field_plot
		bsr.w	field_fadecol
		bsr.w	field_page
		bsr.w	field_movesprites
		bsr.w	field_updatefadespr
		bsr.w	field_updateline
		;move.w	#$000,$dff180
		;bsr.w	vsync
.sync:
		tst.w	field_sync
		beq.b	.sync
		clr.w	field_sync
		
		btst	#$06,$bfe001
		beq.b	field_end
		
		move.w	field_endframe,d0
		move.l	fw_jumptable(pc),a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	field_main
field_end:
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		
		move.w	#$0020,$dff096		;turn off sprite dma
		rts		
		
		cnop	0,4
fw_jumptable:
		dc.l	0
field_endframe:
		dc.w	0
		
;--------------------------------------------------------------------
		
field_init:
		bsr.w	field_initpal
		bsr.w	field_initrnd
		bsr.w	field_initfield
		bsr.w	field_initfade
		bsr.w	field_gencode
		bsr.w	field_convexptab
		bsr.w	field_convlogtab
		bsr.w	field_inittexts
		moveq	#0,d0
		bsr.w	field_settext
		
		lea		field_sintab,a0
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
		
		lea		$dff1a0,a2
		moveq	#16-1,d7
.sl1:
		clr.w	(a2)+
		dbra	d7,.sl1
		
		bsr.w	initsprites
		rts

;--------------------------------------------------------------------

initsprites:
		lea		field_satellite,a0
		lea		field_sprites,a1

		moveq	#8-1,d7
.l1:
		move.l	(a1)+,a2
		addq	#4,a2
		moveq	#64*2-1,d6
.l2:
		move.w	(a0)+,(a2)+
		dbra	d6,.l2
		
		dbra	d7,.l1
		rts

;--------------------------------------------------------------------

field_convexptab:		
		lea		field_exptabcomp,a0
		lea		field_exptabcompend-2,a6
		lea		field_exptabx,a1
		lea		field_exptaby,a2
	
		move.l	#$1fffc,d5
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
		
		move.w	d0,d4
		
		addi.w	#128,d4
		bpl.b	.cliptop
		moveq	#0,d4
.cliptop:
		cmpi.w	#256,d4
		blt.b	.clipbottom
		moveq	#0,d4
.clipbottom:

		addi.w	#160,d0
		bpl.b	.clipleft
		moveq	#0,d0
.clipleft:
		cmpi.w	#320,d0
		blt.b	.clipright
		moveq	#0,d0
.clipright:

		move.w	d0,d6
		not.w	d0
		lsr.w	#3,d6
		lsl.w	#6,d4
		
		move.l	d5,d7
		lsr.l	#1,d7
		andi.w	#$fffc,d7
		addq	#2,d7
		
		move.w	d0,(a1,d7.w)
		move.w	d4,(a2,d7.w)
		subq	#2,d7
		
		move.w	d6,(a1,d7.w)
		move.w	d4,(a2,d7.w)
		
		subq.l	#4,d5
	
		add.l	d3,d1
		
		dbra	d2,.l1		
		
		cmp.l	a0,a6
		bne.b	.l0
.end:
		rts
		
;--------------------------------------------------------------------

field_convlogtab:	
		lea		field_logtabcomp,a0
		lea		field_logtab,a1
		lea		field_logtabcompend-2,a6
		
		moveq	#$0,d5		
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
		add.w	d0,d0
		andi.w	#$fffc,d0
		move.w	d0,(a1,d5.w)
		addq	#2,d5
	
		add.l	d3,d1
		
		dbra	d2,.l1		
		
		cmp.l	a0,a6
		bne.b	.l0
.end:
		rts
		
;--------------------------------------------------------------------

field_initpal:
		lea		$dff180,a1

		clr.w	d0
		moveq	#8-1,d7
.l0:	
		move.w	d0,(a1)+
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

field_initrnd:
		lea     field_rndtab,a0
        move.l  #12345678,d0
        move.w  #NUMPLOTS*3-1,d7
.l0:    
		divu.w  #4433,d0
        move.w  d0,(a0)+
        dbra    d7,.l0
        rts
		
;--------------------------------------------------------------------

field_initfield:
		lea     field_rndtab,a0
		lea     field_points,a1
		move.w  #NUMPLOTS-1,d7
.l0:
		move.w  (a0)+,d0
		andi.w  #$3f,d0
		cmpi.w	#$20,d0
		bne.b	.nocenter	;if the plot in x is directly in the center, move it 1 to the right. otherwise we only get a blinking dot in the first phase.
		addq	#1,d0
.nocenter:
		add.w	d0,d0
		
		move.w  (a0)+,d1
		andi.w  #$3f,d1
		add.w	d1,d1
		
		move.w  (a0)+,d2
		andi.w  #$3f,d2
		add.w	d2,d2
		
		move.w  d0,(a1)+
		move.w  d1,(a1)+
		move.w  d2,(a1)+

		dbra    d7,.l0
		rts

;--------------------------------------------------------------------

field_gencode:
		lea		field_plotcode,a0
		lea		field_points,a3
		move.w	#NUMPLOTS-1,d7
.l0:
		move.l	a0,a2
		
		lea		.template,a1
		moveq	#(.templateend-.template)/2-1,d6
.l1:
		move.w	(a1)+,(a0)+
		dbra	d6,.l1

		movem.w	(a3)+,d0-d2
		
		move.w	d0,d3
		move.w	d1,d4
		move.w	d2,d5
		add.w	d3,d3
		add.w	d4,d4
		add.w	d5,d5
		addi.w	#256*0,d3
		addi.w	#256*3,d4
		addi.w	#256*6,d5
		move.w	d3,(.off1-.template)+2(a2)
		move.w	d4,(.off2-.template)+2(a2)
		move.w	d5,(.off3-.template)+2(a2)
		move.w	d0,d3
		move.w	d1,d4
		move.w	d2,d5
		addi.w	#256*2,d3
		addi.w	#256*5,d4
		addi.w	#256*8,d5
		move.w	d3,(.off4-.template)+2(a2)
		move.w	d4,(.off5-.template)+2(a2)
		move.w	d5,(.off6-.template)+2(a2)
		
		dbra	d7,.l0
		
		move.w	#$4e75,(a0)+	;rts
		rts

FIELD_PLOTCODESIZE	= .templateend-.template
		
.template:
.off1:
		move.l	1234(a1),d0
.off2:
		add.l	1234(a1),d0
.off3:
		add.l	1234(a1),d0
	
.off4:
		move.w	1234(a1),d2
.off5:
		add.w	1234(a1),d2
.off6:
		add.w	1234(a1),d2
	
		move.w	(a2,d2.w),d5		; -log(z)
		move.w	d5,d3				; -log(z)

		sub.w	(a2,d0.w),d5		; +=log(x)
		swap	d0
		and.w	d1,d0
		sub.w	(a2,d0.w),d3		; +=log(y)
				
		movem.w	(a5,d5.w),d0/d5
		add.w	(a3,d3.w),d0
		and.w	d7,d2
		add.w	d2,d0
		
		bset.b	d5,(a6,d0.l)
.templateend:		

;--------------------------------------------------------------------

		cnop	0,4
field_coppermuxs:
		dc.l	field_coppermux1
		dc.l	field_coppermux2
		dc.l	field_coppermux3
		dc.l	field_coppermux4
		dc.l	field_coppermux5
		dc.l	field_coppermux6
		dc.l	field_coppermux7
		dc.l	field_coppermux7
		
field_text:
		dc.b	0,"  axis  "
		dc.b	8," faker  "
		dc.b	8," yazoo  "
		dc.b	8," alien  "
		dc.b	0," nytrik "
		dc.b	8," fanta  "
		dc.b	0,"        "		

		cnop	0,2
		
field_settext:
		lea		field_copperjmp+2,a0
		lea		field_coppermuxs(pc),a1
		move.l	(a1,d0.w),d0
		cmp.l	field_coppermux7,d0
		move.w	d0,4(a0)
		swap	d0
		move.w	d0,(a0)
		rts

;--------------------------------------------------------------------

		cnop	0,4
texpoi:
		dc.l	field_text

field_inittexts:
		lea		field_coppermux1,a0
		bsr.w	field_inittext
		lea		field_coppermux2,a0
		bsr.w	field_inittext
		lea		field_coppermux3,a0
		bsr.w	field_inittext
		lea		field_coppermux4,a0
		bsr.w	field_inittext
		lea		field_coppermux5,a0
		bsr.w	field_inittext
		lea		field_coppermux6,a0
		bsr.w	field_inittext
		
		lea		field_coppermux7,a0
		lea		field_sprites,a1
		lea		field_satpal,a2
		
		move.w	#$0120,d0
		moveq	#8-1,d7
.l0:
		move.l	(a1)+,d1

		move.w	d0,(a0)+
		addq	#2,d0
		swap	d1
		move.w	d1,(a0)+
		
		move.w	d0,(a0)+
		addq	#2,d0
		swap	d1
		move.w	d1,(a0)+

		dbra	d7,.l0

		move.w	#$01a0,d0
		moveq	#16-1,d7
.l1:
		move.w	d0,(a0)+
		move.w	(a2)+,(a0)+
		addq	#2,d0
		
		dbra	d7,.l1

		move.w	#$0096,(a0)+
		move.w	#$8020,(a0)+		;turn on sprite dma
		
		move.l	#$ffdffffe,(a0)+	; wait line 256
		move.l	#$280ffffe,(a0)+	; wait line 296
		move.l	#$009c8010,(a0)+	; start irq
		move.l	#$fffffffe,(a0)+	; end coplist
		rts
		
;--------------------------------------------------------------------

sprcenter 	= $9d8c		
sprstep		= 16
		
field_inittext:
		lea		field_font-12,a1		;correctpointer by 2 lines, because we dont display the first 2 lines
				
		move.l	#$990ffffe,(a0)+
		move.l	#$010a0000,(a0)+
				
		move.l	#$9cd7fffe,d0
		
		moveq	#35-1,d7
.l0:			
		move.l	d0,(a0)+
	
		move.l	texpoi(pc),a2
		moveq	#0,d2
		move.b	(a2)+,d2
		
		move.w	#$0140,d1
		add.w	#sprcenter-sprstep*4+sprstep/2,d2
		moveq	#sprstep,d5
		cmpi.w	#32,d7
		blt.b	.fix				;hide the first 2 lines of the sprites, because the display only dma-trash
		move.w	#$9dfc,d2
		moveq	#0,d5
.fix:
		moveq	#0,d4
		
		moveq	#8-1,d6
.l1:
		move.b	(a2),d4
		andi.w	#$1f,d4
		mulu.w	#34*8,d4
		add.w	d3,d4

		move.w	d1,(a0)+
		addq	#4,d1
		move.w	d2,(a0)+
		
		move.w	d1,(a0)+
		addq	#2,d1
		move.w	(a1,d4.w),(a0)+
		
		move.w	d1,(a0)+
		addq	#2,d1
		move.w	2(a1,d4.w),(a0)+
		
		eori.w	#$88,d3
		
		btst	#0,d6
		bne.b	.l2
		add.w	d5,d2
		addq	#1,a2
.l2:		
		dbra	d6,.l1

		addq	#4,a1
		
		move.w	#$0140,d1
		moveq	#0,d3
		
		moveq	#8-1,d6
.l3:
		move.b	(a2),d4
		andi.w	#$1f,d4
		mulu.w	#34*8,d4
		add.w	d3,d4

		move.w	d1,(a0)+
		addq	#4,d1
		move.w	d2,(a0)+
		
		move.w	d1,(a0)+
		addq	#2,d1
		move.w	(a1,d4.w),(a0)+
		
		move.w	d1,(a0)+
		addq	#2,d1
		move.w	2(a1,d4.w),(a0)+
		
		eori.w	#$88,d3
		
		btst	#0,d6
		bne.b	.l4
		add.w	d5,d2
		addq	#1,a2
.l4:		
		dbra	d6,.l3
	
		addi.l	#$01000000,d0
		
		dbra	d7,.l0

		move.l	#$c50ffffe,(a0)+
		move.l	#$010affd8,(a0)+

		move.l	#$ffdffffe,(a0)+	; wait line 256
		move.l	#$280ffffe,(a0)+	; wait line 296
		move.l	#$009c8010,(a0)+	; start irq
		move.l	#$fffffffe,(a0)+	; end coplist
	
		add.l	#9,texpoi
		rts
		
;--------------------------------------------------------------------

field_initfade:
		lea		field_fadedat,a1
		moveq	#1,d7
.l0:
		lea		field_sprpal,a0
		moveq	#16-1,d6
.l1:		
		move.w	(a0)+,d0
		move.w	d0,d1
		move.w	d0,d2
		andi.w	#$f00,d0
		andi.w	#$0f0,d1
		andi.w	#$00f,d2
		mulu.w	d7,d0
		mulu.w	d7,d1
		mulu.w	d7,d2
		lsr.w	#4,d0
		lsr.w	#4,d1
		lsr.w	#4,d2
		andi.w	#$f00,d0
		andi.w	#$0f0,d1
		andi.w	#$00f,d2
		or.w	d1,d0
		or.w	d2,d0
		move.w	d0,(a1)+
		
		dbra	d6,.l1
		
		addq	#1,d7
		cmpi.w	#17,d7
		bne.b	.l0
		rts
		
;--------------------------------------------------------------------

field_clear:
		move.l	field_screens+0,a0
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTAFWM(a6)
		clr.w	BLTADAT(a6)
		move.w	#24,BLTDMOD(a6)
		move.l  a0,BLTDPTR(a6)
		move.l	#$01f00000,BLTCON0(a6)
		move.w  #$8014,BLTSIZE(a6)
		;bsr.w	bltwait
		rts

;--------------------------------------------------------------------

NUMPLOTS	= 470
tf			= 8000

			cnop 0,2
field_frame:dc.w	0
field_rx:	dc.w 	$00
field_ry:	dc.w 	$00
field_rz:	dc.w 	$00
field_stepx:dc.w	0
field_stepy:dc.w	0
field_stepz:dc.w	0
field_z:	dc.w	0
field_tmps:	ds.w	3
field_mat:	ds.w 	9

field_plot:
		addq.w	#1,field_frame
		
		move.w	field_frame,d0
		cmpi.w	#256,d0
		bne.b	.noevent1
		move.w	#$8,field_stepz
.noevent1:
		cmpi.w	#512,d0
		bne.b	.noevent2
		move.w	#$2,field_stepx
		move.w	#$4,field_stepy
.noevent2:
		cmpi.w	#1365,d0
		bne.b	.noevent3
		clr.w	field_stepx
		clr.w	field_stepy
		clr.w	field_stepz
.noevent3:
		move.w	field_z(pc),d0
		subq	#2,d0
		andi.w	#$7e,d0
		move.w	d0,field_z
		
		move.w	field_rx(pc),d0
		add.w	field_stepx(pc),d0
		andi.w	#$ffe,d0
		move.w	d0,field_rx

		move.w	field_ry(pc),d1
		add.w	field_stepy(pc),d1
		andi.w	#$ffe,d1
		move.w	d1,field_ry
		
		move.w	field_rz(pc),d2
		add.w	field_stepz(pc),d2
		andi.w	#$ffe,d2
		move.w	d2,field_rz
		
		lea		field_sintab,a0
		lea		field_sintab+$400,a1
		lea		field_tmps,a2
		lea		field_mat,a3

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
		lsl.l	#1,d6
		swap	d6
		move.w	d6,0(a3)		;cy*cz

		move.w	d1,d6
		muls.w	d5,d6			
		lsl.l	#1,d6
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
		lsl.l	#1,d6
		swap	d6
		move.w	d6,10(a3)		;sx*cy
		
		move.w	4(a2),d6
		muls.w	d4,d6			
		move.w	d3,d7
		muls.w	d5,d7			
		sub.l	d7,d6
		lsl.l	#1,d6
		swap	d6
		move.w	d6,12(a3)		;c*sy-sx*sz
		
		move.w	2(a2),d6
		muls.w	d4,d6			
		move.w	d3,d7
		muls.w	d2,d7			
		add.l	d7,d6
		lsl.l	#1,d6
		swap	d6
		move.w	d6,14(a3)		;b*sy+sx*cz
	
		move.w	d0,d6
		muls.w	d1,d6			
		lsl.l	#1,d6
		swap	d6
		neg.w	d6
		move.w	d6,16(a3)		;-cx*cy

		lea		field_mat,a1
		lea		field_lerptab,a2
		
		bsr.w	dolerpxy
		
		moveq	#0,d2
		bsr.w	dolerpz
		
		bsr.w	dolerpxy
		
		moveq	#0,d2
		bsr.w	dolerpz
		
		adda.w	field_z(pc),a2
		adda.w	field_z(pc),a2
		bsr.w	dolerpxy
		
		suba.w	field_z(pc),a2
		move.w	#tf*2,d2
		bsr.w	dolerpz		
		
		lea		field_lerptab+256*6,a0
		lea		256(a0),a1
		lea		256(a1),a2
		lea		128(a2),a3
		move.w	field_z(pc),d7
		lsr.w	#1,d7
		subq	#1,d7
		bmi.b	.skip
.l2:
		move.l	(a1)+,(a0)+
		move.w	(a3)+,(a2)+
		dbra	d7,.l2
.skip:
				
		lea		field_lerptab,a1
		move.l	field_screens+4,a6
		lea		field_logtab,a2
		lea		field_exptabx,a5
		lea		field_exptaby,a3
		
		moveq	#0,d0
		move.w	#$c000,d7
		move.w	#$fffe,d1
		jmp		field_plotcode
		
dolerpxy:
		move.l	#$80000000,d0
		move.l	#$80000000,d4
		
		move.w	(a1)+,d0
		move.w	(a1)+,d4
		move.w	d0,d1
		move.w	d4,d5
		neg.w	d0
		neg.w	d5
		sub.w	d0,d1
		sub.w	d4,d5
		swap	d1
		swap	d5
		clr.w	d1
		clr.w	d5
		asr.l	#6,d1
		asr.l	#6,d5
		swap	d1
		swap	d4

		move.l	d4,a4
		
		add.w	#0,d0
		move.l	#$fffefffe,d2
		
		REPT	64
		move.l	a4,d3
		move.w	d0,d3
		and.l	d2,d3
		move.l	d3,(a2)+
		addx.l	d1,d0
		add.l	d5,a4
		ENDR
		
		lea		256(a2),a2
		rts
		
dolerpz:
		move.l	#$80000000,d0
		move.w	(a1)+,d0
		move.w	d0,d1
		neg.w	d0
		sub.w	d0,d1
		swap	d1
		clr.w	d1
		asr.l	#6,d1
		swap	d1
				
		add.w	d2,d0
.bla2:		
		add.w	#0,d0
		moveq	#$fffffffe,d2
		
		REPT	64
		move.w	d0,d3
		and.w	d2,d3
		move.w	d3,(a2)+
		addx.l	d1,d0
		ENDR
		
		lea		128(a2),a2		
		rts
		
;--------------------------------------------------------------------

field_screens:
		dc.l	field_screen1,field_screen2,field_screen3

field_page:
		lea 	field_screens,a0

		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)

		move.l	#field_lineplane,d2
	
		lea		field_copperbpl,a6
		
		move.l	d1,d0
		addi.l	#64,d0
		
		move.l	d0,d1
		addi.l	#$4000,d0
		
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)

		move.w	d2,$0e(a6)
		swap	d2
		move.w	d2,$0a(a6)
		
		move.w	d1,$16(a6)
		swap	d1
		move.w	d1,$12(a6)
		rts

;--------------------------------------------------------------------
		
 MACRO<FADECOL>
 		move.w	(a0)+,d0
		sub.w	d6,d0
		bpl.b	.clamp\@
		moveq	#0,d0
.clamp\@:
		add.w	d0,d0
		move.w	(a1,d0.w),\1*2(a2)
 ENDM
		
		cnop	0,2
field_fadeframe:
		dc.w	0
field_fadetab:
		dc.w	$0000,$0111,$0222,$0333,$0444,$0555,$0666,$0777
		dc.w	$0888,$0999,$0aaa,$0bbb,$0ccc,$0ddd,$0eee,$0fff
field_pal:
		dc.w	$00,$08,$0f,$0f
		
field_fadecol:
		addq.w	#1,field_fadeframe
		
		move.w	field_fadeframe(pc),d6
		cmpi.w	#32,d6
		bgt.b	.fadeout
		
		sub.w	#32,d6
		neg.w	d6
		bpl.b	.clipfront
		moveq	#0,d6
.clipfront:
		lsr.w	#1,d6
		bsr.w	.dofade
		rts
		
.fadeout:
		sub.w	#FIELD_NUMFRAMES-32,d6
		bpl.b	.clipback
		moveq	#0,d6
.clipback:
		bsr.w	.dofade
		rts
		
.dofade:
		lea		field_pal,a0
		lea		field_fadetab,a1
		lea		$dff180,a2
		FADECOL 0
		FADECOL 1
		FADECOL 4
		FADECOL 5		
		rts

;--------------------------------------------------------------------

		cnop	0,4
field_spritex:
		dc.l	160*65536
field_spritey:
		dc.l	0*65536
field_spritexspeed:
		dc.l	300*256*2
field_spriteyspeed:
		dc.l	250*256*2

field_movesprites:
		move.w	field_fadeframe(pc),d0
		subi.w	#FIELD_NUMFRAMES-200,d0
		blt.w	.skip

		move.w	#$0038,field_copperprio+2
	
		move.l	field_spritex(pc),d0
		move.l	field_spritexspeed(pc),d1
		move.l	field_spritey(pc),d2
		move.l	field_spriteyspeed(pc),d3
		sub.l	d1,d0
		add.l	d3,d2
		sub.l	#1300,d1
		bpl.b	.noright
		moveq	#0,d1
.noright:
		sub.l	#500,d3
		move.l	d0,field_spritex
		move.l	d1,field_spritexspeed
		move.l	d2,field_spritey
		move.l	d3,field_spriteyspeed
		
		swap	d0
		swap	d2
		exg		d0,d2
		
		lea		field_sprites,a0

		cmpi.w	#10,d0
		bgt.b	.clamp1
		moveq	#10,d0
.clamp1:
		cmpi.w	#190,d0
		blt.b	.clamp2
		move.w	#190,d0
.clamp2:
		move.w	d2,d3
		move.w	d3,d4
		
		move.w	d4,d3
		add.w	d3,d3
		add.w	d4,d3
		
		addi.w	#20,d0
		
		tst.w	d3
		bpl.b	.clip
		moveq	#0,d3
.clip:
		move.w	#$80,d2
		asr.w	#1,d3
		bcc.b	.lobit
		addq	#1,d2
.lobit:

		move.w	d0,d1
		addi.w	#64,d1
	
		moveq	#4-1,d7
.l0:
		move.l	(a0)+,a1
		move.b	d0,0(a1)
		move.b	d3,1(a1)
		move.b	d1,2(a1)
		move.b	d2,3(a1)
		
		move.l	(a0)+,a1
		move.b	d0,0(a1)
		move.b	d3,1(a1)
		move.b	d1,2(a1)
		move.b	d2,3(a1)

		addq	#8,d3
		
		dbra	d7,.l0
.skip:		
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
field_sprfadeframe:
		dc.w	0
field_sprfadewave:
		dc.w	0
		
field_updatefadespr:
		move.w	field_fadeframe(pc),d0
		cmp.w	#FIELD_NUMFRAMES-200,d0
		bgt.w	.skip

		move.w	field_sprfadeframe(pc),d1
		addq	#1,d1
		move.w	d1,field_sprfadeframe
		cmpi.w	#266,d1
		blt.b	.nonew
		clr.w	field_sprfadeframe
		addq.w	#4,field_sprfadewave
		move.w	field_sprfadewave(pc),d0
		bsr.w	field_settext
.nonew:
		move.w	field_sprfadeframe(pc),d0
		cmpi.w	#137,d0
		blt.b	.noneg
		neg.w	d0
		addi.w	#244,d0
.noneg:
		subi.w	#$10,d0
		bpl.b	.noclip
		moveq	#0,d0
.noclip:
		lsr.w	#2,d0
		cmpi.w	#$0f,d0
		blt.b	.noclamp
		moveq	#$0f,d0
.noclamp:
		lsl.w	#5,d0
		lea		field_fadedat,a0
		adda.w	d0,a0

		move.w	#$0038,d1
		
		move.w	$06(a0),d0
		lea		$dff180,a1
		move.w	d0,4(a1)
		move.w	d0,6(a1)
		move.w	d0,12(a1)
		
		bne.b	.prio
		moveq	#0,d1
.prio:

		move.w	d1,field_copperprio+2
		
		lea		$dff1a0,a1
		moveq	#16/2-1,d7
.l0:
		move.l	(a0)+,(a1)+
		dbra	d7,.l0
		
.skip:
		rts
		
;--------------------------------------------------------------------

		cnop	0,4
field_lines:
		dc.l	field_line4
		dc.l	field_line5
		dc.l	field_line5
		dc.l	field_line5
		dc.l	field_line6
		dc.l	field_line5
		dc.l	field_line5
		
field_updateline:
		move.w	field_sprfadewave(pc),d1
		
		lea		field_lines,a2
	
		move.l	(a2,d1.w),a0
		lea		field_lineplane+40*1,a1
		lea		field_lineplane+40*43-2,a3
	
		move.w	field_sprfadeframe(pc),d0
		cmpi.w	#160,d0
		blt.b	.noneg
		subq	#2,a1
		addq	#2,a3
		subi.w	#160-33,d0
.noneg:
		subi.w	#33,d0
		cmpi.w	#127,d0
		blt.b	.noclamp
		moveq	#127,d0
.noclamp:
		eori.w	#127,d0
		lsr.w	#3,d0
		ror.w	#4,d0
		ori.w	#$09f0,d0
		
		move.l	fw_jumptable(pc),a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTAFWM(a6)
		clr.w	BLTADAT(a6)
		clr.w	BLTAMOD(a6)
		clr.w	BLTDMOD(a6)
		move.l  a0,BLTAPTR(a6)
		move.l  a1,BLTDPTR(a6)
		move.w	d0,BLTCON0(a6)
		move.w  #$0054,BLTSIZE(a6)
		
		move.l	(a2,d1.w),a0
		
		move.l	fw_jumptable(pc),a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTAFWM(a6)
		clr.w	BLTADAT(a6)
		clr.w	BLTAMOD(a6)
		clr.w	BLTDMOD(a6)
		move.l  a0,BLTAPTR(a6)
		move.l  a3,BLTDPTR(a6)
		eori.w	#$f000,d0
		move.w	d0,BLTCON0(a6)
		move.w  #$0054,BLTSIZE(a6)
		rts

;--------------------------------------------------------------------

		cnop	0,2
field_sync:
		dc.w	0
		
field_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		
		addq.w	#1,field_sync
	
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  		
			
		cnop	0,4
field_sprites:
		dc.l	field_sprite1
		dc.l	field_sprite2
		dc.l	field_sprite3
		dc.l	field_sprite4
		dc.l	field_sprite5
		dc.l	field_sprite6
		dc.l	field_sprite7
		dc.l	field_sprite8
		
;********************************************************************
		
				section "field_data",data

				cnop	0,2
field_sintab:		
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096
									
field_exptabcomp:	
	incbin "../data/starfield/exptabcomp.dat"		
field_exptabcompend:
				
field_logtabcomp:	
	incbin "../data/starfield/logtabcomp.dat"	
field_logtabcompend:

field_font:		
				ds.b	$110
	incbin "../data/starfield/font.dat"
	
field_sprpal:
	incbin "../data/starfield/pal.dat"
		
field_satpal:	
	incbin "../data/starfield/satpal.dat"

field_satellite:
	incbin "../data/starfield/satsprites.dat"	
	
;********************************************************************
			
				section "field_empty",bss

				cnop	0,2
field_rndtab:	
				ds.w	NUMPLOTS*3
field_points:	
				ds.w	NUMPLOTS*3
field_lerptab:
				ds.w	128*9
field_fadedat:
				ds.w	16*16

field_plotcode:
				ds.w	NUMPLOTS*FIELD_PLOTCODESIZE+1
				
; log2-table: contains y=log2(x)
; negative values are sign corrected to access the negative part of the exp-table
; range: $c000->$3fff
; initcode will copy the negative part in front of the table for easier access
; and multiply it by 2 to get valid word-offsets into the exp-table
				ds.b	$8000
field_logtab:	ds.b	$8000

; exp2-table: contains y=x^2
; negative values are sign corrected to fit to the log-table
; range: $c000->$3fff
; table is premultiplied with screen size
; initcode will copy the negative part in front of the table for easier access
; and add the screen-center
				ds.b	$8000
field_exptabx:	ds.b	$8000
				ds.b	$8000
field_exptaby:	ds.b	$8000

;********************************************************************
			
				section "field_emptychip",bss,chip
				
				cnop	0,8
field_screen1:	ds.b	$4000*4
field_screen2:	ds.b	$4000*4
field_screen3:	ds.b	$4000*4
field_lineplane:ds.b	46*40

;********************************************************************

				section "field_copper",data,chip

field_copperlist:
				dc.l	$008e2c82,$00902ac1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

field_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;3 bitplane pointer
				dc.l	$00e80000,$00ea0000
				
				dc.l	$01000200,$01020000						;bplcon mode, scroll values
field_copperprio:		
				dc.l	$01040038			 					;bplcon prios
				dc.l	$01080018,$010affd8						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01003200						;wait x: 15, y: 1, turn on 3 bitplanes
					
				dc.l	$01440000,$01460000
				dc.l	$014c0000,$014e0000
				dc.l	$01540000,$01560000
				dc.l	$015c0000,$015e0000
				dc.l	$01640000,$01660000
				dc.l	$016c0000,$016e0000
				dc.l	$01740000,$01760000
				dc.l	$017c0000,$017e0000
				dc.l	$01409d00,$0142bd00
				dc.l	$01489d00,$014abd80
				dc.l	$01509d00,$0152bd00
				dc.l	$01589d00,$015abd80
				dc.l	$01609d00,$0162bd00
				dc.l	$01689d00,$016abd80
				dc.l	$01709d00,$0172bd00
				dc.l	$01789d00,$017abd80

field_copperjmp:
				dc.l	$00840000,$00860000,$008a0000	; dispatch to multiplexer
				
;--------------------------------------------------------------------

				cnop	0,2
field_line4:
				ds.b	13
				blk.b	14,$ff
				ds.b	13
field_line5:
				ds.b	11
				blk.b	18,$ff
				ds.b	11
				
field_line6:
				ds.b	 9
				blk.b	22,$ff
				ds.b	 9

				cnop	0,8
field_sprite1:
				dc.w	$aeef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64

				cnop	0,8
field_sprite2:
				dc.w	$aeef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64

				cnop	0,8
field_sprite3:
				dc.w	$2eef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64

				cnop	0,8
field_sprite4:
				dc.w	$2eef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64
				
				cnop	0,8
field_sprite5:
				dc.w	$2eef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64
				
				cnop	0,8
field_sprite6:
				dc.w	$2eef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64
				
				cnop	0,8
field_sprite7:
				dc.w	$2eef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64
				
				cnop	0,8
field_sprite8:
				dc.w	$2eef,$6e81             ;VSTART, HSTART, VSTOP
				ds.l	64
				
;--------------------------------------------------------------------

field_coppermux1:
				blk.l	35*50,$01800000+8
field_coppermux2:
				blk.l	35*50,$01800000+8
field_coppermux3:
				blk.l	35*50,$01800000+8
field_coppermux4:
				blk.l	35*50,$01800000+8
field_coppermux5:
				blk.l	35*50,$01800000+8
field_coppermux6:
				blk.l	35*50,$01800000+8
field_coppermux7:
				blk.l	35*50,$01800000+8
		
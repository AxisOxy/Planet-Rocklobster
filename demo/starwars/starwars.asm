STAR_NUMTEXTLINES	= 12
STAR_NUMCHARWIDTH	= 9
STAR_FONTHEIGHT		= 16
STAR_NUMBPLS		= 3
STAR_LINEWIDTH		= 40
STAR_LINEWIDTH1		= 40
STAR_LINEWIDTH2		= 40
STAR_LINEWIDTH3		= 36
STAR_LINEWIDTH4		= 36
STAR_LINEWIDTH5		= 32
STAR_LINEWIDTH6		= 32
STAR_LINEWIDTH7		= 28
STAR_LINEWIDTH8		= 28
STAR_LINEWIDTH9		= 24
STAR_NUMTEMPLATES	= 88

USE_CUSTOM_ALLOC = 1
CHIPMEM_SIZE = 200000
FASTMEM_SIZE = 4


	include "../framework/framework.i"	
	include "../framework/hardware.i"	
	include "../launcher/timings.asm"	
			
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

	
			section	"star_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable

		;shut down floppy motor, if we are in the trackmo. because this is the end part!
	ifd _DEMO
		jsr		EXITLOADER(a6)
	endc ;_DEMO
		
		bsr.w	star_init
		bsr.w	star_updatecopper

		lea		star_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		move.w	#TIME_STARWARS_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
	
		move.l	#star_copperlist,a0
		move.l	#star_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)

star_main:
		tst.w	star_move
		beq.b	star_main
		
		bsr.w	star_updatemap
		
		btst	#$06,$bfe001
		bne.b	star_main

		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
 		rts		
		
		cnop	0,4
fw_jumptable:
		dc.l	0
		
;--------------------------------------------------------------------

		cnop	0,4
star_screen:
		dc.l	0

star_init:
		move.l	fw_jumptable(pc),a6
		jsr		BLTWAIT(a6)
		lea		$dff000,a5
		clr.w	BLTCON1(a5)

		move.l	fw_jumptable(pc),a6
		jsr		SWITCHMEMMODE(a6)
		move.l	fw_jumptable(pc),a6
		jsr		FREEALL(a6)
		move.l	fw_jumptable(pc),a6
		jsr		SWITCHMEMMODE(a6)
		
		move.l	#STAR_SCREENSIZE,d0
		move.l	fw_jumptable(pc),a6
		jsr		ALLOC_CHIP(a6)
		
		move.l	a0,star_screen

		moveq	#0,d0
		move.w	#STAR_SCREENSIZE/4-1,d7
.l0:
		move.l	d0,(a0)+
		dbra	d7,.l0
		
		lea		star_sintab,a0
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
		
		bsr.w	star_initpal
		bsr.w	star_genrotation
		bsr.w	star_gentabs
		moveq	#0,d1
		bsr.w	star_initscreen
		bsr.w	star_inittemplates
		bsr.w	star_initcopper
		rts
		
;--------------------------------------------------------------------

star_initpal:
		lea		star_shadetab+$100,a0
		lea		$dff180,a1
		moveq	#8-1,d7
.l0:	
		move.w	(a0)+,(a1)+
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

au	= 100
tf	= $680

		cnop	0,2
rot:
		dc.w	$7f0
points:
		ds.w	2*3
dstpoints:
		ds.w	2*3
		
star_genrotation:
		lea		star_lineshades,a4
		lea		star_linevs,a5
		lea		star_linewidths,a6

		move.w	#256-1,d7
.ll0:
		move.w	d7,-(sp)
		
		bsr.w	.rotframe
		
		lea		256(a5),a5
		lea		256(a6),a6
		addq	#2,a4
		
		move.w	(sp)+,d7
		dbra	d7,.ll0
		rts

.rotframe:
		move.w	rot(pc),d0
		addi.w	#$10,d0
		andi.w	#$ffe,d0
		move.w	d0,rot
		
		lea		star_sintab,a0
		move.w	(a0,d0.w),d1	;y1
		addi.w	#$400,d0
		andi.w	#$ffe,d0
		move.w	(a0,d0.w),d2	;z1
		addi.w	#$400,d0
		andi.w	#$ffe,d0
		move.w	(a0,d0.w),d4	;y2
		addi.w	#$400,d0
		andi.w	#$ffe,d0
		move.w	(a0,d0.w),d5	;z2

		asr.w	#3,d1
		asr.w	#5,d2
		asr.w	#3,d4
		asr.w	#5,d5
		
		addi.w	#tf,d2
		addi.w	#tf,d5
		
		move.w	#-$800,d0
		
		lea		points(pc),a1
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		move.w	d2,(a1)+
				
		move.w	d0,(a1)+
		move.w	d4,(a1)+
		move.w	d5,(a1)+
	
		lea		points(pc),a0
		lea		dstpoints(pc),a1
		moveq	#2-1,d7
.l0:	
		movem.w	(a0)+,d0-d2
		
		muls.w	#au,d0
		muls.w	#au,d1
		divs.w	d2,d0
		divs.w	d2,d1
		
		addi.w	#160,d0
		addi.w	#128,d1
	
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		move.w	d2,(a1)+
	
		dbra	d7,.l0
		
		move.l	a5,a0
		move.l	a6,a1
		moveq	#-1,d0
		move.w	#256/4-1,d7
.l1:
		move.l	d0,(a0)+
		move.l	d0,(a1)+
		dbra	d7,.l1
		
		lea		dstpoints(pc),a1
		
		move.w	(a1)+,d0	;x1
		move.w	(a1)+,d1	;y1
		move.l	#$fffff,d2
		divu.w	(a1)+,d2	;32767/z1		
		move.w	#10+10,d3		;v1
		muls.w	d2,d3		;v1*32767/z1	
		move.w	(a1)+,d4	;x2
		move.w	(a1)+,d5	;y2
		move.l	#$fffff,d6
		divu.w	(a1)+,d6	;32767/z2	
		move.w	#STAR_NUMTEXTLINES*STAR_FONTHEIGHT-8-10,d7	;v2	
		muls.w	d6,d7		;v2*32767/z2
		
		cmp.w	d1,d5
		beq.w	.skip
		bgt.b	.noswap		;if (y1>y2) swap p1/p2
		exg		d0,d4
		exg		d1,d5
		exg		d2,d6
		exg		d3,d7
.noswap:
		sub.w	d0,d4		;dx=x2-x1
		sub.w	d1,d5		;dy=y2-y1
		sub.w	d2,d6		;dz=z2-z1
		sub.l	d3,d7		;dv=v2-v1
		
		ext.l	d4
		ext.l	d6

		lsl.l	#8,d4
		lsl.l	#8,d6
		lsl.l	#1,d7
		divs.w	d5,d4
		divs.w	d5,d6
		divs.w	d5,d7
		ext.l	d4
		ext.l	d6
		ext.l	d7
		lsl.l	#8,d4
		lsl.l	#8,d6
		lsl.l	#8,d7
		swap	d0
		swap	d2
		move.w	#$8000,d0
		move.w	#$8000,d2
		lsl.l	#8,d3
		lsl.l	#1,d3
	
		add.w	d1,d5
		cmpi.w	#255,d5
		blt.b	.clipbottom
		move.w	#255,d5
.clipbottom:
		sub.w	d1,d5
		
		tst.w	d1
		bpl.b	.cliptop
		neg.w	d1
		subq	#1,d1
.cl0:	
		add.l	d4,d0
		add.l	d6,d2
		add.l	d7,d3
		
		dbra	d1,.cl0
		moveq	#0,d1
.cliptop:
		move.l	a5,a0
		move.l	a6,a1
		adda.w	d1,a0
		adda.w	d1,a1
		
		swap	d0
		moveq	#87,d1
		sub.w	d0,d1
		muls.w	#24*65536/87,d1
		swap	d1
		addq	#2,d1
		lsl.w	#4,d1
		move.w	d1,(a4)
		swap	d0
		
		move.l	d4,a2
		move.l	d6,a3

		subq	#1,d5
.l2:
		move.l	d0,d1
		swap	d1
		move.b	d1,(a1)+
		
		move.l	d3,d1
		move.l	d2,d4
		swap	d4
		lsr.l	#8,d1
		lsr.l	#1,d1
		divu.w	d4,d1
		move.b	d1,(a0)+
		
		add.l	a2,d0
		add.l	a3,d2
		add.l	d7,d3
		
		dbra	d5,.l2
.skip:
		rts
		
;--------------------------------------------------------------------

star_gentabs:
		lea		star_charlineoffsets,a0
		lea		star_charlineoffsets2,a2
		lea		star_scalewidths,a1
		
		move.l	star_screen,d2
;		moveq	#0,d2
		
		moveq	#0,d0
.l0:
		move.w	(a1)+,d3
		mulu.w	#STAR_FONTHEIGHT*STAR_NUMBPLS,d3

		moveq	#0,d1
.l1:
		moveq	#0,d6
		sub.w	d3,d6
		
		cmp.w	d2,d6
		bhi.b	.nopad
		addi.l	#$ffff,d2	;if we are too close to a hi-byte increment, skip the charline and align to next 64k
		move.w	d4,d2
.nopad:
		
		move.l	d2,(a0)+
		move.w	d0,d4
		andi.w	#$fffe,d4
		ext.l	d4
		sub.l	d4,d2
		move.l	d2,(a2)+
		add.l	d4,d2
		add.l	d3,d2
	
		addq	#1,d1
		cmpi.w	#STAR_NUMTEXTLINES,d1
		bne.b	.l1
		
		addq	#1,d0
		cmpi.w	#STAR_NUMCHARWIDTH,d0
		bne.b	.l0
		
		lea		star_scalewidths2,a1
		moveq	#STAR_FONTHEIGHT-1,d6
.l4:	
		lea		star_scalewidths,a0
		moveq	#0,d0
		moveq	#16-1,d7
.l3:
		move.w	(a0)+,d1
		move.w	d1,d2
		mulu.w	#3,d1
		moveq	#STAR_FONTHEIGHT-1,d5
		sub.w	d6,d5
		mulu.w	d5,d1
		move.w	d1,(a1)+
		move.w	d2,(a1)+
		;lsl.w	#2,d0
		move.w	d0,(a1)+
		clr.w	(a1)+
		
		addi.w	#STAR_NUMTEXTLINES*4,d0
		
		dbra	d7,.l3
		
		dbra	d6,.l4
		rts
		
;--------------------------------------------------------------------

;d1 - basepointer
star_initscreen:
		move.l	star_screen(pc),a0
		move.l	a0,d0
		add.l	d1,d0
		move.l	d0,d1
		move.l	d0,d2
		addi.l	#STAR_LINEWIDTH*1,d1
		addi.l	#STAR_LINEWIDTH*2,d2

		lea		star_copperbpl,a6
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)

		move.w	d1,$0e(a6)
		swap	d1
		move.w	d1,$0a(a6)

		move.w	d2,$16(a6)
		swap	d2
		move.w	d2,$12(a6)
		rts
		
;--------------------------------------------------------------------

star_inittemplates:
		lea		star_coppertemplates,a5
		lea		star_coppertemplates2,a6
		lea		star_templatebuf2,a1
		lea		star_shadetab,a4

		move.w	#STAR_NUMTEMPLATES-1,d7
.l0:		
		move.l	(a5)+,a0
		move.l	a1,(a6)+
.loop:
		move.l	(a0),d2
		beq.b	.end
		move.w	d2,d1
		cmpi.w	#$fffe,d1
		bne.b	.nowait
		andi.l	#$00ff80ff,d2
.nowait:
		move.l	d2,d3
		swap	d3
		cmpi.w	#$0180,d3
		blo.b	.nocol
		cmpi.w	#$01ae,d3
		bhi.b	.nocol
		
		move.w	d7,d4
		muls.w	#24*65536/87,d4
		swap	d4
		addq	#2,d4
		lsl.w	#4,d4
		sub.w	#$180,d3
		add.w	d3,d4
		move.w	(a4,d4.w),d2
.nocol:
		move.l	d2,(a0)+
		ori.l	#$80000000,d2
		move.l	d2,(a1)+
		bra.b	.loop
.end:
		move.l	#$008a0000,(a0)+
		move.l	#$008a0000,(a1)+

		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

TIME	= $00d7fffe
REG		= $0102

		cnop	0,2
star_tmpwidth:
		dc.w	0

		cnop	0,2
star_scalewidths:
		dc.w	STAR_LINEWIDTH1
		dc.w	STAR_LINEWIDTH2
		dc.w	STAR_LINEWIDTH3
		dc.w	STAR_LINEWIDTH4
		dc.w	STAR_LINEWIDTH5
		dc.w	STAR_LINEWIDTH6
		dc.w	STAR_LINEWIDTH7
		dc.w	STAR_LINEWIDTH8
		dc.w	STAR_LINEWIDTH9
		
star_initcopper:
		lea		star_copperscale,a0
		lea		star_linewidths,a2
		lea		star_linevs,a3
		lea		star_coppois,a1
		move.l	#TIME+$2b000000,d0
		
		move.w	#256-1,d7
.l0:
		move.w	#$00e0,d1
		
		move.l	star_screen(pc),a5
		move.l	a5,d2
		
		moveq	#0,d4
		move.b	(a2)+,d4
		bpl.b	.clip
		moveq	#0,d4
.clip:
		move.w	d4,star_tmpwidth
		lsr.w	#3,d4
		
		moveq	#0,d3
		move.b	(a3)+,d3
		
		mulu.w	#STAR_LINEWIDTH*STAR_NUMBPLS,d3
		mulu.w	#STAR_LINEWIDTH*STAR_NUMBPLS*STAR_NUMTEXTLINES*STAR_FONTHEIGHT,d4
		add.l	d3,d2
		add.l	d4,d2
		
		move.l	d0,d6
		cmpi.l	#$ffd7fffe,d6
		bne.b	.bla
		move.l	#$ffdffffe,d6
.bla:
		move.l	d6,(a0)+
		
		addq	#2,a0
		move.l	a0,(a1)+
		subq	#2,a0
		
		moveq	#3-1,d6
.l1:
		move.w	d1,(a0)+
		addq	#2,d1

		swap	d2
		move.w	d2,(a0)+
		
		move.w	d1,(a0)+
		addq	#2,d1
		swap	d2
		move.w	d2,(a0)+
				
		addi.w	#STAR_LINEWIDTH,d2
		
		dbra	d6,.l1
		
		move.l	a0,d5
		addi.l	#20,d5
		move.w	#$0086,(a0)+
		move.w	d5,(a0)+
		move.w	#$0084,(a0)+
		swap	d5
		move.w	d5,(a0)+
		
		lea		star_coppertemplates,a5
		move.l	d0,d6
		addi.l	#$01000000,d6
		tst.l	d6
		bpl.b	.noneg
		adda.w	#4*STAR_NUMTEMPLATES,a5
.noneg:
		move.w	star_tmpwidth(pc),d6
		lsl.w	#2,d6
		move.l	(a5,d6.w),d5

		move.w	#$0082,(a0)+
		move.w	d5,(a0)+
		move.w	#$0080,(a0)+
		swap	d5
		move.w	d5,(a0)+
		move.l	#$00880000,(a0)+

		addi.l	#$01000000,d0
		dbra	d7,.l0
		
		lea		star_copperlist,a1
		move.l	a1,d0
		
		move.w	#$0082,(a0)+
		move.w	d0,(a0)+
		move.w	#$0080,(a0)+
		swap	d0
		move.w	d0,(a0)+
		rts

star_coppertemplates:
		dc.l	star_tmp0
		dc.l	star_tmp1
		dc.l	star_tmp2
		dc.l	star_tmp3
		dc.l	star_tmp4
		dc.l	star_tmp5
		dc.l	star_tmp6
		dc.l	star_tmp7
		dc.l	star_tmp8
		dc.l	star_tmp9
		dc.l	star_tmp10
		dc.l	star_tmp11
		dc.l	star_tmp12
		dc.l	star_tmp13
		dc.l	star_tmp14
		dc.l	star_tmp15
		dc.l	star_tmp16
		dc.l	star_tmp17
		dc.l	star_tmp18
		dc.l	star_tmp19
		dc.l	star_tmp20
		dc.l	star_tmp21
		dc.l	star_tmp22
		dc.l	star_tmp23
		dc.l	star_tmp24
		dc.l	star_tmp25
		dc.l	star_tmp26
		dc.l	star_tmp27
		dc.l	star_tmp28
		dc.l	star_tmp29
		dc.l	star_tmp30
		dc.l	star_tmp31
		dc.l	star_tmp32
		dc.l	star_tmp33
		dc.l	star_tmp34
		dc.l	star_tmp35
		dc.l	star_tmp36
		dc.l	star_tmp37
		dc.l	star_tmp38
		dc.l	star_tmp39
		dc.l	star_tmp40
		dc.l	star_tmp41
		dc.l	star_tmp42
		dc.l	star_tmp43
		dc.l	star_tmp44
		dc.l	star_tmp45
		dc.l	star_tmp46
		dc.l	star_tmp47
		dc.l	star_tmp48
		dc.l	star_tmp49
		dc.l	star_tmp50
		dc.l	star_tmp51
		dc.l	star_tmp52
		dc.l	star_tmp53
		dc.l	star_tmp54
		dc.l	star_tmp55
		dc.l	star_tmp56
		dc.l	star_tmp57
		dc.l	star_tmp58
		dc.l	star_tmp59
		dc.l	star_tmp60
		dc.l	star_tmp61
		dc.l	star_tmp62
		dc.l	star_tmp63
		dc.l	star_tmp64
		dc.l	star_tmp65
		dc.l	star_tmp66
		dc.l	star_tmp67
		dc.l	star_tmp68
		dc.l	star_tmp69
		dc.l	star_tmp70
		dc.l	star_tmp71
		dc.l	star_tmp72
		dc.l	star_tmp73
		dc.l	star_tmp74
		dc.l	star_tmp75
		dc.l	star_tmp76
		dc.l	star_tmp77
		dc.l	star_tmp78
		dc.l	star_tmp79
		dc.l	star_tmp80
		dc.l	star_tmp81
		dc.l	star_tmp82
		dc.l	star_tmp83
		dc.l	star_tmp84
		dc.l	star_tmp85
		dc.l	star_tmp86
		dc.l	star_tmp87
star_coppertemplates2:
		ds.l	STAR_NUMTEMPLATES

;--------------------------------------------------------------------

star_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		;move.w	#$800,$dff180
	;	tst.w	star_move
	;	beq.b	.skip
		bsr.w	star_updatecopper
.skip:
		;clr.w	$dff180
		
		;move.w	#$fff,$dff180
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
	
		cnop	0,2
star_textline:
		dc.w	0
star_destline:
		dc.w	STAR_NUMTEXTLINES-1
star_move:
		dc.w	1
	
star_updatemap:
.waitsync:
		tst.w	star_sync
		beq.b	.waitsync
		clr.w	star_sync

		move.w	star_textline(pc),d0
		addq	#1,d0
		cmpi.w	#STAR_TEXTLENGTH,d0
		bne.b	.nowrap
		clr.w	star_move
		moveq	#0,d0
.nowrap:
		move.w	d0,star_textline
		
		move.w	star_destline(pc),d0
		addq	#1,d0
		cmpi.w	#STAR_NUMTEXTLINES,d0
		bne.b	.nowrap2
		moveq	#0,d0
.nowrap2:
		move.w	d0,star_destline
		
		moveq	#STAR_NUMCHARWIDTH-1,d7
.l0:
		move.w	d7,-(sp)
		
		move.w	d7,d1
		mulu.w	#STAR_NUMTEXTLINES,d1
		add.w	star_destline(pc),d1
		move.w	star_textline(pc),d2
		move.w	d7,d3
		bsr.w	star_drawline
		
		move.w	(sp)+,d7

		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

;d1 - ypos
;d2	- width in pixels
star_clear:
		lsr.w	#4,d2
		
		lea		star_charlineoffsets,a2
		add.w	d1,d1
		add.w	d1,d1
		move.l	(a2,d1.w),a1
		
		lea		BLTBASE,a5
		move.l	fw_jumptable(pc),a6
		
		jsr		BLTWAIT(a6)
		
		move.w	#$ffff,BLTAFWM(a5)
		move.w	#$ffff,BLTALWM(a5)
		clr.w	BLTADAT(a5)
		clr.w	BLTDMOD(a5)
		move.l	a1,BLTDPTR(a5)
		move.w	#$01f0,BLTCON0(a5)
		addi.w	#STAR_NUMBPLS*(STAR_FONTHEIGHT)*64,d2
		move.w	d2,BLTSIZE(a5)
		rts
			
;--------------------------------------------------------------------
	
			cnop	0,2
star_scale:	dc.w	0
star_x:		dc.w	0
star_y:		dc.w	0
star_chr:	dc.w	0
star_width:	dc.w	0

;d1 - ypos
;d2 - textline
;d3 - scale
star_drawline:
		move.w	d1,-(sp)
		move.w	d2,-(sp)
		move.w	d3,-(sp)

		add.w	d3,d3
		lea		star_scalewidths,a2
		move.w	(a2,d3.w),d2
		lsl.w	#3,d2
		bsr.w	star_clear
		
		move.w	(sp)+,d3
		move.w	(sp)+,d2
		move.w	(sp)+,d1
			
		move.w	d3,star_scale
		
		moveq	#20,d5
		sub.w	d3,d5
		move.w	d5,star_width
		
		andi.w	#1,d3
		lsl.w	#3,d3
		move.w	d3,star_x
		lsl.w	#4,d1
		move.w	d1,star_y
		
		lea		star_text,a4
		lsl.w	#4,d2
		adda.w	d2,a4
		
		moveq	#16-1,d7
.l0:
		moveq	#0,d2
		move.b	(a4)+,d2
		cmp.b	#$20,d2
		beq.b	.skip
		subi.w	#$61,d2
		move.w	star_x(pc),d0
		move.w	star_y(pc),d1
		move.w	star_scale(pc),d3
		
		bsr.w	star_drawletter
.skip:
		move.w	star_width(pc),d4
		add.w	d4,star_x
		
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

;d0 - xpos
;d1 - ypos
;d2 - char
;d3 - scale (0-10)
star_drawletter:
		move.w	d3,d5
		mulu.w	#4*STAR_FONTHEIGHT*STAR_NUMBPLS*STAR_NUMCHARWIDTH,d2
		mulu.w	#4*STAR_FONTHEIGHT*STAR_NUMBPLS,d3
		add.l	d2,d3

		move.w	d0,d2
		lsr.w	#3,d2
		andi.w	#$0f,d0
		ror.w	#4,d0
		ori.w	#$bfa,d0
		
		lea		star_charlineoffsets,a2
		lsr.w	#4,d1
		lsl.w	#2,d1
		move.l	(a2,d1.w),a1	
		add.w	d2,a1
	
		lea		star_font,a0
		adda.l	d3,a0
		
		lea		star_scalewidths,a2
		add.w	d5,d5
		move.w	(a2,d5.w),d4
		subq	#6,d4
		
		move.l	fw_jumptable(pc),a6
		lea		BLTBASE,a5
		
		jsr		BLTWAIT(a6)
		
		cmpi.w	#2*2,d5
		bgt.b	.narrow
		
		move.w	#$ffff,BLTAFWM(a5)
		clr.w	BLTALWM(a5)
		move.w	#-2,BLTAMOD(a5)
		move.w	d4,BLTCMOD(a5)
		move.w	d4,BLTDMOD(a5)
		move.l	a0,BLTAPTR(a5)
		move.l	a1,BLTCPTR(a5)
		move.l	a1,BLTDPTR(a5)
		move.w	d0,BLTCON0(a5)
		move.w	#STAR_NUMBPLS*STAR_FONTHEIGHT*64+3,BLTSIZE(a5)
		rts
.narrow:
		addq	#2,d4
		
		move.w	#$ffff,BLTAFWM(a5)
		move.w	#$ffff,BLTALWM(a5)
		clr.w	BLTAMOD(a5)
		move.w	d4,BLTCMOD(a5)
		move.w	d4,BLTDMOD(a5)
		move.l	a0,BLTAPTR(a5)
		move.l	a1,BLTCPTR(a5)
		move.l	a1,BLTDPTR(a5)
		move.w	d0,BLTCON0(a5)
		move.w	#STAR_NUMBPLS*STAR_FONTHEIGHT*64+2,BLTSIZE(a5)
		rts

;--------------------------------------------------------------------

 MACRO<STAR_UPDATELINE>
		move.l	(a0)+,a1
		moveq	#0,d4
		move.b	(a2)+,d4
		bmi.b	.empty\@

		move.w	#STAR_NUMTEXTLINES*STAR_FONTHEIGHT,d0
		
		moveq	#0,d3
		move.b	(a3)+,d3
		add.w	d5,d3
		cmp.w	d0,d3
		blt.b	.nowrap2\@
		sub.w	d0,d3
.nowrap2\@:
		moveq	#$0f,d6
		and.w	d3,d6		;line inside font
		lsl.w	#7,d6
		
		lsr.w	#2,d3		;charline
		add.w	d4,d6
		andi.w	#$fff8,d6				;d2 und d5 frei
		movem.w	(a6,d6.w),d0/d1/d6
		andi.w	#$fffc,d3	;offset into star_charlineoffsets
		add.w	d6,d3		;charline including scale
		
		add.l	(a5,d3.w),d0
			
		move.w	d0,4(a1)
		add.w	d1,d0
		move.w	d0,12(a1)
		add.w	d1,d0
		move.w	d0,20(a1)

		swap	d0
		move.w	d0,(a1)
		move.w	d0,8(a1)
		move.w	d0,16(a1)

		add.w	d4,d4
		add.w	d4,d4

		move.w	(a4,d4.w),36(a1)
		move.w	2(a4,d4.w),32(a1)
		
		bra.b	.end\@
.empty\@:
		move.l	#star_emptyline,d0
		move.w	d0,4(a1)
		move.w	d0,12(a1)
		move.w	d0,20(a1)
		swap	d0
		move.w	d0,(a1)
		move.w	d0,8(a1)
		move.w	d0,16(a1)
	
		move.l	(a4),d4
		move.w	d4,32(a1)
		swap	d4
		move.w	d4,36(a1)
		
		addq	#1,a3
.end\@:
 ENDM

		cnop	0,2
star_frame:
		dc.w	0
star_offset:
		dc.w	0
star_offsetshift:
		dc.w	0
star_rot:
		dc.w	$5800
star_rotstep:
		dc.w	0
star_subpos:
		dc.w	0
star_sync:
		dc.w	0
star_accelerations:
		dc.w	-4,4,0,0,4,-4,0,-0
	
star_updatecopper:	
		move.w	star_subpos(pc),d0
		addq	#1,d0
		cmpi.w	#16*2,d0
		bne.b	.nowrap0
		moveq	#0,d0
.nowrap0:
		cmpi.w	#4*2,d0
		bne.b	.nowrap01
		addq.w	#1,star_sync
.nowrap01:
		move.w	d0,star_subpos

		move.w	star_offset(pc),d0
		addq	#1,d0
		cmpi.w	#STAR_NUMTEXTLINES*STAR_FONTHEIGHT*2,d0
		bne.b	.nowrap1
		moveq	#0,d0
.nowrap1:
		move.w	d0,star_offset
		move.w	d0,d1
		lsr.w	#1,d0
		move.w	d0,star_offsetshift
		
		move.w	star_frame(pc),d1
		addq	#1,d1
		move.w	d1,star_frame
		
		moveq	#0,d3
		
		cmpi.w	#512,d1
		blt.b	.norot
		
		lsr.w	#7,d1
		andi.w	#$07,d1
		add.w	d1,d1
		lea		star_accelerations,a5
		move.w	(a5,d1.w),d3
.norot:		
		add.w	d3,star_rotstep
		
		move.w	star_rot(pc),d2
		add.w	star_rotstep(pc),d2
		move.w	d2,star_rot
		lsr.w	#8,d2
		ext.l	d2
		lea		star_lineshades,a4
		add.w	d2,d2
		add.w	d2,a4		
		lsl.l	#7,d2
		
		lea		star_coppois,a0
		lea		star_linewidths,a2
		lea		star_linevs,a3
		adda.l	d2,a3
		adda.l	d2,a2
		
		move.w	(a4),d0
		lea		star_shadetab,a4
		adda.w	d0,a4
		lea		star_copperpal,a6
		move.w	(a4)+,2(a6)
		move.w	(a4)+,6(a6)
		move.w	(a4)+,10(a6)
		move.w	(a4)+,14(a6)
		move.w	(a4)+,18(a6)
		move.w	(a4)+,22(a6)
		move.w	(a4)+,26(a6)
		move.w	(a4)+,30(a6)
				
		lea		star_charlineoffsets2,a5
		lea		star_scalewidths2,a6
		lea		star_coppertemplates,a4
		
		moveq	#0,d1
		move.w	star_offsetshift(pc),d5
		move.l	star_screen(pc),d2
		
		move.w	#84-1,d7
.l0:		
		STAR_UPDATELINE
		dbra	d7,.l0
		
		lea		STAR_NUMTEMPLATES*4(a4),a4
		
		move.w	#128-1,d7
.l1:		
		STAR_UPDATELINE
		dbra	d7,.l1
	
		lea		-STAR_NUMTEMPLATES*4(a4),a4
		
		move.w	#44-1,d7
.l2:		
		STAR_UPDATELINE
		dbra	d7,.l2
		rts

;********************************************************************
				
				section "star_data",data
				
				cnop	0,8
star_shadetab:
	incbin "../data/starwars/shadetab.dat"

star_text:
		dc.b	"                "
		dc.b	"you just reached"
		dc.b	"the    end    of"
		dc.b	"                "
		dc.b	"planet          "
		dc.b	"     rocklobster"
		dc.b	"                "
		dc.b	"the first oxyron"
		dc.b	"amiga  demo  for"
		dc.b	"a long long time"
		dc.b	"                "
		dc.b	"if   you   think"
		dc.b	"this demo is too"
		dc.b	"short  blame the"
		dc.b	"revision   orgas"
		dc.b	"for  the  stupid"
		dc.b	"one  disk   rule"
		dc.b	"                "
		dc.b	"i have parts for"
		dc.b	"two  more  disks"
		dc.b	"                "
		dc.b	"                "
		dc.b	"detailed credits"
		dc.b	"and  more   tech"
		dc.b	"details  can  be"
		dc.b	"found         in"
		dc.b	"the       readme"
		dc.b	"                "
		dc.b	"                "
		dc.b	"so  i   continue"
		dc.b	"with        some"
		dc.b	"personal  greets"
		dc.b	"                "
		dc.b	"first   of   all"
		dc.b	"thanks   to  the"
		dc.b	"whole       team"
		dc.b	"                "
		dc.b	"you  guys   rock"
		dc.b	"                "
		dc.b	"more      greets"
		dc.b	"fly           to"
		dc.b	"                "
		dc.b	"tin   peiselulli"
		dc.b	"doynax    heaven"
		dc.b	"blueberry  xxxxx"
		dc.b	"raylight    guru"
		dc.b	"chaos     photon"
		dc.b	"ragnar     crown"
		dc.b	"                "
		dc.b	"and     all    i"
		dc.b	"have   forgotten"
		dc.b	"                "
		dc.b	"                "
		dc.b	"see    you    in"
		dc.b	"one    of    our"
		dc.b	"upcoming   prods"
		dc.b	"                "
		dc.b	"                "
		dc.b	"                "
		dc.b	"                "
		dc.b	"end of          "
		dc.b	"    transmission"
		dc.b	"                "
		dc.b	"                "
		dc.b	"                "
		dc.b	"                "
		dc.b	"                "
star_textend:

STAR_TEXTLENGTH	= (star_textend-star_text)/16

star_sintab:
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096	
				
;********************************************************************

				section "star_empty",bss

				cnop	0,8		
star_coppois:
				ds.l	256	
star_charlineoffsets:
				ds.l	STAR_NUMTEXTLINES*STAR_NUMCHARWIDTH
star_charlineoffsets2:
				ds.l	STAR_NUMTEXTLINES*STAR_NUMCHARWIDTH
star_scalewidths2:
				ds.w	STAR_NUMCHARWIDTH*4*STAR_FONTHEIGHT
				ds.b	$400
star_linewidths:
				ds.b	$10000
star_linevs:
				ds.b	$10000
star_lineshades:	
				ds.w	256

;********************************************************************

				section "star_emptychip",bss,chip

STAR_SIZEPAGE1	= STAR_LINEWIDTH1*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE2	= STAR_LINEWIDTH2*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE3	= STAR_LINEWIDTH3*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE4	= STAR_LINEWIDTH4*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE5	= STAR_LINEWIDTH5*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE6	= STAR_LINEWIDTH6*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE7	= STAR_LINEWIDTH7*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE8	= STAR_LINEWIDTH8*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_SIZEPAGE9	= STAR_LINEWIDTH9*STAR_NUMTEXTLINES*STAR_FONTHEIGHT*STAR_NUMBPLS
STAR_WORSTCASE_PAD	= STAR_LINEWIDTH1*STAR_NUMBPLS*STAR_FONTHEIGHT
STAR_SCREEN_PADDING	= STAR_WORSTCASE_PAD*4
STAR_SCREENSIZE	= STAR_SIZEPAGE1+STAR_SIZEPAGE2+STAR_SIZEPAGE3+STAR_SIZEPAGE4+STAR_SIZEPAGE5+STAR_SIZEPAGE6+STAR_SIZEPAGE7+STAR_SIZEPAGE8+STAR_SIZEPAGE9+STAR_SCREEN_PADDING
			
				cnop	0,8
star_emptyline:
				ds.b	STAR_LINEWIDTH

star_templatebuf2:
				ds.b	star_templatesend-star_tmp0
				
;********************************************************************

				section "star_copper",data,chip

star_copperlist:	
				dc.l	$008e2c81,$00902c4c1,$00920030,$009400c8 ;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
				
star_copperpal:
				dc.l	$01800000,$01820000,$01840000,$01860000
				dc.l	$01880000,$018a0000,$018c0000,$018e0000
				
star_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;3 bitplane pointers
				dc.l	$00e80000,$00ea0000

star_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080050,$010a0050						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01003200						;wait x: 15, y: 1, turn on 3 bitplanes

				dc.l	$009c8010								;start irq
						
				dc.l	$2bbffffe
star_copperscale:
				blk.l	256*12+3,$01800000	

				dc.l	$fffffffe 								;wait for end
					
;--------------------------------------------------------------------
		
		include "../data/starwars/coppercode.asm"	
star_templatesend:
		
;--------------------------------------------------------------------
	
				cnop	0,2
star_font:
	incbin "../data/starwars/letters.dat"

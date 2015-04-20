ROT_NUMFRAMES	= 870

numlines	= 64
width		= 472
height		= 200

	include "../framework/hardware.i"
	include "../framework/framework.i"
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

	
			section	"rot_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#200,d0
		move.w	d0,rot_startframe

		bsr.w	rot_init
		bsr.w	rot_update
		bsr.w	rot_update
		bsr.w	rot_dopage
						
		lea		rot_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
				
		lea		rot_coppersprites,a0
		lea		rot_sprites,a1
		moveq	#2-1,d7
.l0:
		move.l	(a1)+,d0
		move.w	d0,$06(a0)
		swap	d0
		move.w	d0,$02(a0)
		addq	#8,a0
		dbra	d7,.l0
	
		move.w	#TIME_ROTO_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#rot_copperlist,a0
		move.l	#rot_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
	
		move.w	#$8020,$dff096		;copper, bitplane & sprite dma
			
		lea		$dff1a0,a0
		moveq	#16-1,d7
.l1:
		move.w	#$fff,(a0)+
		dbra	d7,.l1
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#ROT_NUMFRAMES,d0
		move.w	d0,rot_endframe

		bsr.w	rot_setpal
	
;		move.l	fw_jumptable,a6
;		jsr		VSYNC(a6)

.syncw2:
		cmpi.w	#2,rot_sync
		blt.b	.syncw2
		clr.w	rot_sync
		
rot_main:
		;move.w	#$400,$dff180
		bsr.w	rot_dofade
		bsr.w	rot_dolerpy
		bsr.w	rot_move
		bsr.w	rot_draw
		bsr.w	rot_blit
		;clr.w	$dff180
		
.syncw:
		cmpi.w	#2,rot_sync
		blt.b	.syncw
		clr.w	rot_sync
				
		btst	#$06,$bfe001
		beq.b	rot_end
		
		move.w	rot_endframe,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	rot_main
rot_end:

		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		
		move.w	#$0020,$dff096		;turn off sprite dma
		rts		

		cnop	0,4
fw_jumptable:
		dc.l	0
rot_startframe:
		dc.w	0
rot_endframe:
		dc.w	0

;--------------------------------------------------------------------
		
rot_init:
		lea		rot_sintab,a0
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

		lea		rot_modtab,a0
		moveq	#0,d0
		moveq	#64-1,d7
.l0:	
		move.w	d0,d1
		muls.w	#64*1,d1
		
		move.w	d1,(a0)+
		
		addq	#1,d0
		dbra	d7,.l0
		
		lea		rot_techtechtab,a0
		move.w	#256-1,d7
.l1:
		move.w	#256-1,d0
		sub.w	d7,d0
		addi.w	#20,d0
		
		move.w	d0,d1
		
		andi.w	#$0f,d0
		move.w	d0,d2
		lsl.w	#4,d2
		or.w	d2,d0		
		
		asr.w	#3,d1
		andi.w	#$fffe,d1
		neg.w	d1
		
		move.w	d0,(a0)+
		move.w	d1,(a0)+
		
		dbra	d7,.l1
		
		bsr.w	rot_inittexture
		bsr.w	rot_initcopper
		bsr.w	rot_initfade
		rts

;--------------------------------------------------------------------

rot_inittexture:
		lea		rot_texture,a1
		moveq	#4-1,d7
.l00:
		move.w	d7,-(sp)
		
		bsr.w	.doconv
		bsr.w	rot_rottex90
		adda.w	#$2000,a1
		
		move.w	(sp)+,d7
		dbra	d7,.l00
		rts

.doconv:
		lea		rot_tmptex,a0
		moveq	#64-1,d6
.l1:
		moveq	#64-1,d7
.l0:
		moveq	#0,d0
		move.b	(a0)+,d0
		move.w	d0,d1
		move.w	d0,d2
		move.w	d0,d3
		andi.w	#$01,d0
		andi.w	#$02,d1
		andi.w	#$04,d2
		andi.w	#$08,d3
		lsl.w	#8,d0
		lsl.w	#6,d0
		lsl.w	#8,d1
		lsl.w	#5,d1
		lsl.w	#8,d2
		lsl.w	#4,d2
		lsl.w	#8,d3
		lsl.w	#3,d3
		
		add.w	d0,d0
		add.w	d1,d1
		add.w	d2,d2
		add.w	d3,d3
		lsr.w	#4,d1
		lsr.w	#8,d2
		lsr.w	#8,d3
		lsr.w	#4,d3
		or.w	d1,d0
		or.w	d2,d0
		or.w	d3,d0

		move.w	d0,$2000(a1)
		move.w	d0,(a1)+
		
		dbra	d7,.l0
				
		dbra	d6,.l1
		rts

rot_rottex90:
		lea		rot_tmptex,a2
		lea		rot_tmptex2+63,a3
		moveq	#64-1,d7
.l1:
		moveq	#64-1,d6
.l0:
		move.b	(a2)+,d0
		move.b	d0,(a3)
		adda.w	#64,a3
		
		dbra	d6,.l0
		
		suba.w	#64*64+1,a3
		
		dbra	d7,.l1
		
		lea		rot_tmptex2,a2
		lea		rot_tmptex,a3
		move.w	#64*64/4-1,d7
.l2:	
		move.l	(a2)+,(a3)+
		dbra	d7,.l2
		rts
		
;--------------------------------------------------------------------

rot_initcopper:
		lea		rot_copperscale,a0
			
		move.l	#$440ffffe,d0
		move.l	#$0108ffd8,d1
		move.l	#$010affd8,d2
		move.l	#$01020000,d3
		move.w	#height+1-1,d7
.l0:
		move.l	d0,(a0)+
		move.l	d1,(a0)+
		move.l	d2,(a0)+
		move.l	d3,(a0)+
		addi.l	#$01000000,d0
		cmpi.l	#$000ffffe,d0
		bne.b	.skip
		move.l	#$ffdffffe,(a0)+
.skip:
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

rot_setpal:
		lea		$dff180,a1
		moveq	#16-1,d7
.l0:	
		clr.w 	(a1)+
		dbra	d7,.l0
		
		move.w	#$9a8,$dff180
		rts
 
;--------------------------------------------------------------------

rot_update:
		bsr.w	rot_move
		bsr.w	rot_draw
		bsr.w	rot_blit
		bsr.w	rot_dolerpy
		rts
		
;--------------------------------------------------------------------

rot_initfade:	
		lea		rot_fadetab,a1
		moveq	#0,d0
.l0:
		moveq	#0,d4
		bsr.w	.doconv
		addq	#1,d0
		cmpi.w	#16,d0
		bne.b	.l0
		
		moveq	#16-1,d0
.l1:
		move.w	#$9a8,d4
		bsr.w	.doconv
		dbra	d0,.l1
		rts
		
.doconv:
		move.w	d4,d5
		move.w	d5,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6
		
		lea		rot_pal,a0
		moveq	#16-1,d7
.l2:		
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
		
		dbra	d7,.l2
		rts

;--------------------------------------------------------------------

		cnop	0,2
rot_fadeframe:
		dc.w	0

rot_dofade:
		addq.w	#1,rot_fadeframe
		move.w	rot_fadeframe(pc),d0
		cmpi.w	#32,d0
		bge.b	.fadeout
		lsl.w	#4,d0
		bra.w	.dofade
.fadeout:
		move.w	#ROT_NUMFRAMES/2,d1
		sub.w	d0,d1
		move.w	d1,d0
		cmpi.w	#32,d0
		bge.b	.skip
		eori.w	#31,d0
		lsl.w	#4,d0
		addi.w	#16*16*2,d0
		bsr.w	.dofade
		
		move.w	-2(a0),d0
		move.w	d0,rot_copperfade1+2
		move.w	d0,rot_copperfade2+2
		move.w	d0,$dff1a6
.skip:
		rts
		
.dofade:
		andi.w	#$ffe0,d0
		lea		rot_fadetab+2,a0
		adda.w	d0,a0
		lea		$dff180+2,a1
		REPT	7
		move.l	(a0)+,(a1)+
		ENDR
		move.w	(a0)+,(a1)+
		rts
		
;--------------------------------------------------------------------
		
rotstep		= 24/2
scalestep	= 48/2
ustep		= 12/2
vstep		= 20/2

		cnop	0,2
rot_scaleoff:
		dc.w	$200/2
rot_uoff:
		dc.w	0
rot_voff:
		dc.w	0
rot_rot:
		dc.w	12/2
rot_scale:
		dc.w	0
rot_u:
		dc.l	0
rot_v:
		dc.l	0
rot_stepux:
		dc.l	0
rot_stepvx:
		dc.l	0
rot_stepuy:
		dc.l	0
rot_stepvy:
		dc.l	0
texid:
		dc.w	0
		
rot_move:
		moveq	#scalestep,d4
		moveq	#ustep,d5
		moveq	#vstep,d6
		moveq	#rotstep,d7	

		move.w	rot_fadeframe(pc),d0
		addi.w	#40,d0
		andi.w	#$7f,d0
		cmpi.w	#$70,d0
		bgt.b	.bla
		neg.w	d4
		neg.w	d5
		neg.w	d6
		neg.w	d7
.bla:		

		move.w	rot_scaleoff(pc),d0
		add.w	d4,d0
		andi.w	#$7fe,d0
		move.w	d0,rot_scaleoff
		
		move.w	rot_uoff(pc),d1
		add.w	d5,d1
		andi.w	#$7fe,d1
		move.w	d1,rot_uoff

		move.w	rot_voff(pc),d2
		add.w	d6,d2
		andi.w	#$7fe,d2
		move.w	d2,rot_voff
		
		lea		rot_sintab,a0
		move.w	(a0,d0.w),d0
		addi.w	#16384,d0
		mulu.w	#11000,d0
		swap	d0
		addi.w	#5700,d0
		move.w	d0,rot_scale

		move.w	(a0,d1.w),d1
		move.w	(a0,d2.w),d2

		move.w	rot_rot(pc),d0
		add.w	d7,d0
		andi.w	#$7fe,d0
		move.w	d0,rot_rot
	
		move.w	d0,d3
		lsr.w	#8,d3
		lsr.w	#1,d3
		andi.w	#$03,d3
		move.w	d3,texid

		add.w	d1,d1
		
		cmpi.w	#1,d3
		bne.b	.skip1
		exg		d1,d2
		neg.w	d1
.skip1:

		cmpi.w	#2,d3
		bne.b	.skip2
		neg.w	d1
		neg.w	d2
.skip2:

		cmpi.w	#3,d3
		bne.b	.skip3
		exg		d1,d2
		neg.w	d2
.skip3:

		swap	d1
		clr.w	d1
		lsr.l	#5,d1
		swap	d2
		clr.w	d2
		add.l	d2,d2
		
		move.l	d1,rot_u
		move.l	d2,rot_v
		
		andi.w	#$1fe,d0
		addi.w	#$100,d0
		lea		rot_sintab,a0
		move.w	(a0,d0.w),d1	;stepux
		addi.w	#$200,d0
		andi.w	#$7fe,d0
		move.w	(a0,d0.w),d2	;stepvx
		
		move.w	d1,d6
		move.w	d2,d3			;stepuy
		
		move.w	rot_scale(pc),d7
		muls.w	d7,d1
		muls.w	d7,d2
		lsl.l	#3,d1
		lsl.l	#3,d2
		swap	d1
		swap	d2
		
		addi.w	#$200,d0
		andi.w	#$7fe,d0
		move.w	(a0,d0.w),d4	;stepvy

		move.l	#15600*15600/2,d7
		divs.w	d6,d7			;corscale=16384*16384/stepux
	
		muls.w	d7,d3
		lsl.l	#4,d3
		swap	d3				;stepuy*corscale/4096;
		
		move.w	rot_scale(pc),d4
		muls.w	d7,d4
		lsl.l	#3,d4
		swap	d4				;stepvy=scale*corscale/256;
		
		ext.l	d1
		ext.l	d2
		ext.l	d3
		ext.l	d4

		add.l	d1,d1
		add.l	d2,d2
		add.l	d4,d4
		
		move.l	d1,rot_stepux
		move.l	d2,rot_stepvx
		move.l	d3,rot_stepuy
		move.l	d4,rot_stepvy
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
rot_screenoffset:
		dc.w	0

rot_dolerpy:		
		move.l	rot_stepuy(pc),d3
		move.l	rot_stepvy(pc),d4

		lsl.l	#3,d3
		lsl.l	#3,d4
		
		move.l	d3,d0
		add.l	d0,d0
		add.l	d3,d0
		lsl.l	#3,d0
		add.l	d3,d0
		lsl.l	#2,d0			
		neg.l	d0				;fast mul -100
	
		move.l	d4,d5
		add.l	d5,d5
		add.l	d4,d5
		lsl.l	#3,d5
		add.l	d4,d5
		lsl.l	#2,d5			
		neg.l	d5				;fast mul -100	
		
		move.w	d3,d7
		move.w	d4,d3
		move.w	d7,d4
		swap	d3
		swap	d4

		move.w	d0,d7
		move.w	d5,d0
		move.w	d7,d5
		swap	d0
		swap	d5
					
		addi.w	#345,d0
		add.w	#0,d5
				
		lea		rot_lerpyu,a0
		lea		rot_lerpyv,a1
		
		moveq	#$7e,d1
				
		REPT	height
		addx.l	d3,d0
		addx.l	d4,d5
		move.w	d0,(a0)+
		move.w	d5,(a1)+
		ENDR
	
 MACRO<LERPY1>
		move.w	(a0)+,d5
		and.w	d6,d5
		moveq	#$7e,d0
 		and.w	(a1)+,d0
		move.l	(a4,d5.w),d1
		add.w	(a3,d0.w),d1
		move.w	d1,d2
		sub.w	d3,d1
		sub.w	d7,d1
		
		move.w	d1,(a5)
		move.w	d1,4(a5)
		swap	d1
		move.w	d1,8+\1(a5)
		lea		16(a5),a5
 ENDM	

 MACRO<LERPY2>
		move.w	(a0)+,d5
		and.w	d6,d5
		moveq	#$7e,d0
 		and.w	(a1)+,d0
		move.l	(a4,d5.w),d1
		add.w	(a3,d0.w),d1
		move.w	d1,d3
		sub.w	d2,d1
		sub.w	d7,d1
		
		move.w	d1,(a5)
		move.w	d1,4(a5)
		swap	d1
		move.w	d1,8+\1(a5)
		lea		16(a5),a5
 ENDM	
		
		lea		rot_lerpyu,a0
		lea		rot_lerpyv,a1
		lea		rot_techtechtab,a4
		lea		rot_copperscale,a5
		adda.w	#6,a5
		lea		rot_modtab,a3
		moveq	#0,d2
		moveq	#38,d7
		moveq	#$fffffffc,d6

		LERPY2 0
		
		lea		-16(a5),a5
		move.w	(a5),rot_screenoffset
				
		movem.l	d0-d2/d4-d5/a0/a6,-(sp)
		bsr.w	rot_dopage
		movem.l	(sp)+,d0-d2/d4-d5/a0/a6
				
		REPT	93
			LERPY1 16
			LERPY2 16
		ENDR

		LERPY1 16
		LERPY2 20
		
		addq	#4,a5
		
		REPT	6
			LERPY1 16
			LERPY2 16
		ENDR

		rts
		
;--------------------------------------------------------------------

 MACRO<LERPX>
		move.l	d5,d6
		move.l	d0,d7
		swap	d6
		swap	d7
		andi.w	#$1f80,d6
		andi.w	#$007e,d7
		or.w	d7,d6
		lea		(a1,d6.w),\1
		add.l	d1,d0
		add.l	d2,d5
		add.l	d1,d3
		bpl.w	.end
 ENDM
 
 MACRO<BLTWAIT>
.bltwait\@:
		btst	#$0e,2(a6)
		bne.b	.bltwait\@
 ENDM
 
 MACRO<BLTWAIT2>
		move.w	#$8400,$96(a6)
.bltwait\@:
		btst	#$0e,2(a6)
		bne.b	.bltwait\@
		move.w	#$0400,$96(a6)
 ENDM
 
 MACRO<DOBLIT1>
		BLTWAIT
		move.l  a3,BLTAPTR(a6)
		move.l  a4,BLTBPTR(a6)
		move.l  a2,BLTDPTR(a6)
		
		move.w	#\1*4096+$dfc,BLTCON0(a6)
		move.w	#(\1+1)*4096,BLTCON1(a6)
		move.w  #64*64+1,BLTSIZE(a6)
 ENDM
 
 MACRO<DOBLIT2>
		BLTWAIT
		move.l  a3,BLTAPTR(a6)
		move.l  a4,BLTBPTR(a6)
		move.l  a2,BLTCPTR(a6)
		move.l  a2,BLTDPTR(a6)
		
		move.w	#\1*4096+$ffe,BLTCON0(a6)
		move.w	#(\1+1)*4096,BLTCON1(a6)
		move.w  #64*64+1,BLTSIZE(a6)
 ENDM
 
 MACRO<SETPIXEL>
		LERPX a3
		LERPX a4
		\2 \1
 ENDM 
				
rot_draw:
		lea		rot_texture,a1

		move.w	texid(pc),d0
		swap	d0
		clr.w	d0
		lsr.l	#2,d0
		adda.l	d0,a1
		
		lea		rot_screen4+8,a2
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
				
		lea		$dff000,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		move.w	#64*2-2,BLTAMOD(a6)
		move.w	#64*2-2,BLTBMOD(a6)
		move.w	#32*2-2,BLTCMOD(a6)
		move.w	#32*2-2,BLTDMOD(a6)
		
		move.l	rot_stepux(pc),d1
		move.l	rot_stepvx(pc),d2

		lsl.l	#2,d1
		lsl.l	#2,d2
		lsl.l	#6,d2
		
		move.l	d1,d0
		add.l	d0,d0
		add.l	d1,d0
		add.l	d0,d0
		add.l	d1,d0
		lsl.l	#5,d0
		neg.l	d0				;fast mul -224
		add.l	rot_u(pc),d0
		
		move.l	d2,d5
		add.l	d5,d5
		add.l	d2,d5
		add.l	d5,d5
		add.l	d2,d5
		lsl.l	#5,d5			
		neg.l	d5				;fast mul -224
		add.l	rot_v(pc),d5

		move.l	#$ff800000,d3
		REPT	2
		sub.l	d1,d3
		ENDR
		
		move.w	#$8400,$96(a6)

		moveq	#32-1,d4
.l0:			
		SETPIXEL  0, DOBLIT1
		SETPIXEL  2, DOBLIT2
		
		addq	#2,a2
		
		dbra	d4,.l0
.end:
		move.w	#$0400,$96(a6)
		
		bsr.w	rot_c2p
		bsr.w	rot_copy
		rts
		
;--------------------------------------------------------------------
 
 MACRO<C2PBLT>
		jsr		BLTWAIT(a6)
	
		move.w	#\2,BLTAFWM(a5)
		lea		\3(a2),a0
		lea		\4(a3),a1
		move.l	a0,BLTAPTR(a5)
		move.l	a1,BLTCPTR(a5)
		move.l	a1,BLTDPTR(a5)
		move.w	#\1*4096+\5,BLTCON0(a5)
		move.w	#64*64*8+1,BLTSIZE(a5)		
 ENDM

rot_c2p:
		lea		$dff000,a5
		move.l	fw_jumptable,a6
		
		lea		rot_screen4,a2
		lea		rot_screen3,a3
	
		jsr		BLTWAIT(a6)
		move.w	#$ffff,BLTALWM(a5)
		move.w	#6,BLTAMOD(a5)
		clr.w	BLTCMOD(a5)
		clr.w	BLTDMOD(a5)
		
		C2PBLT 	 0, $f000, 0, 0, $09f0
		C2PBLT 	 4, $f000, 2, 0, $0bfa
		C2PBLT 	 8, $f000, 4, 0, $0bfa
		C2PBLT 	12, $f000, 6, 0, $0bfa
	
		C2PBLT 	12, $0f00, 0+8, 32*64, $09f0
		C2PBLT 	 0, $0f00, 2, 32*64, $0bfa
		C2PBLT 	 4, $0f00, 4, 32*64, $0bfa
		C2PBLT 	 8, $0f00, 6, 32*64, $0bfa

		C2PBLT 	 8, $00f0, 0+8, 64*64, $09f0
		C2PBLT 	12, $00f0, 2+8, 64*64, $0bfa
		C2PBLT 	 0, $00f0, 4, 64*64, $0bfa
		C2PBLT 	 4, $00f0, 6, 64*64, $0bfa
		
		C2PBLT 	 4, $000f, 0+8, 96*64, $09f0
		C2PBLT 	 8, $000f, 2+8, 96*64, $0bfa
		C2PBLT 	12, $000f, 4+8, 96*64, $0bfa
		C2PBLT 	 0, $000f, 6, 96*64, $0bfa
		rts

;--------------------------------------------------------------------

 MACRO<COPYBLT>
		move.l	a2,BLTAPTR(a5)
		move.l	a3,BLTDPTR(a5)
		move.w	#64*64+8,BLTSIZE(a5)		
 ENDM

rot_copy:
		lea		$dff000,a5
		lea		rot_screen3,a2
		lea		16*64(a2),a3
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		clr.w	BLTAMOD(a5)
		clr.w	BLTDMOD(a5)
		move.w	#$09f0,BLTCON0(a5)
		
		COPYBLT
		
		jsr		BLTWAIT(a6)
		lea		32*64(a2),a2
		lea		32*64(a3),a3
		COPYBLT
		
		jsr		BLTWAIT(a6)
		lea		32*64(a2),a2
		lea		32*64(a3),a3
		COPYBLT
		
		jsr		BLTWAIT(a6)
		lea		32*64(a2),a2
		lea		32*64(a3),a3
		COPYBLT
		rts
		
;--------------------------------------------------------------------

 MACRO<BLITBLT>
		move.w	lastx(pc),d4	;x1
		move.w	d6,lastx
		
		subq	#1,d6
		
		moveq	#$fffffff0,d1
		moveq	#$fffffff0,d2

		and.w	d4,d1
		and.w	d6,d2
		sub.w	d1,d2
		lsr.w	#4,d2			;width in words
		
		andi.w	#$0f,d4			;x1 & 0x0f
		andi.w	#$0f,d6			;x2 & 0x0f
		move.w	d4,d3
		add.w	d4,d4
		add.w	d6,d6
		
		lsr.w	#3,d1			;(x1 & 0xfff0)>>3
		lea		(a3,d1.w),a4

		move.l	lastv(pc),d7
		swap	d7
		andi.w	#$1f80,d7
		lsr.w	#3,d7
		lea		(a2,d7.w),a0
		move.l	d5,lastv
	
		ror.w	#4,d3			;(x1 & 0x0f)<<12
		addq	#1,d2

		moveq	#64,d1
		sub.w	d2,d1
		sub.w	d2,d1
		
		moveq	#-48,d7
		add.w	d1,d7
		
		ori.w	#64*64,d2
		
		BLTWAIT2
		move.w	(a5,d4.w),BLTAFWM(a6)
		move.w	32(a5,d6.w),BLTALWM(a6)
		move.w	d3,BLTCON1(a6)
		move.w	d7,BLTBMOD(a6)
		move.w	d1,BLTCMOD(a6)
		move.w	d1,BLTDMOD(a6)

		move.l	a0,BLTBPTR(a6)
		move.l	a4,BLTCPTR(a6)
		move.l	a4,BLTDPTR(a6)
		move.w	d2,BLTSIZE(a6)
		
		lea		$800(a0),a0
		lea		$1000(a4),a4
		BLTWAIT2
		move.l	a0,BLTBPTR(a6)
		move.l	a4,BLTCPTR(a6)
		move.l	a4,BLTDPTR(a6)
		move.w	d2,BLTSIZE(a6)
	
		BLTWAIT2
		lea		$800(a0),a0
		lea		$1000(a4),a4
		move.l	a0,BLTBPTR(a6)
		move.l	a4,BLTCPTR(a6)
		move.l	a4,BLTDPTR(a6)
		move.w	d2,BLTSIZE(a6)

		BLTWAIT2
		lea		$800(a0),a0
		lea		$1000(a4),a4
		move.l	a0,BLTBPTR(a6)
		move.l	a4,BLTCPTR(a6)
		move.l	a4,BLTDPTR(a6)
		move.w	d2,BLTSIZE(a6)
 ENDM

rot_blit:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
				
		lea		$dff000,a6
		move.w	#$ffff,BLTADAT(a6)
		move.w	#$07ca,BLTCON0(a6)
		
		move.l	rot_stepux(pc),d1
		move.l	rot_stepvx(pc),d2

		lsl.l	#2,d1
		lsl.l	#2,d2
		lsl.l	#6,d2
		
		moveq	#0,d5
		move.l	#$ff800000,d0
	
		lea		rot_screen3+2,a2
		move.l	rot_screens+0,a3
	
		clr.w	lastx
		clr.l	lastv
		
		lea		masktab,a5
	
		move.w	#472-1,d7
.l0:		
		add.l	d2,d5
		add.l	d1,d0
		bmi.w	.noblit
		subi.l	#$00800000,d0

		movem.l	d1-d2/d7,-(sp)
		
		move.w	#472-1,d6
		sub.w	d7,d6			;x2
	
		BLITBLT
		
		movem.l	(sp)+,d1-d2/d7

.noblit:		
		dbra	d7,.l0

		move.w	#472-1,d6
		BLITBLT
		rts

		cnop	0,4
lastv:	dc.l	0
lastx:	dc.w	0
		
masktab:
		;left
		dc.w	$ffff,$7fff,$3fff,$1fff,$0fff,$07ff,$03ff,$01ff
		dc.w	$00ff,$007f,$003f,$001f,$000f,$0007,$0003,$0001
		;right
		dc.w	$8000,$c000,$e000,$f000,$f800,$fc00,$fe00,$ff00
		dc.w	$ff80,$ffc0,$ffe0,$fff0,$fff8,$fffc,$fffe,$ffff
		
;--------------------------------------------------------------------

rot_screens:
		dc.l	rot_screen1,rot_screen2

rot_dopage:
		lea 	rot_screens,a0
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	d0,$04(a0)
		move.l	d1,$00(a0)
		
		;move.l	d1,d0
		
		lea		rot_copperbpl,a6
		move.w 	rot_screenoffset,d5
		ext.l	d5
		add.l	d5,d0
		addi.l	#64*1-6,d0
		move.l	a0,d4
		move.l	d0,d1
		move.l	d0,d2
		addi.l	#64*64*1,d1
		addi.l	#64*64*2,d2
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)
		move.w	d1,$0e(a6)
		swap	d1
		move.w	d1,$0a(a6)
		move.w	d2,$16(a6)
		swap	d2
		move.w	d2,$12(a6)
		swap	d2
		addi.l	#64*64,d2
		move.w	d2,$1e(a6)
		swap	d2
		move.w	d2,$1a(a6)
		rts

;--------------------------------------------------------------------

		cnop	0,2
rot_sync:
		dc.w	0
		
rot_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		
		addq.w	#1,rot_sync
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
		cnop	0,4
rot_sprites:
		dc.l	rot_sprite1
		dc.l	rot_sprite2
		
;********************************************************************
		
				section "rot_data",data

				cnop	0,2
rot_sintab:
	incbin "../data/sinplots/sintab1024.dat"
				ds.b	$600

rot_pal:
	incbin "../data/rotzoom/texture.pal"
	
rot_tmptex:
	incbin "../data/rotzoom/texture.dat"

;********************************************************************

				section "rot_emptychip",bss,chip

				cnop	0,8
rot_screen1:	ds.b	64*numlines*4
rot_screen2:	ds.b	64*numlines*4
rot_screen3:	ds.b	2*16*numlines*4
rot_screen4:	ds.b	2*16*numlines*4
rot_texture:	ds.b	$10000

;********************************************************************

				section "rot_empty",bss

				cnop	0,2
rot_lerpyu:		ds.w	height+1
rot_lerpyv:		ds.w	height+1
rot_modtab:		ds.w	512
rot_techtechtab:
				ds.l	256
rot_tmptex2:	ds.b	64*64
rot_fadetab:	ds.w	16*16*2
				
;********************************************************************

				section "rot_copper",data,chip
			
				cnop	0,2
rot_copperlist:
				dc.l	$008e4490,$00900ca0,$00920030,$009400c0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

rot_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				
rot_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01040038						;bplcon mode, bplcon prios
				dc.l	$0108ffd8,$010affd8						;modulo odd planes, modulo even planes
				dc.l	$01020000								;scroll x odd and even planes
							
				dc.l	$4347fffe
rot_copperfade1:							
				dc.l	$01800fff,$43cffffe,$018009a8,$01004200
rot_copperscale:
				ds.l	(height+1)*4+1
				dc.l	$0c47fffe
rot_copperfade2:	
				dc.l	$01800fff,$0ccffffe,$018009a8

				dc.l	$200ffffe,$009c8010						;wait x: 15, y: 33, start irq
					
				dc.l	$fffffffe 								;wait for end
				
;--------------------------------------------------------------------

				cnop	0,2
rot_sprite1:
				dc.w	$4447,$0c03             ;VSTART, HSTART, VSTOP
				REPT	200
				dc.l	$80008000
				ENDR
				dc.l	0
				
rot_sprite2:
				dc.w	$44cf,$0c02             ;VSTART, HSTART, VSTOP
				REPT	200
				dc.l	$80008000
				ENDR
		
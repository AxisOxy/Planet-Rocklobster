;TODO:	- 

VOXEL_DEPTHS	= 64
VOXEL_WIDTH 	= 160
VOXEL_HEIGHT 	= 100
VOXEL_PLANESIZE	= VOXEL_WIDTH*VOXEL_HEIGHT/4
	
VOXEL_NUMFRAMES		= 1200
	
	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
			
			section	"voxel_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable
		
		;detect aga
		clr.w	voxel_isaga
		moveq	#0,d1
		move.w 	$dff004,d0
		and.w 	#$6f00,d0                      ; 0110111100000000
		cmp.w 	#$2200,d0                      ; 0010001000000000
		beq.b 	.aga
		cmp.w 	#$2300,d0                      ; 0010001100000000
.aga: 
		seq 	d1
		tst.w	d1
		beq.b	.noaga
		move.w	#$6a00,voxel_agafix				;if we have aga, we need to set a correct ham6 mode.
												;the "ham7" needed for the dma-hack, doesnt work here.
		move.w	#1,voxel_isaga
.noaga:

		bsr.w	voxel_init
		
		bsr.w	voxel_step
		bsr.w	voxel_doframe
		bsr.w	voxel_step
		bsr.w	voxel_doframe
		bsr.w	voxel_step
		bsr.w	voxel_doframe
				
		lea		voxel_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		lea		voxel_coppersprites,a0
		move.l	#voxel_sprite,d0
		move.w	d0,$06(a0)
		swap	d0
		move.w	d0,$02(a0)
				
		move.w	#TIME_VOXEL_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
	
		move.l	#voxel_copperlist,a0
		move.l	#voxel_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		move.w	#$8020,$dff096		;copper, bitplane & sprite dma
			
		bsr.w	voxel_setpal
		clr.w	$dff1a2				;sprite color
	
voxel_main:
		;move.w	#$0008,$dff180
		bsr.w	voxel_doframe
		;move.w	#$000,$dff180
		;bsr.w	vsync
		
		;move.w	voxel_time(pc),d0
		;add.w	d0,d0
		;clr.w	voxel_time
		;lea		voxel_timetab,a0
		;move.w	(a0,d0.w),$dff180
		
		btst	#$06,$bfe001
		beq.b	voxel_end
		
		cmpi.w	#VOXEL_NUMFRAMES,voxel_fadeframe
		blt.b	voxel_main
voxel_end:
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		
		move.w	#$0020,$dff096		;turn off sprite dma
		rts		
		
		cnop	0,4
fw_jumptable:
		dc.l	0
		
voxel_timetab:
		dc.w	$0000,$0fff,$0f00,$00ff,$0f0f,$00f0,$000f,$0ff0
		
;--------------------------------------------------------------------

voxel_init:
		lea		voxel_sintab,a0
		lea		$280(a0),a1
		move.l	a1,a2
		lea		$500(a0),a3
		move.w	#$9f,d7
.sl0:	
		move.w	(a0)+,d0
		move.w	d0,-(a1)
		
		neg.w	d0
		move.w	d0,(a2)+
		move.w	d0,-(a3)
		dbra	d7,.sl0
		
		lea		voxel_sintab,a0
		lea		$500(a0),a1
		move.w	#$27f,d7
.sl1:
		move.w	(a0)+,(a1)+
		dbra	d7,.sl1
		
		move.l	fw_jumptable,a6
		jsr		VSYNC(a6)
		bsr.w	voxel_initcopper
		bsr.w	voxel_initmask
		bsr.w	voxel_inittexture
		bsr.w	voxel_initpersptab
		bsr.w	voxel_initoffsets
		bsr.w	voxel_initshadetab
		rts
		
;--------------------------------------------------------------------

VOXEL_SKYCOL	= $06ae
VOXEL_SKYCOLHAM	= $7bf0

		cnop	0,2
voxel_isaga:
		dc.w	0

voxel_setpal:
		clr.w	$dff106
		lea		$dff180,a0
		clr.w	(a0)+
		move.w	#VOXEL_SKYCOL,(a0)+
		
		tst.w	voxel_isaga
		beq.b	.skip
		move.w	#$0200,$dff106
		lea		$dff180,a0
		clr.w	(a0)+
		clr.w	(a0)+
.skip:
		rts

;--------------------------------------------------------------------

		cnop	0,4
voxel_copperbpl:
		dc.l	0
voxel_agafix:
		dc.w	$7a00
		
voxel_initcopper:
		lea		voxel_copperstretch,a0
		;move.l	#$720ffffe,d0
		move.l	#$1a0ffffe,d0
		
		move.w	#44-1,d7
.l0:	
		move.l	d0,(a0)+
		move.l	#$01001200,(a0)+
		addi.l	#$01000000,d0
		
		move.l	d0,(a0)+
		move.l	#$01000200,(a0)+
		addi.l	#$01000000,d0
		dbra	d7,.l0
	
		move.l	a0,voxel_copperbpl
	
		move.l	#$00e40000,(a0)+						;8 real bitplane pointers
		move.l	#$00e60000,(a0)+
		move.l	#$00e80000,(a0)+
		move.l	#$00ea0000,(a0)+
		move.l	#$00ec0000,(a0)+
		move.l	#$00ee0000,(a0)+
		move.l	#$00f00000,(a0)+
		move.l	#$00f20000,(a0)+
		move.l	#$00f40000,(a0)+
		move.l	#$00f60000,(a0)+
		move.l	#$00f80000,(a0)+
		move.l	#$00fa0000,(a0)+
		move.l	#$00fc0000,(a0)+
		move.l	#$00fe0000,(a0)+
		move.l	#$00e00000,(a0)+
		move.l	#$00e20000,(a0)+
		
		move.l	#$01080000,(a0)+
		move.l	#$010a0000,(a0)+						;modulos

		move.w	#VOXEL_HEIGHT-1,d7
.l1:		
		move.l	d0,(a0)+
		move.w	#$0100,(a0)+
		move.w	voxel_agafix(pc),(a0)+
		addi.l	#$01000000,d0
		
		move.l	d0,(a0)+
		move.l	#$01000200,(a0)+
		addi.l	#$01000000,d0
		
		cmpi.l	#$000ffffe,d0
		bne.b	.skipwrap
		move.l	#$ffdffffe,(a0)+
.skipwrap:
		
		dbra	d7,.l1
		
		move.l	#$01000200,(a0)+	;turn off bitplanes
		move.l	#$fffffffe,(a0)+	;end of copperlist
		rts
		
;--------------------------------------------------------------------

voxel_initmask:
		lea		voxel_mask,a0
		lea		VOXEL_PLANESIZE(a0),a1
		lea		VOXEL_PLANESIZE(a1),a2
		
		move.w	#VOXEL_PLANESIZE/4-1,d7
.l0:
		move.l	#$77777777,(a0)+	;rgbb
		move.l	#$cccccccc,(a1)+	;rgbb
		move.l	#$00000000,(a2)+	;rgbb
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

voxel_inittexture:
		lea		voxel_textureheights+$10000,a0
		lea		voxel_textureheights,a1
		lea		voxel_textureheights+$20000,a2
		move.w	#$7fff,d7
.l0:
		move.b	(a0)+,(a2)+
		move.b	(a1)+,(a2)+
		move.b	(a0)+,(a2)+
		move.b	(a1)+,(a2)+
		dbra	d7,.l0
	
		lea		voxel_textureheights+$20000,a0
		lea		voxel_textureheights,a1
		move.w	#$7fff,d7
.l1:
		move.l	(a0)+,(a1)+
		dbra	d7,.l1
		rts
		
;--------------------------------------------------------------------
		
 MACRO<VOXEL_CALCSHADE>
		move.w	d0,d1
		move.w	d0,d2
		move.w	d0,d3
		move.w	d0,d4
		andi.w	#$0800,d1
		andi.w	#$0400,d2
		andi.w	#$0200,d3
		andi.w	#$0100,d4
		lsl.w	#4,d1	;$0800->$8000
		lsl.w	#1,d2	;$0400->$0800
		lsr.w	#2,d3	;$0200->$0080
		lsr.w	#5,d4	;$0100->$0008
		or.w	d2,d1
		or.w	d3,d1
		or.w	d4,d1	;$8888

		move.w	d0,d2
		move.w	d0,d3
		move.w	d0,d4
		move.w	d0,d5
		andi.w	#$0080,d2
		andi.w	#$0040,d3
		andi.w	#$0020,d4
		andi.w	#$0010,d5
		lsl.w	#7,d2	;$0080->$4000
		lsl.w	#4,d3	;$0040->$0400
		lsl.w	#1,d4	;$0020->$0040
		lsr.w	#2,d5	;$0010->$0004
		or.w	d3,d2
		or.w	d4,d2
		or.w	d5,d2	;$4444

		move.w	d0,d3
		move.w	d0,d4
		move.w	d0,d5
		move.w	d0,d6
		andi.w	#$0008,d3
		andi.w	#$0004,d4
		andi.w	#$0002,d5
		andi.w	#$0001,d6
		lsl.w	#8,d3
		lsl.w	#2,d3	;$0008->$2000
		lsl.w	#7,d4	;$0004->$0200
		lsl.w	#4,d5	;$0002->$0020
		lsl.w	#1,d6	;$0001->$0002
		or.w	d4,d3
		or.w	d5,d3
		or.w	d6,d3	;$2222
		move.w	d3,d4
		lsr.w	#1,d4
		or.w	d4,d3	;$3333
		
		move.w	d1,d0	;$8888
		or.w	d2,d0	;$cccc
		or.w	d3,d0	;$ffff
 ENDM 
		
voxel_initshadetab:
		lea		voxel_shadetab,a0
		
		move.l	#voxel_shadetab,d0
		andi.l	#$ffff0000,d0
		addi.l	#$00010000,d0
		move.l	d0,voxel_shadetabpoi

		lea		voxel_shadetabsrc,a0
		move.l	d0,a1
		move.w	#16*128-1,d7
.l0:
		move.w	(a0)+,d0
		VOXEL_CALCSHADE
		move.w	d0,(a1)+
	
		dbra	d7,.l0
		
		move.w	#VOXEL_SKYCOLHAM,d0
		move.w	#16*128-1,d7
.l1:	
		move.w	d0,(a1)+

		dbra	d7,.l1
		rts
		
;--------------------------------------------------------------------
		
voxel_initpersptab:
		lea		voxel_persptabpacked,a0
		lea		voxel_persptab,a1
		moveq	#128-1,d7
.l1:
		move.l	(a0)+,d1
		move.l	(a0)+,d0
		sub.l	d0,d1
		asr.l	#7,d1
		
		move.w	#99,d4
		
		moveq	#128-1,d6
.l0:
		move.l	d0,d2
		swap	d2
		tst.w	d2
		bpl.b	.cliptop
		moveq	#0,d2
.cliptop:
		cmp.w	d4,d2
		blt.b	.clipbottom
		move.w	d4,d2
.clipbottom:
	
		move.w	d2,d3
		add.w	d3,d3
		add.w	d3,d3
		add.w	d2,d3
		lsl.w	#5,d3		;mulu #160
		
		move.w	d3,(a1)
		adda.w	#256,a1
	
		add.l	d1,d0
		
		dbra	d6,.l0
	
		suba.w	#256*128-2,a1
		
		dbra	d7,.l1
		rts
		
;--------------------------------------------------------------------
		
voxel_initoffsets:
		lea		voxel_offsets,a0
		lea		voxel_offsets+64*480,a1
		lea		voxel_offsetstmp,a2
		move.w	#64*480-1,d7
.l0:
		move.b	(a0)+,d0
		move.b	(a1)+,d1
		
		lsl.w	#8,d1
		move.b	d0,d1
		add.w	d1,d1
		move.w	d1,(a2)+
		
		dbra	d7,.l0
		
		lea		voxel_offsetstmp,a0
		lea		voxel_offsets,a1
		move.w	#64*480/2-1,d7
.l1:
		move.l	(a0)+,(a1)+
		
		dbra	d7,.l1
		rts
		
;--------------------------------------------------------------------

voxel_doframe:
		bsr.w	voxel_clear
		bsr.w	voxel_c2p
		bsr.w	voxel_fill
		bsr.w	voxel_draw
		bsr.w	voxel_updatefade
		
		move.l	fw_jumptable(pc),a6
		jsr		BLTWAIT(a6)
		
		bsr.w	voxel_page
		rts
		
;--------------------------------------------------------------------

voxel_clear:
		move.l	voxel_backbuffers+4,a0
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6
		
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		clr.w	BLTADAT(a6)
		clr.w	BLTBDAT(a6)
		clr.w	BLTCDAT(a6)
		clr.w	BLTCMOD(a6)
		clr.w	BLTDMOD(a6)
		move.l  a0,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #VOXEL_HEIGHT*128+VOXEL_WIDTH/4,BLTSIZE(a6)
		rts
	
;--------------------------------------------------------------------

voxel_step:
		move.w	voxel_moveframe(pc),d0
		addi.w	#2,d0
		cmpi.w	#1280*4,d0
		blt.b	.wrap0
		moveq	#0,d0
.wrap0:
		move.w	d0,voxel_moveframe

		lsr.w	#2,d0
		andi.w	#$ffe,d0
		
		lea		voxel_sintab,a0
		move.w	(a0,d0.w),d1
		muls.w	#12/4,d1
		move.l	d1,voxel_movespeed
		
		move.w	voxel_rotframe(pc),d0
		addq	#4,d0
		cmpi.w	#1280*4,d0
		blt.b	.wrap01
		subi.w	#1280*4,d0
.wrap01:
		move.w	d0,voxel_rotframe
		
		lsr.w	#2,d0
		andi.w	#$ffe,d0
		
		move.w	(a0,d0.w),d1
		muls.w	#10*8/4,d1
		swap	d1
		move.w	d1,voxel_rotystep
		
		move.w	voxel_roty(pc),d0
		add.w	voxel_rotystep(pc),d0
		bpl.b	.wrap1
		addi.w	#640*8,d0
.wrap1:		
		cmpi.w	#640*8,d0
		blt.b	.wrap2
		subi.w	#640*8,d0
.wrap2:
		move.w	d0,voxel_roty
		
		lsr.w	#3,d0
		addi.w	#20,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		add.w	d0,d0	;fast mulu.w #6
		asr.w	#3,d0
		cmpi.w	#480,d0
		blt.b	.bla
		subi.w	#480,d0
.bla:
		ext.l	d0
		lsl.l	#7,d0
		
		move.l	d0,voxel_offsetoffset
		
		move.w	voxel_roty(pc),d0
		lsr.w	#3,d0
		add.w	d0,d0
		lea		voxel_sintab+80*2,a1
		lea		voxel_sintab+240*2,a2
		move.l	voxel_offsetx(pc),d3
		move.l	voxel_offsety(pc),d4
		move.w	(a1,d0.w),d1
		move.w	(a2,d0.w),d2
		ext.l	d1
		ext.l	d2
		move.l	d1,d5
		move.l	d2,d6
		move.l	d5,voxel_dirx
		move.l	d6,voxel_diry
		
		move.l	voxel_movespeed(pc),d1
		moveq	#0,d2
		
		add.l	d1,d3
		add.l	d2,d4
		move.l	d3,voxel_offsetx
		move.l	d4,voxel_offsety
		rts

;--------------------------------------------------------------------

 MACRO<VOXEL_PIXEL1>
		adda.w	(a0)+,a3
		
		move.w	(a3),d1
		move.b	d1,d0
		
		clr.b	d1
		
		move.w	\1*2(a2,d1.w),d4
		cmp.w	d4,d5
		ble.w	.skip\@+\2
		
		move.l	d0,a1
		move.w	(a1),d1
		eor.w	d1,d3
		move.w	d3,(a6,d5.w)
.skip\@:		
		if \3>0 
			add.w	d2,d0
		endc 
 ENDM

 MACRO<VOXEL_PIXEL2>
		adda.w	(a0)+,a3
		
		move.w	(a3),d3
		move.b	d3,d0
		
		clr.b	d3
		
		move.w	\1*2(a2,d3.w),d5
		cmp.w	d5,d4
		ble.w	.skip\@+\2
		
		move.l	d0,a1
		move.w	(a1),d3
		eor.w	d3,d1
		move.w	d1,(a6,d4.w)
.skip\@:		
		if \3>0 
			add.w	d2,d0
		endc 
 ENDM

 MACRO<VOXEL_DOSKY>
		eor.w	#VOXEL_SKYCOLHAM,\2
		move.w	\2,(a6,\3.w)
 ENDM
 
;--------------------------------------------------------------------

	cnop	0,2
voxel_fadeframe:
		dc.w	0
voxel_fadetab:
		dc.w	$0000,$0001,$0112,$0123,$0234,$0235,$0346,$0357
		dc.w	$0357,$0468,$0479,$057a,$058b,$069c,$069d,$06ae

voxel_updatefade:
		move.w	voxel_fadeframe(pc),d0
		cmpi.w	#64,d0
		bgt.b	.fadeout
		
		lsr.w	#2,d0
		cmpi.w	#$0f,d0
		blt.b	.wrap0
		moveq	#$0f,d0
.wrap0:	
		eori.w	#$0f,d0
		lsl.w	#8,d0
		ext.l	d0
		move.l	d0,voxel_fadeoff
		rts
.fadeout:
		sub.w	#VOXEL_NUMFRAMES-32,d0
		neg.w	d0
		bpl.b	.bla
		moveq	#0,d0
.bla:
.dofade:
		lsr.w	#2,d0
		cmpi.w	#$0f,d0
		blt.b	.wrap1
		moveq	#$0f,d0
.wrap1:	
		eori.w	#$0f,d0
		move.w	d0,d1
		addq	#1,d0
		lsl.w	#8,d0
		ext.l	d0
		move.l	d0,voxel_fadeoff
		add.w	d1,d1
		lea		voxel_fadetab,a0
		move.w	(a0,d1.w),d0

		clr.w	$dff106
		move.w	d0,$dff180
		move.w	d0,$dff1a2

		tst.w	voxel_isaga
		beq.b	.skip
		move.w	#$0200,$dff106
		clr.w	$dff180
		clr.w	$dff1a2
.skip:
		rts
 
;--------------------------------------------------------------------

		cnop	0,4
voxel_campoi:
		dc.l	0
voxel_movespeed:
		dc.l	$8000*8
voxel_persptabpoi:
		dc.l	0
voxel_offsetx:
		dc.l	160*65536
voxel_offsety:
		dc.l	32*65536
voxel_dirx:
		dc.l	0
voxel_diry:
		dc.l	0
voxel_camheight:
		dc.w	0
voxel_roty:
		dc.w	0*1
voxel_rotystep:
		dc.w	4
voxel_moveframe:
		dc.w	0
voxel_rotframe:
		dc.w	0
voxel_fadeoff:
		dc.l	128*2*16
voxel_offsetoffset:
		dc.l	0
		
voxel_scrambletab:
		dc.w	$00,$02,$04,$06
		dc.w	$08,$0a,$0c,$0e
		dc.w	$10,$12,$14,$16
		dc.w	$18,$1a,$1c,$1e
		dc.w	$20,$22,$24,$26
		dc.w	$28,$2a,$2c,$2e
		dc.w	$30,$32,$34,$36
		dc.w	$38,$3a,$3c,$3e
		dc.w	$40,$42,$44,$46
		dc.w	$48,$4a,$4c,$4e
		dc.w	$50,$52,$54,$56
		dc.w	$58,$5a,$5c,$5e
		dc.w	$60,$62,$64,$66
		dc.w	$68,$6a,$6c,$6e
		dc.w	$70,$72,$74,$76
		dc.w	$78,$7a,$7c,$7e
		dc.w	$80,$82,$84,$86
		dc.w	$88,$8a,$8c,$8e
		dc.w	$90,$92,$94,$96
		dc.w	$98,$9a,$9c,$9e

voxel_shadetabpoi:
		dc.l	0

voxel_draw:
		move.l	voxel_offsetoffset(pc),d0
		lea		voxel_offsets,a0
		adda.l	d0,a0

		move.l	voxel_offsetx(pc),d3
		move.l	voxel_offsety(pc),d4
		move.l	voxel_dirx(pc),d5
		move.l	voxel_diry(pc),d6
		
		;moveq	#0,d4
		move.l	#12*65536,d4
		swap	d3
		swap	d4
		andi.w	#$ff,d3
		andi.l	#$ff,d4
		lsl.w	#8,d4
		move.b	d3,d4
		add.l	d4,d4
		
		lea		voxel_textureheights+256*512,a3
		adda.l	d4,a3
		move.l	a3,voxel_campoi

		lsl.l	#5,d5
		lsl.l	#5,d6
		move.l	voxel_offsetx(pc),d3
		move.l	voxel_offsety(pc),d4
		;moveq	#0,d4
		move.l	#12*65536,d4
		add.l	d5,d3
		add.l	d6,d4
		moveq	#0,d5
		moveq	#0,d6
		swap	d3
		swap	d4
		andi.w	#$ff,d3
		andi.l	#$ff,d4
		lsl.w	#8,d4
		move.b	d3,d4
		add.l	d4,d4
		lea		voxel_textureheights+256*512,a3
		adda.l	d4,a3
		move.w	#$3f00,d0
		sub.w	(a3),d0
		;clr.b	1(a3)
		;move.b	#$3e,1(a3)
		;andi.w	#$3f00,d0
		move.w	voxel_camheight(pc),d1
		add.w	d1,d1
		add.w	voxel_camheight(pc),d1
		add.w	d0,d1
		lsr.w	#2,d1
		move.w	d1,voxel_camheight

		lea		voxel_persptab,a2
		andi.w	#$ff00,d1
		adda.w	d1,a2
		move.l	a2,voxel_persptabpoi
		
		move.w	$7e(a2),d2
		ext.l	d2
		divu.w	#160,d2
		not.w	d2
		addi.w	#94,d2
		add.w	d2,d2
		
		lea		voxel_scrambletab+VOXEL_WIDTH/2*2,a4
		adda.w	d6,a4
		lea		voxel_blitbuf,a5
		move.l	#voxel_offsetsend,d6
		
		move.w	#VOXEL_WIDTH/2-7,d7
.l0:
		tst.w	(a5)
		beq.b	.skipblit			;we are finished with blits
		
		lea		BLTBASE,a1
		
.bltwait1:
		btst	#$0e,2(a1)
		bne.b	.skipblit			;if blitter is busy, skip blit for this run and try on next
		
		move.w	(a5)+,BLTADAT(a1)
		move.l	(a5)+,BLTBPTR(a1)
		move.l	(a5)+,BLTCPTR(a1)
		move.l	(a5)+,BLTDPTR(a1)
		move.l	(a5)+,BLTCON0(a1)
		move.w	(a5)+,BLTBMOD(a1)
		move.w	(a5)+,BLTSIZE(a1)
.skipblit:

		move.l	voxel_persptabpoi(pc),a2
		move.l	voxel_campoi(pc),a3
		move.l	voxel_backbuffers+0,a6
		adda.w	-(a4),a6
		
		move.w	#$100,d2
		moveq	#0,d3
		move.w	#(VOXEL_HEIGHT-2)*VOXEL_WIDTH,d5

		move.l	voxel_shadetabpoi(pc),d0
		add.l	voxel_fadeoff(pc),d0
		
voxel_offset = .voxel_code2-.voxel_code1
 
.voxel_code1:
		VOXEL_PIXEL1 $00, voxel_offset, 0
		VOXEL_PIXEL2 $01, voxel_offset, 0
		VOXEL_PIXEL1 $02, voxel_offset, 0
		VOXEL_PIXEL2 $03, voxel_offset, 0
		VOXEL_PIXEL1 $04, voxel_offset, 0
		VOXEL_PIXEL2 $05, voxel_offset, 0
		VOXEL_PIXEL1 $06, voxel_offset, 0
		VOXEL_PIXEL2 $07, voxel_offset, 0
		VOXEL_PIXEL1 $08, voxel_offset, 0
		VOXEL_PIXEL2 $09, voxel_offset, 0
		VOXEL_PIXEL1 $0a, voxel_offset, 0
		VOXEL_PIXEL2 $0b, voxel_offset, 0
		VOXEL_PIXEL1 $0c, voxel_offset, 0
		VOXEL_PIXEL2 $0d, voxel_offset, 0
		VOXEL_PIXEL1 $0e, voxel_offset, 0
		VOXEL_PIXEL2 $0f, voxel_offset, 0
		VOXEL_PIXEL1 $10, voxel_offset, 0
		VOXEL_PIXEL2 $11, voxel_offset, 0
		VOXEL_PIXEL1 $12, voxel_offset, 0
		VOXEL_PIXEL2 $13, voxel_offset, 0
		VOXEL_PIXEL1 $14, voxel_offset, 0
		VOXEL_PIXEL2 $15, voxel_offset, 0
		VOXEL_PIXEL1 $16, voxel_offset, 0
		VOXEL_PIXEL2 $17, voxel_offset, 0
		VOXEL_PIXEL1 $18, voxel_offset, 0
		VOXEL_PIXEL2 $19, voxel_offset, 0
		VOXEL_PIXEL1 $1a, voxel_offset, 0
		VOXEL_PIXEL2 $1b, voxel_offset, 0
		VOXEL_PIXEL1 $1c, voxel_offset, 0
		VOXEL_PIXEL2 $1d, voxel_offset, 0
		VOXEL_PIXEL1 $1e, voxel_offset, 0
		VOXEL_PIXEL2 $1f, voxel_offset, 0
		VOXEL_PIXEL1 $20, voxel_offset, 0
		VOXEL_PIXEL2 $21, voxel_offset, 0
		VOXEL_PIXEL1 $22, voxel_offset, 0
		VOXEL_PIXEL2 $23, voxel_offset, 0
		VOXEL_PIXEL1 $24, voxel_offset, 0
		VOXEL_PIXEL2 $25, voxel_offset, 0
		VOXEL_PIXEL1 $26, voxel_offset, 0
		VOXEL_PIXEL2 $27, voxel_offset, 0
		VOXEL_PIXEL1 $28, voxel_offset, 0
		VOXEL_PIXEL2 $29, voxel_offset, 0
		VOXEL_PIXEL1 $2a, voxel_offset, 0
		VOXEL_PIXEL2 $2b, voxel_offset, 0
		VOXEL_PIXEL1 $2c, voxel_offset, 0
		VOXEL_PIXEL2 $2d, voxel_offset, 0
		VOXEL_PIXEL1 $2e, voxel_offset, 0
		VOXEL_PIXEL2 $2f, voxel_offset, 0
		VOXEL_PIXEL1 $30, voxel_offset, $100
		VOXEL_PIXEL2 $31, voxel_offset, $100
		VOXEL_PIXEL1 $32, voxel_offset, $100
		VOXEL_PIXEL2 $33, voxel_offset, $100
		VOXEL_PIXEL1 $34, voxel_offset, $100
		VOXEL_PIXEL2 $35, voxel_offset, $100
		VOXEL_PIXEL1 $36, voxel_offset, $100
		VOXEL_PIXEL2 $37, voxel_offset, $100
		VOXEL_PIXEL1 $38, voxel_offset, $100
		VOXEL_PIXEL2 $39, voxel_offset, $100
		VOXEL_PIXEL1 $3a, voxel_offset, $100
		VOXEL_PIXEL2 $3b, voxel_offset, $100
		VOXEL_PIXEL1 $3c, voxel_offset, $100
		VOXEL_PIXEL2 $3d, voxel_offset, $100
		VOXEL_PIXEL1 $3e, voxel_offset, $100
		VOXEL_PIXEL2 $3f, voxel_offset, $100
		
		VOXEL_DOSKY 0, d3, d5, d1, d4
		
		bra.w	.voxel_codeend

.voxel_code2:
		VOXEL_PIXEL2 $00, -voxel_offset, 0
		VOXEL_PIXEL1 $01, -voxel_offset, 0
		VOXEL_PIXEL2 $02, -voxel_offset, 0
		VOXEL_PIXEL1 $03, -voxel_offset, 0
		VOXEL_PIXEL2 $04, -voxel_offset, 0
		VOXEL_PIXEL1 $05, -voxel_offset, 0
		VOXEL_PIXEL2 $06, -voxel_offset, 0
		VOXEL_PIXEL1 $07, -voxel_offset, 0
		VOXEL_PIXEL2 $08, -voxel_offset, 0
		VOXEL_PIXEL1 $09, -voxel_offset, 0
		VOXEL_PIXEL2 $0a, -voxel_offset, 0
		VOXEL_PIXEL1 $0b, -voxel_offset, 0
		VOXEL_PIXEL2 $0c, -voxel_offset, 0
		VOXEL_PIXEL1 $0d, -voxel_offset, 0
		VOXEL_PIXEL2 $0e, -voxel_offset, 0
		VOXEL_PIXEL1 $0f, -voxel_offset, 0
		VOXEL_PIXEL2 $10, -voxel_offset, 0
		VOXEL_PIXEL1 $11, -voxel_offset, 0
		VOXEL_PIXEL2 $12, -voxel_offset, 0
		VOXEL_PIXEL1 $13, -voxel_offset, 0
		VOXEL_PIXEL2 $14, -voxel_offset, 0
		VOXEL_PIXEL1 $15, -voxel_offset, 0
		VOXEL_PIXEL2 $16, -voxel_offset, 0
		VOXEL_PIXEL1 $17, -voxel_offset, 0
		VOXEL_PIXEL2 $18, -voxel_offset, 0
		VOXEL_PIXEL1 $19, -voxel_offset, 0
		VOXEL_PIXEL2 $1a, -voxel_offset, 0
		VOXEL_PIXEL1 $1b, -voxel_offset, 0
		VOXEL_PIXEL2 $1c, -voxel_offset, 0
		VOXEL_PIXEL1 $1d, -voxel_offset, 0
		VOXEL_PIXEL2 $1e, -voxel_offset, 0
		VOXEL_PIXEL1 $1f, -voxel_offset, 0
		VOXEL_PIXEL2 $20, -voxel_offset, 0
		VOXEL_PIXEL1 $21, -voxel_offset, 0
		VOXEL_PIXEL2 $22, -voxel_offset, 0
		VOXEL_PIXEL1 $23, -voxel_offset, 0
		VOXEL_PIXEL2 $24, -voxel_offset, 0
		VOXEL_PIXEL1 $25, -voxel_offset, 0
		VOXEL_PIXEL2 $26, -voxel_offset, 0
		VOXEL_PIXEL1 $27, -voxel_offset, 0
		VOXEL_PIXEL2 $28, -voxel_offset, 0
		VOXEL_PIXEL1 $29, -voxel_offset, 0
		VOXEL_PIXEL2 $2a, -voxel_offset, 0
		VOXEL_PIXEL1 $2b, -voxel_offset, 0
		VOXEL_PIXEL2 $2c, -voxel_offset, 0
		VOXEL_PIXEL1 $2d, -voxel_offset, 0
		VOXEL_PIXEL2 $2e, -voxel_offset, 0
		VOXEL_PIXEL1 $2f, -voxel_offset, 0
		VOXEL_PIXEL2 $30, -voxel_offset, $100
		VOXEL_PIXEL1 $31, -voxel_offset, $100
		VOXEL_PIXEL2 $32, -voxel_offset, $100
		VOXEL_PIXEL1 $33, -voxel_offset, $100
		VOXEL_PIXEL2 $34, -voxel_offset, $100
		VOXEL_PIXEL1 $35, -voxel_offset, $100
		VOXEL_PIXEL2 $36, -voxel_offset, $100
		VOXEL_PIXEL1 $37, -voxel_offset, $100
		VOXEL_PIXEL2 $38, -voxel_offset, $100
		VOXEL_PIXEL1 $39, -voxel_offset, $100
		VOXEL_PIXEL2 $3a, -voxel_offset, $100
		VOXEL_PIXEL1 $3b, -voxel_offset, $100
		VOXEL_PIXEL2 $3c, -voxel_offset, $100
		VOXEL_PIXEL1 $3d, -voxel_offset, $100
		VOXEL_PIXEL2 $3e, -voxel_offset, $100
		VOXEL_PIXEL1 $3f, -voxel_offset, $100
		
		VOXEL_DOSKY 1, d1, d4, d3, d5
		
.voxel_codeend:
		
		adda.w	#(128-VOXEL_DEPTHS*2),a0
		cmp.l	d6,a0
		blt.b	.wrap2
		lea		voxel_offsets,a0
.wrap2:
		dbra	d7,.l0
		
.doblt:
		lea		BLTBASE,a1
			
		;for savety reasons (faster cpus) we have to do the missing rest of the blits non parallel
.bltloop:
		move.w	(a5)+,d0
		beq.b	.bltend
		
		move.w	#$8400,$096(a1)		;turn on blitter nasty to speed up blits while waiting
.bltwait2:
		btst	#$0e,2(a1)
		bne.b	.bltwait2
		move.w	#$0400,$096(a1)		;turn off blitter nasty
		
		move.w	d0,BLTADAT(a1)
		move.l	(a5)+,BLTBPTR(a1)
		move.l	(a5)+,BLTCPTR(a1)
		move.l	(a5)+,BLTDPTR(a1)
		move.l	(a5)+,BLTCON0(a1)
		move.w	(a5)+,BLTBMOD(a1)
		move.w	(a5)+,BLTSIZE(a1)
		bra.b	.bltloop
.bltend:
		rts
		
;--------------------------------------------------------------------
;src1off
;src1mask
;src1shift
;dstoff
;minterm
 MACRO<VOXEL_C2PBLIT>
		move.w	#\2,(a6)+						;BLTADAT
		lea		\1(a0),a2
		move.l  a2,(a6)+						;BLTBPTR
		lea		\4(a1),a2
		move.l  a2,(a6)+						;BLTCPTR
		move.l  a2,(a6)+						;BLTDPTR
        move.w	#(\3)*4096+\5,(a6)+				;BLTCON0
		move.w	#(\3)*4096,(a6)+				;BLTCON1
		move.w	#6,(a6)+						;BLTBMOD
		
		move.w  #VOXEL_PLANESIZE/4*64+1,(a6)+	;BLTSIZE
			
 ENDM

;--------------------------------------------------------------------
			
		cnop	0,2
saved7:
		dc.w	0
			
voxel_c2p:
		lea		voxel_blitbuf,a6
		
		move.l	voxel_backbuffers+8,a0
		move.l	voxel_screens+0,a1
		adda.w	#VOXEL_PLANESIZE/1*2,a0
		adda.w	#VOXEL_PLANESIZE/4*2,a1
		bsr.w	voxel_c2pblits
		
		move.l	voxel_backbuffers+8,a0
		move.l	voxel_screens+0,a1
		bsr.w	voxel_c2pblits
		
		move.l	a6,voxel_blitbufpoi
		rts
				
voxel_c2pblits:		
		VOXEL_C2PBLIT $00+8, $f000, 12, VOXEL_PLANESIZE*3, $5c0
		VOXEL_C2PBLIT $00+8, $0f00,  8, VOXEL_PLANESIZE*2, $5c0
		VOXEL_C2PBLIT $00+8, $00f0,  4, VOXEL_PLANESIZE*1, $5c0
		VOXEL_C2PBLIT $00+8, $000f,  0, VOXEL_PLANESIZE*0, $5c0
		
		VOXEL_C2PBLIT $02, $f000,  0, VOXEL_PLANESIZE*3, $7ca
		VOXEL_C2PBLIT $02+8, $0f00, 12, VOXEL_PLANESIZE*2, $7ca
		VOXEL_C2PBLIT $02+8, $00f0,  8, VOXEL_PLANESIZE*1, $7ca
		VOXEL_C2PBLIT $02+8, $000f,  4, VOXEL_PLANESIZE*0, $7ca

		VOXEL_C2PBLIT $04, $f000,  4, VOXEL_PLANESIZE*3, $7ca
		VOXEL_C2PBLIT $04, $0f00,  0, VOXEL_PLANESIZE*2, $7ca
		VOXEL_C2PBLIT $04+8, $00f0, 12, VOXEL_PLANESIZE*1, $7ca
		VOXEL_C2PBLIT $04+8, $000f,  8, VOXEL_PLANESIZE*0, $7ca

		VOXEL_C2PBLIT $06, $f000,  8, VOXEL_PLANESIZE*3, $7ca
		VOXEL_C2PBLIT $06, $0f00,  4, VOXEL_PLANESIZE*2, $7ca
		VOXEL_C2PBLIT $06, $00f0,  0, VOXEL_PLANESIZE*1, $7ca
		VOXEL_C2PBLIT $06+8, $000f, 12, VOXEL_PLANESIZE*0, $7ca
		rts
		
;--------------------------------------------------------------------

voxel_blitbufpoi:
		dc.l	0

voxel_fill:
		move.l	voxel_blitbufpoi(pc),a6
		
		move.l	voxel_screens+0,a0
		adda.w	#VOXEL_PLANESIZE*1,a0
		bsr.w	.doblit
		
		move.l	voxel_screens+0,a0
		adda.w	#VOXEL_PLANESIZE*2,a0
		bsr.w	.doblit

		move.l	voxel_screens+0,a0
		adda.w	#VOXEL_PLANESIZE*3,a0
		bsr.w	.doblit

		move.l	voxel_screens+0,a0
		adda.w	#VOXEL_PLANESIZE*4,a0
		bsr.w	.doblit

		clr.w	(a6)+				;end of blits
		move.l	a6,voxel_blitbufpoi
		rts
		
.doblit:
		suba.w	#40,a0
		move.l	a0,a1
		suba.w	#40,a1
		
		move.w	#$ffff,(a6)+		;BLTAFWM
		move.l	a0,(a6)+			;BLTAPTR
		move.l	a1,(a6)+			;BLTCPTR
		move.l	a1,(a6)+			;BLTDPTR
		move.w	#$0766,(a6)+		;BLTCON0: minterm $fa = a|c, channels $b = a&c&d
		move.w	#$0002,(a6)+		;BLTCON1
		clr.w	(a6)+				;BLTAMOD
		move.w  #(VOXEL_HEIGHT*1-2)*64+VOXEL_WIDTH/8,(a6)+
									;BLTSIZE
		rts
		
;--------------------------------------------------------------------

		cnop	0,4
voxel_screens:
		dc.l	voxel_screen1,voxel_screen2,voxel_screen3
voxel_backbuffers:
		dc.l	voxel_backbuffer1,voxel_backbuffer2,voxel_backbuffer3

voxel_page:
		move.l	voxel_backbuffers+0,d0
		move.l	voxel_backbuffers+4,d1
		move.l	voxel_backbuffers+8,d2

		move.l	d1,voxel_backbuffers+0		
		move.l	d2,voxel_backbuffers+4
		move.l	d0,voxel_backbuffers+8

		move.l	voxel_screens+0,d0
		move.l	voxel_screens+4,d1
		move.l	voxel_screens+8,d2

		move.l	d1,voxel_screens+0		
		move.l	d2,voxel_screens+4
		move.l	d0,voxel_screens+8

		move.l	voxel_copperbpl,a6
		lea		voxel_copperbpl2,a5
		
		addq	#2,d0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		addi.l	#VOXEL_PLANESIZE*1,d1
		addi.l	#VOXEL_PLANESIZE*2,d2
		addi.l	#VOXEL_PLANESIZE*3,d3
		
		lea		voxel_mask,a0
		move.l	a0,d4
		move.l	d4,d5
		move.l	d4,d6
		addi.l	#VOXEL_PLANESIZE*1,d5
		addi.l	#VOXEL_PLANESIZE*2,d6
		
		move.l	#voxel_firstline,d7
		move.w	d7,$06(a5)
		swap	d7
		move.w	d7,$02(a5)

		move.w	d1,$06(a6)
		swap	d1
		move.w	d1,$02(a6)

		move.w	d2,$0e(a6)
		swap	d2
		move.w	d2,$0a(a6)
	
		move.w	d3,$16(a6)
		swap	d3
		move.w	d3,$12(a6)

		move.w	d4,$1e(a6)
		swap	d4
		move.w	d4,$1a(a6)

		move.w	d5,$26(a6)
		swap	d5
		move.w	d5,$22(a6)

		move.w	d6,$2e(a6)
		swap	d6
		move.w	d6,$2a(a6)

		move.w	d7,$36(a6)
		swap	d7
		move.w	d7,$32(a6)
	
		move.w	d0,$3e(a6)
		swap	d0
		move.w	d0,$3a(a6)
		rts

;--------------------------------------------------------------------
		
		cnop	0,2
voxel_time:
		dc.w	0
		
voxel_irq:		
		movem.l	d0-d7/a0-a6,-(sp)
	
		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		
		addq.w	#1,voxel_time
		addq.w	#1,voxel_fadeframe

		bsr.w	voxel_step
			
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;********************************************************************
			
				section "voxel_data",data

				cnop	0,8
voxel_textureheights:
		incbin "../data/voxel/texture.dat"
		incbin "../data/voxel/heightmap.dat"
				ds.b	$20000
				
voxel_shadetabsrc:
		incbin "../data/voxel/shadetab.dat"
				
voxel_sintab:
		incbin "../data/voxel/sintab.dat"
				ds.b	2560-320
				
voxel_persptabpacked:
		incbin "../data/voxel/persptabpacked.dat"

voxel_offsets:	
	incbin "../data/voxel/offsets2.dat"
voxel_offsetsend:

;********************************************************************
			
				section "voxel_empty",bss
				
				cnop	0,2
voxel_blitbuf:	ds.w	32*34
voxel_persptab:	ds.w	128*128

voxel_offsetstmp:
voxel_shadetab:	ds.b	$10000+$2000

;********************************************************************
			
				section "voxel_emptychip",bss,chip

				cnop	0,8
voxel_screen1:	ds.b	VOXEL_PLANESIZE*4
voxel_screen2:	ds.b	VOXEL_PLANESIZE*4
voxel_screen3:	ds.b	VOXEL_PLANESIZE*4
voxel_mask:		ds.b	VOXEL_PLANESIZE*3
voxel_backbuffer1:
				ds.b	VOXEL_WIDTH*VOXEL_HEIGHT
voxel_backbuffer2:
				ds.b	VOXEL_WIDTH*VOXEL_HEIGHT
voxel_backbuffer3:
				ds.b	VOXEL_WIDTH*VOXEL_HEIGHT
				
;********************************************************************

				section "voxel_copper",data,chip

voxel_copperlist:
				dc.l	$008e1a85,$009038ad,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

voxel_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020000,$01040038			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$009c8010						;wait x: 15, y: 33, start irq
			
				dc.l	$01187777,$011acccc						;set mask to bpl-dma of plane5 and zero bpl-dma of plane6
				
				dc.l	$0108ffd8,$010affd8						;modulo odd planes, modulo even planes
				
				dc.l	$01001200				
voxel_copperbpl2:	
				dc.l	$00e00000,$00e20000						;1 dummy bitplane pointer for firstline
voxel_copperstretch:
				blk.l	(VOXEL_HEIGHT+44)*6+1,$01800000
				dc.l	$01000200
				
				dc.l	$fffffffe 								;wait for end
				
;--------------------------------------------------------------------

				cnop	0,8
voxel_firstline:
				dc.b	$03
				blk.b	39,$ff

voxel_sprite:
				dc.w	$1c41,$3703             ;VSTART, HSTART, VSTOP
				REPT	249+34
				dc.l	$e0000000
				ENDR
				dc.l	0
NUMWAITFRAMES	= 192
NUMFRAMES		= 576
		
	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

			
			section	"vec_code",code 

vec_ringsize	= 64
vec_numrings	= 64
vec_numrings2	= 44
vec_numplots	= vec_ringsize*vec_numrings2
vec_bltsize		= 1024*vec_numrings2/vec_numrings
vec_bltsize2	= vec_bltsize

			
entrypoint:
		move.l	a6,fw_jumptable
		
		jsr		GETFRAME(a6)
		addi.w	#NUMWAITFRAMES,d0
		move.w	d0,vec_startframe
		addi.w	#NUMFRAMES,d0
		move.w	d0,vec_endframe
		
		bsr.w	vec_init
		
		bsr.w	vec_clear
		bsr.w	vec_page
		bsr.w	vec_clear
		bsr.w	vec_page
		bsr.w	vec_clear
		bsr.w	vec_page
		bsr.w	vec_clear
		bsr.w	vec_page
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
				
		lea		vec_coppersprites,a0
		lea		vec_sprites,a1
		move.l	fw_jumptable(pc),a6
		jsr		SETSPRITES(a6)

		move.w	#TIME_VECPLOTS_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#vec_copperlist,a0
		move.l	#vec_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		move.w	#$8020,$dff096		;copper, bitplane & sprite dma
				
		lea		$dff180,a0
		move.w	#$336,0(a0)
		move.w	#$888,2(a0)
		move.w	#$fff,4(a0)
		move.w	#$fff,6(a0)
		
		lea		vec_spritedat+6,a1
		move.l	(a1),$20(a0)
		move.l	(a1),$28(a0)
		move.l	(a1),$30(a0)
		move.l	#$0ccf0ccf,$38(a0)
		move.l	4(a1),$24(a0)
		move.l	4(a1),$2c(a0)
		move.l	4(a1),$34(a0)
		move.l	#$0ccf0ccf,$3c(a0)
				
vec_main:
		;move.w	#$0008,$dff180
		bsr.w	vec_clear
		bsr.w	vec_plot
		bsr.w	vec_movesprites
		bsr.w	vec_page
		;move.w	#$000,$dff180
		;bsr.w	vsync
.sync:
		tst.w	vec_sync
		beq.b	.sync
		clr.w	vec_sync
		
		btst	#$06,$bfe001
		beq.b	vec_end
		
		move.w	#TIME_VECPLOTS_END,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	vec_main
vec_end:		
		move.l	fw_jumptable,a6
;		jsr		SETBASECOPPER(a6)
		rts		
	
		cnop	0,4
fw_jumptable:
		dc.l	0
vec_startframe:
		dc.w	0
vec_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

vec_init:
		bsr.w	vec_initsprites

		lea		vec_sintab,a0
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

		bsr.w	vec_initrings1
		bsr.w	vec_initrings2
		bsr.w	vec_initrings3
		bsr.w	vec_initmorph
		bsr.w	vec_inittabs	
		bsr.w	vec_initcopper
		
		lea		BLTBASE,a5
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		move.w	#$ffff,BLTALWM(a5)
		clr.w	BLTBMOD(a5)
		clr.w	BLTAMOD(a5)
		clr.w	BLTCMOD(a5)
		
		bsr.w	vec_prepareblits
		rts	

;--------------------------------------------------------------------

vec_initsprites:
		lea		vec_spritedat,a0
		move.w	(a0),d0
		add.w	d0,d0
		addq	#6,a0
		add.w	d0,a0
		
		moveq	#4,d1
		move.w	#256-1,d7
.l0:			
		lea		vec_sprites,a6
		REPT	6
		move.l	(a6)+,a1
		move.l	(a0)+,(a1,d1.w)
		ENDR
		addq	#4,d1
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

vec_initrings1:
		lea		vec_sintab,a0
		lea		vec_sintab+$400,a3
		lea		vec_ringscalesx,a1
		lea		vec_ringscalesz,a2
		
		move.w	#-512*vec_scale,d6
.l0:		
		move.l	#$00008000,d5
		move.l	#4096*65536/vec_ringsize,d4
		
		moveq	#64,d3
		
		move.w	#vec_ringsize/2-1,d7
.l1:
		move.l	d5,d2
		swap	d2
		andi.w	#$ffe,d2
		move.w	(a0,d2.w),d0
		move.w	(a3,d2.w),d1
		
		muls.w	d6,d0
		asr.l	#6,d0
		swap	d0
		add.w	d3,d0
		add.w	d0,d0
		add.w	d0,d0
		move.w	d0,(a1)+

		muls.w	d6,d1
		asr.l	#6,d1
		swap	d1
		add.w	d3,d1
		add.w	d1,d1
		add.w	d1,d1
		move.w	d1,(a2)+

		add.l	d4,d5
		
		dbra	d7,.l1

		addi.w	#vec_scale,d6
		cmpi.w	#512*vec_scale,d6
		bne.b	.l0
		rts
		
;--------------------------------------------------------------------

vec_scale	= 56

vec_initrings2:
		lea		vec_ringoffsets,a2
		
		move.w	#-128*vec_scale,d6
.l2:	
		move.w	#128,d0
		
		move.w	#$1000/12,d5
		
		move.w	#128-1,d7
.l3:
		move.w	d5,d1

		muls.w	d6,d1
		asr.l	#4,d1
		swap	d1
		add.w	d0,d1
		
		move.w	d1,d3
		lsl.w	#8,d3
		or.w	d1,d3
		move.w	d3,(a2)+
		not.w	d3
		move.w	d3,(a2)+

		addi.w	#$1000/32,d5
		
		dbra	d7,.l3
		
		addi.w	#vec_scale,d6
		cmpi.w	#128*vec_scale,d6
		bne.b	.l2
		rts
		
;--------------------------------------------------------------------

vec_initrings3:
		lea		vec_ringsizesxy,a1
		
		move.w	#$00,d5
		
		move.w	#$ff00,d2
		
		move.w	#128-1,d7
.l5:
		move.w	#-512*64,d6
.l4:	
		move.w	d5,d1
		
		muls.w	d6,d1
		swap	d1
		add.w	d1,d1
		add.w	d1,d1
		and.w	d2,d1
		move.w	d1,(a1)+
		move.w	d1,(a1)+
				
		addi.w	#256,d6
		cmpi.w	#512*64,d6
		bne.b	.l4
		
		addi.w	#$1000/32,d5
		
		dbra	d7,.l5
		rts
		
;--------------------------------------------------------------------
	
vec_initmorph:
		lea		vec_ringdata2,a0
		bsr.w	vec_initempty
		lea		vec_ringdata1,a0
		bsr.w	vec_initsphere
		lea		vec_ringpointers+0*64*vec_numrings/2*8,a2
		bsr.w	vec_convobj
				
		lea		vec_ringdata2,a0
		bsr.w	vec_initsphere
		lea		vec_ringdata1,a0
		bsr.w	vec_initdonut
		lea		vec_ringpointers+1*64*vec_numrings/2*8,a2
		bsr.w	vec_convobj
	
		lea		vec_ringdata2,a0
		bsr.w	vec_initdonut
		lea		vec_ringdata1,a0
		bsr.w	vec_initempty
		lea		vec_ringpointers+2*64*vec_numrings/2*8,a2
		bsr.w	vec_convobj
		rts
		
;--------------------------------------------------------------------
	
vec_initsphere:
		lea		vec_sintab+$000,a1
		lea		vec_sintab+$400,a2
		moveq	#vec_numrings/2-1,d7
.l0:
		move.w	(a1),d0
		asr.w	#5,d0
		andi.w	#$1fc,d0
		
		move.w	(a2),d5
		asr.w	#5,d5
		andi.w	#$1fc,d5
		
		move.w	d0,(a0)+
		move.w	d5,(a0)+
		
		adda.w	#2048/vec_numrings2,a2
		adda.w	#2048/vec_numrings2,a1
		
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

vec_initdonut:
		lea		vec_sintab+$040,a1
		lea		vec_sintab+$000,a2
		move.w	#$c00,d6
		moveq	#vec_numrings/2-1,d7
.l0:
		move.w	(a1),d0
		muls.w	#700,d0
		swap	d0
		andi.w	#$1fc,d0

		move.w	(a2,d6.w),d5
		addi.w	#$4000,d5
		muls.w	#700,d5
		swap	d5
		addi.w	#160,d5
		andi.w	#$1fc,d5

		move.w	d0,(a0)+
		move.w	d5,(a0)+
		
		addi.w	#4096/vec_numrings2+1+4,d6
		andi.w	#$ffe,d6
		adda.w	#4096/vec_numrings2+1+4,a1
		
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

vec_initempty:
		moveq	#vec_numrings/2-1,d7
.l0:
		clr.w	d0
		
		move.w	d0,(a0)+
		move.w	d0,(a0)+
		
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

vec_convobj:
		moveq	#64-1,d6
.l1:		
		lea		vec_ringdata1,a0
		lea		vec_ringdata2,a1
		
		moveq	#0,d1
		moveq	#0,d3
		
		move.w	d6,-(sp)
		
		move.w	#$7fff,d0
		muls.w	d6,d0
		divs.w	#63,d0
		move.w	d0,d6
		
		moveq	#vec_numrings/2-1,d7
.l0:
		move.w	(a0)+,d0
		move.w	(a0)+,d5
		
		move.w	(a1)+,d2
		move.w	(a1)+,d4

		sub.w	d0,d2
		sub.w	d5,d4
		
		muls.w	d6,d2
		muls.w	d6,d4
		add.l	d2,d2
		add.l	d4,d4
		swap	d2
		swap	d4
		
		add.w	d2,d0
		add.w	d4,d5
		
		andi.w	#$1fc,d0
		andi.w	#$1fc,d5

		move.w	d0,d2
		sub.w	d1,d0

		move.w	d5,d4		
		sub.w	d3,d5
		ext.l	d5
		lsl.l	#8,d5
		
		subq	#4,d0
		move.w	d0,(a2)+
		move.w	d0,(a2)+
		move.l	d5,(a2)+
		
		move.w	d2,d1
		move.w	d4,d3
		
		dbra	d7,.l0
		
		move.w	(sp)+,d6
		
		dbra	d6,.l1
		rts

;--------------------------------------------------------------------

vec_inittabs:
		lea		vec_sintab,a0
		move.w	#$0a00-1,d7
.l6:
		move.w	(a0),d0
		muls.w	#$7e00,d0
		add.l	d0,d0
		swap	d0
		move.w	d0,(a0)+
		dbra	d7,.l6
		rts
		
;--------------------------------------------------------------------
		
vec_initcopper:
		lea		vec_copperstretch,a0
		move.l	#$2d4ffffe,d0
		move.l	#$2dc7fffe,d1
		move.l	#$01800000,d2
		move.l	#$01800336,d3
		
		move.l	d0,(a0)+
		move.l	#$01800ccf,(a0)+
		move.l	d1,(a0)+
		move.l	#$01800336,(a0)+
		addi.l	#$01000000,d0
		addi.l	#$01000000,d1
		
		move.w	#249-1,d7
.l0:
		move.l	d0,(a0)+
		move.l	d2,(a0)+
		move.l	d1,(a0)+
		move.l	d3,(a0)+
		
		addi.l	#$01000000,d0
		addi.l	#$01000000,d1
		
		cmpi.l	#$004ffffe,d0
		bne.b	.l1
		move.l	#$ffdffffe,(a0)+
.l1:
		cmpi.l	#$384ffffe,d0
		bne.b	.l2
		move.l	#$01002200,(a0)+
.l2:
		cmpi.l	#$184ffffe,d0
		bne.b	.l3
		move.l	#$01001200,(a0)+
.l3:
		dbra	d7,.l0
			
		move.l	d0,(a0)+
		move.l	#$01800ccf,(a0)+
		move.l	d1,(a0)+
		move.l	#$01800336,(a0)+
		
		move.l	#$009c8010,(a0)+	;start irq
		move.l	#$fffffffe,(a0)+	;wait for end
		rts
		
;--------------------------------------------------------------------
		
 MACRO<VEC_SETSPRITE>
		move.l	(a0)+,a1
		move.b	d1,1(a1)
		move.b	d0,3(a1)
		addq	#8,d1
		cmpi.w	#$e5,d1
		blt.b	.clip\@
		move.w	#$e5,d1
.clip\@:
 ENDM 
		
		cnop	0,2
vec_spriteframe:
		dc.w	0
		
vec_movesprites:
		addq.w	#1,vec_spriteframe
		move.w	vec_spriteframe(pc),d0
		
		cmpi.w	#64,d0
		bge.b	.fadeout
		bra.b	.domove
		
.fadeout:
		neg.w	d0
		add.w	#NUMFRAMES,d0
		cmpi.w	#64,d0
		bge.w	.skip
	
.domove:
		lsl.w	#4,d0
		lea		vec_sintab+$800,a0
		move.w	(a0,d0.w),d1
		asr.w	#7,d1
		move.w	d1,d0
		asr.w	#1,d1
		andi.w	#1,d0
		addq	#2,d0
		addi.w	#242,d1		;242->178
		
		lea		vec_sprites,a0
		REPT	6
		VEC_SETSPRITE
		ENDR
.skip:
		rts
				
;--------------------------------------------------------------------

vec_clear:
		move.l	vec_screens+0,a0
		adda.w	#32*16,a0
		
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		move.w	#$0000,BLTADAT(a6)
		move.w	#4,BLTDMOD(a6)
		move.l  a0,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #$780e,BLTSIZE(a6)
		;bsr.w	bltwait
		rts
		
;--------------------------------------------------------------------

			cnop 0,4
vec_frame	dc.w	0
rx:			dc.w 	$580+56*18
ry:			dc.w 	$580+56*14
rz:			dc.w 	$580+56*10
tmps:		ds.w	3
mat:		ds.w 	9
refring:	ds.w	vec_ringsize*2

vec_plot:
		addq.w	#1,vec_frame
				
		moveq	#18,d4
		moveq	#14,d5
		moveq	#10,d6

		move.w	vec_frame(pc),d0		
		addi.w	#$54,d0
		andi.w	#$ff,d0
		cmpi.w	#$e8,d0
		bgt.b	.bla
		neg.w	d4
		neg.w	d5
		neg.w	d6
.bla:	
				
		move.w	rx,d0
		add.w	d4,d0
		andi.w	#$ffe,d0
		move.w	d0,rx

		move.w	ry,d1
		add.w	d5,d1
		andi.w	#$ffe,d1
		move.w	d1,ry
		
		move.w	rz,d2
		add.w	d6,d2
		andi.w	#$ffe,d2
		move.w	d2,rz

		lea		vec_sintab,a0
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
	;	asr.w	#3,d6
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
	;	asr.w	#3,d6
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
	;	asr.w	#3,d6
		move.w	d6,16(a3)		;-cx*cy

		lea		vec_ringscalesx,a0
		lea		vec_ringscalesx,a1
		lea		vec_ringscalesx,a2
		lea		vec_ringscalesz,a3
		lea		vec_ringscalesz,a4
		lea		vec_ringscalesz,a5
		lea		mat,a6
	
		movem.w	(a6),d0-d5
		move.w	#$ffe0,d6
		and.w	d6,d0
		and.w	d6,d1
		and.w	d6,d2
		and.w	d6,d3
		and.w	d6,d4
		and.w	d6,d5
		move.w	#$4000,d6
		add.w	d6,d0
		add.w	d6,d1
		add.w	d6,d2
		add.w	d6,d3		
		add.w	d6,d4		
		add.w	d6,d5		
		ext.l	d0
		ext.l	d1
		ext.l	d2
		ext.l	d3
		ext.l	d4
		ext.l	d5
		add.l	d0,d0
		add.l	d1,d1
		add.l	d2,d2
		add.l	d3,d3
		add.l	d4,d4
		add.l	d5,d5
		adda.l	d0,a0
		adda.l	d1,a1
		adda.l	d2,a2
		adda.l	d3,a3
		adda.l	d4,a4
		adda.l	d5,a5
		lea		.smc+2,a6
		
 MACRO<VEC_SMC>
		add.w	(a3)+,\1
		move.w	\1,\4(a6)
		add.w	(a4)+,\2
		addq	#2,\2
		move.w	\2,\4+4(a6)
		
		add.w	(a5)+,\3
		move.w	\3,\5(a6)
 ENDM
		
		rept	vec_ringsize/16

		move.w	(a0)+,d0
		move.w	(a0)+,d1
		move.w	(a1)+,d4
		move.w	(a1)+,d5
		move.w	(a2)+,d2
		move.w	(a2)+,d3
		VEC_SMC	d0, d4, d2,  0,  96
		VEC_SMC	d1, d5, d3, 10, 102
		
		move.w	(a0)+,d0
		move.w	(a0)+,d1
		move.w	(a1)+,d4
		move.w	(a1)+,d5
		move.w	(a2)+,d2
		move.w	(a2)+,d3
		VEC_SMC	d0, d4, d2, 20, 108
		VEC_SMC	d1, d5, d3, 30, 114
		
		move.w	(a0)+,d0
		move.w	(a0)+,d1
		move.w	(a1)+,d4
		move.w	(a1)+,d5
		move.w	(a2)+,d2
		move.w	(a2)+,d3
		VEC_SMC	d0, d4, d2, 40, 120
		VEC_SMC	d1, d5, d3, 50, 126
		
		move.w	(a0)+,d0
		move.w	(a0)+,d1
		move.w	(a1)+,d4
		move.w	(a1)+,d5
		move.w	(a2)+,d2
		move.w	(a2)+,d3
		VEC_SMC	d0, d4, d2, 60, 132
		VEC_SMC	d1, d5, d3, 70, 138
		
		lea		160(a6),a6	
		endr

		move.l	vec_bltbufs+0,a5
		lea		mat,a1
		lea		vec_ringsizesxy,a2
		
		move.w	12(a1),d4
		move.w	14(a1),d5
		move.w	16(a1),d6
		lea		vec_ringoffsets,a4
		lea		vec_ringoffsets,a3
		lea		vec_ringoffsets,a0
		moveq	#$ffffff80,d0
		and.w	d0,d4
		and.w	d0,d5
		and.w	d0,d6
		move.w	#512*32,d0
		add.w	d0,d4
		add.w	d0,d5
		add.w	d0,d6
		ext.l	d4
		ext.l	d5
		ext.l	d6
		lsl.l	#2,d4
		lsl.l	#2,d5
		lsl.l	#2,d6
		adda.l	d4,a4
		adda.l	d5,a3
		adda.l	d6,a0
		
		lea		vec_ringpointers,a1
		
		move.w	vec_frame(pc),d1
		move.w	d1,d0
		andi.w	#$ff,d1
		cmpi.w	#$3f,d1
		blt.b	.nopingpongwrap
		moveq	#$3f,d1
.nopingpongwrap:
		lsl.w	#8,d1
		adda.w	d1,a1
		
		andi.w	#$300,d0
		lsr.w	#8,d0
		mulu.w	#64*vec_numrings/2*8,d0
		add.l	d0,a1
 		
		move.l	vec_coords+0,a6
		adda.w	#vec_numplots,a6
		
		moveq	#vec_numrings2/2-1,d7
.l0:		
		move.w	(a5),d0
		beq.b	.skipblt
		
		btst	#$0e,$dff002
		bne.b	.skipblt

		addq	#2,a5
		
		move.l	a2,-(sp)

		lea		BLTBASE,a2
		move.w	d0,BLTAFWM(a2)
		move.w	#$2,BLTDMOD(a2)
		move.w	(a5)+,BLTCMOD(a2)
		move.l	(a5)+,BLTAPTR(a2)
		move.l	(a5)+,BLTBPTR(a2)
		move.l	(a5)+,BLTCPTR(a2)
		move.l	(a5)+,BLTDPTR(a2)
		move.l	(a5)+,BLTCON0(a2)
		move.w	(a5)+,BLTADAT(a2)
		move.w	(a5)+,BLTCDAT(a2)
		move.w	(a5)+,BLTSIZE(a2)
		
		move.l	(sp)+,a2
		
.skipblt:				
		move.w	(a3)+,d0
		move.w	(a3)+,d1
		move.w	(a4)+,d2
		move.w	(a4)+,d3
		move.w	(a0)+,d4
		move.w	(a0)+,d5
		adda.w	(a1),a0
		adda.w	(a1)+,a3
		adda.w	(a1)+,a4
		adda.l	(a1)+,a2
		
		sub.w	d0,d1
		sub.w	d2,d3
		sub.w	d4,d5
		move.b	d0,d2
		move.b	d1,d3
		
		move.w	d2,d0
		swap	d0
		move.w	d2,d0
		
		move.w	d3,d1
		swap	d1
		move.w	d3,d1
		
		move.w	d4,d6
		swap	d4
		move.w	d6,d4

		move.w	d5,d6
		swap	d5
		move.w	d6,d5
		
		move.l	a5,-(sp)
		move.w	d7,-(sp)
		
		lea		vec_numplots(a6),a5

 MACRO<VEC_PLOT_XY>
		move.w	$100(a2),\1
		move.b	$100(a2),\1
		swap	\1
		move.w	$100(a2),\1
		move.b	$100(a2),\1
		add.l	d0,\1
 ENDM
 
 MACRO<VEC_WRITE_XY>
		movem.l	d2/d3/d6/d7,-(a6)
		add.l	d1,d2
		add.l	d1,d3
		add.l	d1,d6
		add.l	d1,d7
		movem.l	d2/d3/d6/d7,-(a6)
 ENDM	
	
 MACRO<VEC_PLOT_Z>
		move.w	$100(a2),\1
		swap	\1
		move.w	$100(a2),\1
		add.l	d4,\1
 ENDM	
		
 MACRO<VEC_WRITE_Z>
		movem.l	d2/d3/d6/d7,-(a5)
		add.l	d5,d2
		add.l	d5,d3
		add.l	d5,d6
		add.l	d5,d7
		movem.l	d2/d3/d6/d7,-(a5)
 ENDM

.smc:		
		rept	vec_ringsize/16

		VEC_PLOT_XY d2
		VEC_PLOT_XY d3
		VEC_PLOT_XY d6
		VEC_PLOT_XY d7
		VEC_WRITE_XY
		
		VEC_PLOT_Z d2
		VEC_PLOT_Z d3
		VEC_PLOT_Z d6
		VEC_PLOT_Z d7
		VEC_WRITE_Z
		
		endr
	
		move.w	(sp)+,d7
		move.l	(sp)+,a5
		
		dbra	d7,.l0
	
 MACRO<VEC_BLT3>
		jsr		BLTWAIT(a6)
		
		move.w	#$ffff,BLTAFWM(a5)
		move.w	#2,BLTCMOD(a5)
		move.l	\4+4,a3
		adda.w	#2+(\1+\3)*4,a3
		clr.l 	BLTBPTR(a5)
		move.l  a3,BLTCPTR(a5)
		move.l  a3,BLTDPTR(a5)
        move.l	#$035a0000,BLTCON0(a5)	; source: B, mintern: a^c
		move.l	#$3fff0000,BLTADAT(a5)
		move.w  #\2*64+1,BLTSIZE(a5)
 ENDM
 		
		move.l	fw_jumptable,a6
		lea		BLTBASE,a5
		
		move.l	vec_screens+4,a0
		subq	#2,a0

		moveq	#7,d0
		moveq	#6,d1
		moveq	#5,d2
		moveq	#4,d3
		moveq	#3,d4
		moveq	#2,d5
		moveq	#1,d6
		moveq	#0,d7

		move.l	vec_plotcodes1+4,a2
		jsr		(a2)
		VEC_BLT3 0, vec_bltsize2, 0, vec_plotcodes1
				
		move.l	vec_plotcodes2+4,a2
		jsr		(a2)
		VEC_BLT3 0, vec_bltsize2, 0, vec_plotcodes2
				
		moveq	#0,d0
		moveq	#1,d1
		moveq	#2,d2
		moveq	#3,d3
		moveq	#4,d4
		moveq	#5,d5
		moveq	#6,d6
		moveq	#7,d7
	
		move.l	vec_plotcodes1+4,a2
		jsr		(a2)
		
		move.l	vec_plotcodes2+4,a2
		jmp		(a2)
		
;--------------------------------------------------------------------
	
 MACRO<VEC_BLT1>
		move.w	#$ffff,(a6)+		;BLTAFWM
		clr.w	(a6)+				;BLTCMOD
		move.l	vec_coords+4,a0
		adda.w	#\1*2,a0
		move.l	\4+0,a1
		subq	#4,a1
		clr.l	(a6)+				;BLTAPTR	
		move.l  a0,(a6)+			;BLTBPTR
		clr.l	(a6)+				;BLTCPTR
		move.l  a1,(a6)+			;BLTDPTR
        move.l	#$05787000,(a6)+	;BLTCON0 BLTCON1 	source: B, B shift 7, minterm: (B & A) | C
		move.l	#$01e80e00,(a6)+	;BLTADAT BLTCDAT
		move.w  #\2*64+1,(a6)+		;BLTSIZE		
 ENDM 

 MACRO<VEC_BLT2>
		move.w	#$8000,(a6)+		;BLTAFWM
		clr.w	(a6)+				;BLTCMOD
		move.l	vec_coords+4,a0
		adda.w	#\1*2,a0
		move.l	\4+0,a1
		addq	#2,a1
		lea		vec_numplots(a0),a2
		move.l	a2,(a6)+			;BLTAPTR	
		move.l  a0,(a6)+			;BLTBPTR
		move.l  a0,(a6)+			;BLTCPTR
		move.l  a1,(a6)+			;BLTDPTR
        move.l	#$2d783000,(a6)+	;BLTCON0 BLTCON1	source: B, B shift 3, minterm: B&C
		move.l	#$00001fff,(a6)+	;BLTADAT BLTCDAT
		move.w  #\2*64+1,(a6)+		;BLTSIZE
 ENDM
 
vec_prepareblits:
		lea		vec_bltbuf1,a6
		bsr.w	.do
		bsr.w	vec_page
		lea		vec_bltbuf2,a6
		bsr.w	.do
		bsr.w	vec_page
		rts
		
.do:
		VEC_BLT1 0, (vec_bltsize2+1), 0, vec_plotcodes1
		VEC_BLT2 0, (vec_bltsize2+0), 0, vec_plotcodes1
		VEC_BLT1 vec_bltsize2, (vec_bltsize2+1), 0, vec_plotcodes2
		VEC_BLT2 vec_bltsize2, (vec_bltsize2+0), 0, vec_plotcodes2
		clr.w	(a6)+
		rts
		
;--------------------------------------------------------------------

vec_coords:
		dc.l	vec_coord1,vec_coord2
vec_plotcodes1:
		dc.l	vec_plotcode11,vec_plotcode21
vec_plotcodes2:
		dc.l	vec_plotcode12,vec_plotcode22
vec_bltbufs:
		dc.l	vec_bltbuf1,vec_bltbuf2
vec_screens:
		dc.l	vec_screen1,vec_screen2,vec_screen3

vec_page:
		lea 	vec_coords,a0
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	d0,$04(a0)
		move.l	d1,$00(a0)

		lea 	vec_plotcodes1,a0
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	d0,$04(a0)
		move.l	d1,$00(a0)		

		lea 	vec_plotcodes2,a0
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	d0,$04(a0)
		move.l	d1,$00(a0)		
	
		lea 	vec_bltbufs,a0
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	d0,$04(a0)
		move.l	d1,$00(a0)

		lea 	vec_screens,a0

		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)

		addi.l	#32*5,d1
	
		move.l	d1,d2
		addi.l	#$2000+32*10,d2
	
		lea		vec_copperbpl,a6
		
		move.w	d1,$06(a6)
		swap	d1
		move.w	d1,$02(a6)

		move.w	d2,$0e(a6)
		swap	d2
		move.w	d2,$0a(a6)
		rts

;--------------------------------------------------------------------
		
		cnop	0,2
vec_sync:
		dc.w	0
		
vec_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		addq.w	#1,vec_sync
	
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
vec_sprites:
		dc.l	vec_sprite3
		dc.l	vec_sprite4
		dc.l	vec_sprite5
		dc.l	vec_sprite6
		dc.l	vec_sprite7
		dc.l	vec_sprite8
		dc.l	vec_sprite1
		dc.l	vec_sprite2
		
;********************************************************************
			
				section "vec_data",data

				cnop	0,2
vec_sintab:		
	incbin "../data/sinplots/sintab2048.dat"
				ds.b	4096	
vec_spritedat:
	incbin "../data/vecplots/overlay4.spr"
				
;********************************************************************
			
				section "vec_empty",bss
				
				cnop	0,2
vec_ringscalesx:
				ds.w	vec_ringsize/2*1024
vec_ringscalesz:
				ds.w	vec_ringsize/2*1024
vec_ringsizesxy:
				ds.w	vec_numrings*1024
vec_ringoffsets:
				ds.w	vec_numrings*1024
vec_ringdata1:
				ds.b 	vec_numrings/2*4
vec_ringdata2:
				ds.b 	vec_numrings/2*4
vec_ringpointers:
				ds.b	3*64*vec_numrings/2*8

;********************************************************************
			
				section "vec_emptychip",bss,chip

				cnop	0,8
vec_screen1:	ds.b	$4000
vec_screen2:	ds.b	$4000
vec_screen3:	ds.b	$4000
vec_bltbuf1:	ds.b	32*10+4
vec_bltbuf2:	ds.b	32*10+4

;********************************************************************

				section "vec_copper",data,chip

vec_copperlist:
				dc.l	$008e2e81,$00902ec9,$00920048,$009400b0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

vec_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;2 bitplane pointer
						
vec_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020088,$01040038			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080004,$010a0004						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01001200						;wait x: 15, y: 1, turn on 1 bitplanes

vec_copperstretch:
				blk.l	4*256+3,$01880000
				
				dc.l	$009c8010								;start irq
	
				dc.l	$fffffffe 								;wait for end
		
;--------------------------------------------------------------------
		
				cnop	0,2
vec_sprite1:
				dc.w	$2e4f,$2703             ;VSTART, HSTART, VSTOP
				REPT	249
				dc.l	$80008000
				ENDR
				dc.l	0
				
vec_sprite2:
				dc.w	$2ec7,$2702             ;VSTART, HSTART, VSTOP
				REPT	249
				dc.l	$80008000
				ENDR
				dc.l	0
				
vec_sprite3:
				dc.w	$2eff,$2e02             ;VSTART, HSTART, VSTOP
				ds.l	256+1
vec_sprite4:
				dc.w	$2eff,$2e02             ;VSTART, HSTART, VSTOP
				ds.l	256+1
vec_sprite5:
				dc.w	$2eff,$2e02             ;VSTART, HSTART, VSTOP
				ds.l	256+1
vec_sprite6:
				dc.w	$2eff,$2e02             ;VSTART, HSTART, VSTOP
				ds.l	256+1
vec_sprite7:
				dc.w	$2eff,$2e02             ;VSTART, HSTART, VSTOP
				ds.l	256+1
vec_sprite8:
				dc.w	$2eff,$2e02             ;VSTART, HSTART, VSTOP
				ds.l	256+1
				
;--------------------------------------------------------------------
	
				cnop	0,2
				ds.b	16
vec_coord1:		ds.w	vec_numplots
vec_coord2:		ds.w	vec_numplots
				ds.b	16
			
				ds.b	16
vec_plotcode11:	
				REPT	vec_numplots/4
				bset.b	d0,1(a0)
				ENDR
				rts
				ds.b	16
				
				ds.b	16
vec_plotcode12:	
				REPT	vec_numplots/4
				bset.b	d0,1(a0)
				ENDR
				rts
				ds.b	16
				
				ds.b	16
vec_plotcode21:	
				REPT	vec_numplots/4
				bset.b	d0,1(a0)
				ENDR
				rts
				ds.b	16
				
				ds.b	16
vec_plotcode22:	
				REPT	vec_numplots/4
				bset.b	d0,1(a0)
				ENDR
				rts
				ds.b	16

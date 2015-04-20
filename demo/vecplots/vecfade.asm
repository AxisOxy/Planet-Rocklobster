	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

			
			section	"vecfade_code",code 

entrypoint:
		bra.b	vecfade_start
		bra.w	vecfade_end
		
		
vecfade_start:
		move.l	a6,fw_jumptable
	
		lea		vecfade_fadecopperbpl,a6
		move.l	#vecfade_fadebpl,d0
		move.l	d0,d1
		addi.l	#48,d1
		move.w	d0,6(a6)
		swap	d0
		move.w	d0,2(a6)
		move.w	d1,14(a6)
		swap	d1
		move.w	d1,10(a6)
				
		lea		vecfade_fadecopperstretch,a6
		move.w	fadecols+0,d0
		move.w	fadecols2+0,d1
		move.w	d0,38(a6)
		move.w	d0,42(a6)
		move.w	d0,46(a6)
		move.w	d0,50(a6)
		
		move.w	d1,6(a6)
		move.w	d1,10(a6)
		move.w	d1,30(a6)		
		
		bsr.w	updatefade
		bsr.w	updatefadecols
		
		move.l	fw_jumptable(pc),a6
		jsr		GETFRAME(a6)
		addi.w	#256,d0
		move.w	d0,vectrans_endframe
		
		lea		vecfade_fadecoppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
	
		move.w	#waitname,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
				
		move.l	#vecfade_fadecopperlist,a0
		move.l	#vecfade_fadeirq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		move.w	#$0020,$dff096		;turn off sprite dma
		
		lea		$dff180,a0
		move.w	fadecols+0,d0
		REPT	4
		move.w	d0,(a0)+
		ENDR
		rts
	
vecfade_end:
		rts		
		
		cnop	0,4
fw_jumptable:
		dc.l	0
vectrans_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

vecfade_fadeirq:		
		movem.l	d0-d7/a0-a6,-(sp)

		bsr.w	updatefade
		bsr.w	updatefadecols
		
		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
						
;--------------------------------------------------------------------

		cnop	0,2
fadeframe:
		dc.w	0
fadepos:	
		dc.w	fademinxstart*64,fademaxxstart*64,fademinystart*64,fademaxystart*64
fadegoals:	
		dc.w	fademinxgoal*64,fademaxxgoal*64,fademinygoal*64,fademaxygoal*64
fadevels:	
		dc.w	0,0,0,0
fadeforces:	
		dc.w	0,0,0,0

fademasksleft:
		dc.w	$ffff,$7fff,$3fff,$1fff,$0fff,$07ff,$03ff,$01ff,$00ff,$007f,$003f,$001f,$000f,$0007,$0003,$0001
		dc.w	$8000,$4000,$2000,$1000,$0800,$0400,$0200,$0100,$0080,$0040,$0020,$0010,$0008,$0004,$0002,$0001
	
fademasksright:
		dc.w	$ffff,$fffe,$fffc,$fff8,$fff0,$ffe0,$ffc0,$ff80,$ff00,$fe00,$fc00,$f800,$f000,$e000,$c000,$8000
		dc.w	$0001,$0002,$0004,$0008,$0010,$0020,$0040,$0080,$0100,$0200,$0400,$0800,$1000,$2000,$4000,$8000

 MACRO<FADE_CLIP>
	asr.w	#6,\1
	bpl.b	.skip1\@
	moveq	#0,\1
.skip1\@:
	cmpi.w	#\2,\1
	blt.b	.skip2\@
	move.w	#\2,\1
.skip2\@:
		
 ENDM
		
updatefade:
		addq.w	#1,fadeframe

		lea		fadepos,a0
		lea		fadegoals,a1
		lea		fadevels,a2
		lea		fadeforces,a3
		moveq	#4-1,d7
.l00:		
		move.w	(a0),d0
		move.w	(a3),d1
		move.w	(a2),d2
		sub.w	(a1)+,d0
		neg.w	d0
		muls.w	#fadestiffness,d0
		swap	d0
		add.w	d0,d1
		muls.w	#fadedamping1,d1
		add.l	d1,d1
		swap	d1
		move.w	d1,(a3)+
		
		add.w	d1,d2
		muls.w	#fadedamping2,d2
		add.l	d2,d2
		swap	d2
		move.w	d2,(a2)+

		move.w	(a0),d0
		add.w	d2,d0
		move.w	d0,(a0)+
		
		dbra	d7,.l00
		
		lea		fadepos,a0
		movem.w	(a0)+,d0-d3
		FADE_CLIP d0, 367
		FADE_CLIP d1, 367
		FADE_CLIP d2, 285
		FADE_CLIP d3, 285
		
		lea		vecfade_fadebpl,a0
		moveq	#0,d4
		REPT 	48*2/4
		move.l	d4,(a0)+
		ENDR

		lea		vecfade_fadebpl,a0
		lea		fademasksleft,a1
		lea		fademasksright,a2
		
		move.w	d0,d4
		lsr.w	#4,d4
		andi.w	#$1f,d4
		
		move.w	d1,d5
		lsr.w	#4,d5
		andi.w	#$1f,d5
		sub.w	d4,d5
		subq	#1,d5
		bmi.b	.skip

		add.w	d4,d4
		move.w	#$ffff,d6
		lea		(a0,d4.w),a3
.l1:
		move.w	d6,(a3)+
		dbra	d5,.l1
		
.skip:		
		
		move.w	d0,d4
		andi.w	#$0f,d4
		add.w	d4,d4
		lsr.w	#3,d0
		andi.w	#$3e,d0
		move.w	(a1,d4.w),(a0,d0.w)
		move.w	32(a1,d4.w),48(a0,d0.w)

		move.w	d1,d4
		not.w	d4
		andi.w	#$0f,d4
		add.w	d4,d4
		lsr.w	#3,d1
		andi.w	#$3e,d1
		move.w	(a2,d4.w),(a0,d1.w)
		move.w	32(a2,d4.w),48(a0,d1.w)
		
		lea		vecfade_fadecopperstretch,a0
		addi.w	#$1c,d2
		cmpi.w	#$22,d2
		bgt.b	.bla3
		move.w	#$22,d2
.bla3:
		lsl.w	#8,d2
		or.w	#$0f,d2
		move.w	d2,0(a0)
		or.w	#$d0,d2
		move.w	d2,12(a0)
		
		addi.w	#$1c,d3
		cmpi.w	#$133,d3
		blt.b	.bla2
		move.w	#$133,d3
.bla2:
		move.w	d3,d4
		lsl.w	#8,d3
		or.w	#$df,d3
		move.w	d3,32(a0)
		subi.w	#$0d0,d3
		move.w	d3,24(a0)
		subi.w	#$0010,d3
		cmpi.w	#$100,d4
		blt.b	.bla
		move.w	#$ffdf,d3
.bla:
		move.w	d3,20(a0)
		rts

;--------------------------------------------------------------------

updatefadecols:
		move.w	fadeframe(pc),d0
		lsr.w	#2,d0
		subi.w	#45,d0
		bmi.b	.skip
		cmpi.w	#6,d0
		bgt.b	.skip
		add.w	d0,d0
		lea		fadecols,a0
		lea		fadecols2,a2
		lea		vecfade_fadecopperstretch,a1
	
		move.w	(a2,d0.w),d1
		move.w	(a0,d0.w),d0
		move.w	d0,38(a1)
		move.w	d0,42(a1)
		move.w	d0,46(a1)
		move.w	d0,50(a1)
		move.w	d1,6(a1)
		move.w	d1,10(a1)
		move.w	d1,30(a1)
.skip:
		rts

;********************************************************************
		
				section "vecfade_copper",data,chip
			
vecfade_fadecopperlist:
				dc.l	$008e2481,$009034c9,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
				
vecfade_fadecopperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;2 bitplane pointer
				
vecfade_fadecoppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01040000						;bplcon mode, bplcon prios
				dc.l	$0108ffd2,$010affd2						;modulo odd planes, modulo even planes
				dc.l	$01020000								;scroll x odd and even planes
				dc.l	$01002200								;wait x: 15, y: 1, turn on 2 bitplanes
							
vecfade_fadecopperstretch:
				dc.l	$300ffffe,$01820fff,$01860fff
				dc.l	$310ffffe,$01820000
				dc.l	$fe0ffffe
				dc.l	$fe1ffffe,$01820fff
				dc.l	$ff0ffffe,$01800000,$01820000,$01840000,$01860000
			
				dc.l	$009c8010								;wait x: 15, y: 33, start irq
					
				dc.l	$fffffffe 								;wait for end
	
;********************************************************************
	
					cnop	0,8
vecfade_fadebpl:	ds.b	48*2
					
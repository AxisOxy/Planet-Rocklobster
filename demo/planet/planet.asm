	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
			
			section	"planet_code",code 
		
entrypoint:
		bra.b	planet_start
		bra.b	planet_end

planet_start:
		move.l	a6,fw_jumptable

		bsr.w	planet_startfade
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#500,d0
		move.w	d0,planet_endframe
		rts
		
planet_end:
		rts
		
		cnop	0,4
fw_jumptable:
		dc.l	0
planet_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

planet_startfade:
		lea		planet_copperfadesprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)

		lea		planet_mask2,a1
		move.w	#$0000,d2
		move.w	#$ffff,d3
		move.w	#286/4-1,d6
.l1:
		move.w	#46/2-1,d7
.l0:	
		move.w	d2,(a1)+
		move.w	d3,46-2(a1)
		
		dbra	d7,.l0

		adda.w	#46,a1
		
		dbra	d6,.l1
						
		lea		planet_mask1,a0
		lea		planet_mask3,a2
		move.w	#$5555,d0
		move.w	#$aaaa,d1
		move.w	#$ffff,d3
		moveq	#46/2-1,d7
.l01:
		move.w	d0,(a0)+
		move.w	d3,(a2)+
		dbra	d7,.l01
		
		move.l	#planet_mask1,d0
		move.l	#planet_mask2,d1
		move.l	#planet_mask3,d2
		move.l	#planet_mask4,d3
		lea		planet_copperbpl1,a5
		lea		planet_copperbpl2,a6
		move.w	d3,$06(a5)
		swap	d3
		move.w	d3,$02(a5)
		move.w	d0,$0e(a5)
		move.w	d0,$0e(a6)
		swap	d0
		move.w	d0,$0a(a5)
		move.w	d0,$0a(a6)
		move.w	d1,$16(a5)
		move.w	d1,$16(a6)
		swap	d1
		move.w	d1,$12(a5)
		move.w	d1,$12(a6)
		move.w	d2,$1e(a5)
		move.w	d2,$1e(a6)
		swap	d2
		move.w	d2,$1a(a5)
		move.w	d2,$1a(a6)
		
		lea		planet_modtab,a0
		move.w	#-512,d0
		move.w	#1024-1,d7
.l2:	
		move.w	d0,d1
		bpl.b	.l4
		moveq	#0,d1
.l4:
		mulu.w	#46,d1
		move.w	d1,(a0)+

		addq	#1,d0
		cmpi.w	#143,d0
		blt.b	.l3
		move.w	#143,d0
.l3:
		dbra	d7,.l2

		bsr.w	planet_update
		bsr.w	planet_update
		bsr.w	planet_update

		move.w	#TIME_PLANET_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
	
		move.l	#planet_copperfade,a0
		move.l	#planet_fadeirq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		rts

;--------------------------------------------------------------------

planet_fadeirq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)

		;move.w	#$fff,$dff180
		bsr.w	planet_update
		;clr.w	$dff180
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  

;--------------------------------------------------------------------

planet_update:
		bsr.w	planet_fade
		bsr.w	planet_dopage
		bsr.w	planet_clear
		bsr.w	planet_draw
		bsr.w	planet_fill
		rts
		
;--------------------------------------------------------------------

planet_clear:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		move.l	planet_screens+0,a0
		
		lea		BLTBASE,a6
		clr.w	BLTDMOD(a6)
		clr.w	BLTADAT(a6)
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTALWM(a6)
		move.l  a0,BLTDPTR(a6)
        move.l	#$01f00000,BLTCON0(a6)
		move.w  #$23d7,BLTSIZE(a6)
		rts
		
;--------------------------------------------------------------------

planet_draw:
		move.l	planet_screens+4,a0
		lea		planet_spheretab+144,a1
		
		move.w	#450,d2
		sub.w	planet_fadeframe(pc),d2
		
		move.w	d2,d3
		lsl.w	#1,d2
		bpl.b	.clamp
		moveq	#0,d2
.clamp:

		mulu.w	#41,d3
		lsr.w	#6,d3
		andi.w	#$fffe,d3
		addi.w	#1024,d3
		
		lea		planet_modtab,a2
		adda.w	d3,a2
		
		moveq	#7,d0
		move.w	#368-1,d7
.l0:
		move.w	(a1)+,d1
		mulu.w	d2,d1
		swap	d1
		add.w	d1,d1
		move.w	(a2,d1.w),d1	

		bset	d0,(a0,d1.w)
		
		subq	#1,d0
		bpl.b	.l1
		moveq	#7,d0
		addq	#1,a0
.l1:
		dbra	d7,.l0
		rts		

;--------------------------------------------------------------------

planet_fill:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
	
		move.l	planet_screens+4,a0		
		move.l	a0,a1
		adda.w	#46,a1
		
		lea		BLTBASE,a6
		clr.w	BLTAMOD(a6)
		clr.w	BLTCMOD(a6)
		clr.w	BLTDMOD(a6)
		move.l  a0,BLTAPTR(a6)
        move.l  a1,BLTCPTR(a6)
        move.l  a1,BLTDPTR(a6)
        move.l	#$0b5a0000,BLTCON0(a6)					;minterm $fa = a|c, channels $b = a&c&d
		move.w  #$23d7,BLTSIZE(a6)
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
planet_fadeframe:
		dc.w	0

planet_dithertab:
		dc.w	0,0,0,0
		dc.w	2,0,0,0
		dc.w	2,0,0,2
		dc.w	2,2,0,2
		
planet_pal1:
		dc.w	$0000,$0011,$0122,$0123,$0234,$0245,$0356,$0357
		dc.w	$0367,$0468,$0479,$058a,$059b,$069c,$06ad,$06ae,$06ae
planet_pal2:
		dc.w	$0fff,$0eff,$0eff,$0def,$0cef,$0cef,$0bdf,$0adf
		dc.w	$0ade,$0ace,$09ce,$08ce,$08be,$07be,$06be,$06ae,$06ae
		
planet_fade:
		addq.w	#1,planet_fadeframe
		
		move.w	planet_fadeframe(pc),d0
		lea		planet_pal1,a0
		lea		$dff190,a1
		bsr.w	.dofade
		
		move.w	planet_fadeframe(pc),d0
		lea		planet_pal2,a0
		lea		$dff192,a1
		bsr.w	.dofade
		rts
		
.dofade:
		cmpi.w	#15*32,d0
		blt.b	.clamp
		move.w	#15*32,d0
.clamp:
		
		move.w	d0,d1
		lsr.w	#5,d0
		andi.w	#6*4,d1
		
		add.w	d0,d0
		
		lea		planet_dithertab,a2
		movem.w	(a2,d1.w),d1-d4
		
		add.w	d0,d1
		add.w	d0,d2
		add.w	d0,d3
		add.w	d0,d4
		
		move.w	(a0,d1.w),(a1)
		move.w	(a0,d2.w),$4(a1)
		move.w	(a0,d3.w),$c(a1)
		move.w	(a0,d4.w),$8(a1)
		rts
		
;--------------------------------------------------------------------

planet_screens:		
		dc.l	planet_screen1,planet_screen2,planet_screen3

planet_dopage:
		lea 	planet_screens,a0
		
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
			
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$00(a0)
		
		lea		planet_copperbpl2,a6
		move.w	d0,$06(a6)
		swap	d0
		move.w	d0,$02(a6)
		rts
		
;********************************************************************

				section "planet_data",data
				
				cnop	0,2
planet_spheretab:				
	incbin "../data/planet/spheretab.dat"
	
;********************************************************************
	
				section "planet_copper",data,chip

planet_copperfade:
				dc.l	$008e1c87,$00903cad,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

planet_copperbpl1:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointer
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				
planet_copperfadesprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010affd2						;modulo odd planes, modulo even planes
	
				dc.l	$01004200
				dc.l	$01800000
	
				dc.l	$100ffffe,$009c8010						;wait x: 15, y: 33, start irq
				
				dc.l	$aa0ffffe
planet_copperbpl2:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointer
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				
				dc.l	$fffffffe 	
				
;********************************************************************

				section "planet_bss",bss
				
				cnop	0,2
planet_modtab:
				ds.w	1024
				
;********************************************************************

				section "planet_bsschip",bss,chip

				cnop	0,8
planet_screen1:
				ds.b	46*288/2
planet_screen2:
				ds.b	46*288/2
planet_screen3:
				ds.b	46*288/2
planet_mask1:
				ds.b	46*2
planet_mask2:
				ds.b	46*286/2
planet_mask3:
				ds.b	46*2
planet_mask4:
				ds.b	46*286/2

	include "../framework/hardware.i"
	
	ifnd _DEMO

entrypoint = bench_entry
	include "../framework/parttester.asm"

	endc	// _DEMO

	
			section	"bench_code",code 
		
bench_entry:
		bsr.w	bench_init

		lea		bench_coppersprites,a0
		bsr.w	clearsprites

		move.l	#bench_copperlist,a0
		move.l	#bench_irq,a1
		bsr.w	setcopper
		
bench_main:
		move.w	#$0f00,$dff180
		;bsr.w	bench_clear
		bsr.w	bench_mark
		move.w	#$000,$dff180
		bsr.w	vsync
		
		btst	#$06,$bfe001
		bne.b	bench_main
		rts		

;--------------------------------------------------------------------

bench_init:
		lea		bench_screen,a1
		move.l	a1,d0
		lea		bench_copperbpl,a0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		addi.l	#$2800,d1
		addi.l	#$5000,d2
		addi.l	#$7800,d3
		addi.l	#$a000,d4
		move.w	d0,$06(a0)
		move.w	d1,$0e(a0)
		move.w	d2,$16(a0)
		move.w	d3,$1e(a0)
		move.w	d4,$26(a0)
		swap	d0
		swap	d1
		swap	d2
		swap	d3
		swap	d4
		move.w	d0,$02(a0)
		move.w	d1,$0a(a0)
		move.w	d2,$12(a0)
		move.w	d3,$1a(a0)
		move.w	d4,$22(a0)
		rts

;--------------------------------------------------------------------

bench_clear:
		lea		bench_screen,a0
		
		bsr.w	bltwait
		lea		BLTBASE,a6
		move.w	#$ffff,BLTAFWM(a6)
		move.w	#$ffff,BLTAFWM(a6)
		clr.w	BLTADAT(a6)
		clr.w	BLTBDAT(a6)
		clr.w	BLTCDAT(a6)
		clr.w	BLTDMOD(a6)
		move.l  a0,BLTAPTR(a6)
        move.l  a0,BLTBPTR(a6)
        move.l  a0,BLTCPTR(a6)
        move.l  a0,BLTDPTR(a6)
        move.l	#$0ff00000,BLTCON0(a6)
		move.w  #$a418,BLTSIZE(a6)
		;bsr.w	bltwait
		rts

;--------------------------------------------------------------------

bla:
		dc.w	0

bench_mark:
		lea		bench_screen,a0
		lea		bench_screen,a1
		
		moveq	#0,d0
		
		REPT	3900

		lea		bla,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		ENDR
		
		rts
		
;--------------------------------------------------------------------

bench_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		;bsr.w	musicproxy
     
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;********************************************************************
			
				section "bench_empty",bss
				
				cnop 	0,$10000
data:			ds.b	$40000
				
				
;********************************************************************
			
				section "bench_emptychip",bss,chip

				cnop	0,8
bench_screen:	ds.b	$2800*5

;********************************************************************

				section "bench_copper",data,chip

bench_copperlist:
				dc.l	$008e2c81,$00902cc1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

bench_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000

bench_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01004200						;wait x: 15, y: 1, turn on 4 bitplanes

				dc.l	$210ffffe,$009c8010						;wait x: 15, y: 33, start irq

				dc.l	$fffffffe 								;wait for end

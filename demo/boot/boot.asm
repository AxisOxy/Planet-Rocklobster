	include "../framework/framework.i"	
		
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
BOOT_NUMFRAMES = 850

	
			section	"boot_code",code 
		
entrypoint:
		bra.b	boot_start
		bra.b	boot_end
		
boot_start:
		move.l	a6,fw_jumptable
		
		bsr.w	boot_init
		bsr.w	boot_update
				
		lea		boot_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		move.l	#boot_copperlist,a0
		move.l	#boot_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)

		jsr		GETFRAME(a6)
		addi.w	#BOOT_NUMFRAMES,d0
		move.w	d0,boot_endframe
		rts
		
boot_end:
		move.l	fw_jumptable,a6
		move.w	boot_endframe(pc),d0
		jsr		WAITFORFRAME(a6)
		
		bsr.w	boot_fadeout
		
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
 		rts		
		
		cnop	0,4
fw_jumptable:
		dc.l	0
boot_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

boot_init:
		lea		boot_lineoffs,a0
		moveq	#4,d0
		move.w	#285,d7
.l0:
		move.w	d0,(a0)+
		
		addi.w	#16,d0
		cmpi.w	#285-229,d7
		bne.b	.l1
		addq	#4,d0
.l1:
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
boot_pal:
		dc.w	$0021,$06a8
		dc.w	$0132,$07b9
boot_rasterbar:
		ds.w	256
		blk.w	5,$0010
		blk.w	5,$0021
		blk.w	5,$0132
		blk.w	5,$0243
		blk.w	5,$0132
		blk.w	5,$0021
		blk.w	5,$0010
		ds.w	256
boot_brighttab:
		dc.w	0,0,0,0,0,0,0,0,0,0,0,1,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0
		dc.w	0,0,0,0,0,0,0,0,0,0,0,1,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,2,0,0
		
boot_rndpoi:
		dc.w	0
boot_barpoi:
		dc.w	$1d0
boot_brightpoi:
		dc.w	0
		
boot_updatecopper:	
		lea		boot_pal,a0
		lea		boot_coppercols,a1
		lea		boot_rndtab,a2
		lea		boot_rasterbar,a3
		
		move.w	boot_brightpoi(pc),d0
		addq	#1,d0
		move.w	d0,boot_brightpoi
		lsr.w	#3,d0
		andi.w	#$3f,d0
		add.w	d0,d0
		lea		boot_brighttab,a4
		move.w	(a4,d0.w),d2
				
		move.w	boot_rndpoi(pc),d4
		addi.w	#129,d4
		move.w	d4,boot_rndpoi
		andi.w	#$ff,d4
	
		move.w	boot_barpoi(pc),d3
		addi.w	#8,d3
		move.w	d3,boot_barpoi
		andi.w	#$1ff,d3
		add.w	d3,d3
		
		move.l	#$1c0ffffe,d0
		moveq	#0,d1
		move.w	#285-1,d7
.l0:
		move.l	d0,(a1)+
		
		move.w	(a3,d3.w),d5
		
		move.w	#$0180,(a1)+
		move.w	(a0,d1.w),d6
		add.w	d5,d6
		move.w	d6,(a1)+
		
		move.w	#$0182,(a1)+
		move.w	2(a0,d1.w),d6
		add.w	d5,d6
		cmpi.w	#2,d2
		bne.b	.nobright
		move.w	#$9db,d6
.nobright
		move.w	d6,(a1)+
		
		moveq	#0,d6
		cmpi.b	#20,(a2,d4.w)
		blo.b	.l1
		addq	#1,d6
.l1:
		cmpi.w	#2,d2
		bne.b	.notech
		addq	#2,d6
.notech:

		move.w	#$0102,(a1)+
		andi.w	#$0f,d5
		add.w	d5,d6
		move.w	d6,(a1)+
		
		addq	#1,d4
		addq	#2,d3
		andi.w	#$3fe,d3
		andi.w	#$ff,d4
		
		cmpi.w	#142,d7
		bne.b	.half
		addq	#1,d2
.half:		
		
		eori.w	#$4,d1
		addi.l	#$01000000,d0
		cmpi.l	#$000ffffe,d0
		bne.b	.wrap
		move.l	#$ffdffffe,(a1)+
.wrap:
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

boot_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		tst.w	boot_infade
		bne.b	.skip
		;move.w	#$0f00,$dff180
		bsr.w	boot_update
		;move.w	#$000,$dff180
.skip:
		
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
boot_frame:
		dc.w	0

boot_update:
		addq.w	#1,boot_frame
		bsr.w	boot_updatetext
		bsr.w	boot_updatescroll
		bsr.w	boot_updatecopper
		rts
		
;--------------------------------------------------------------------

		cnop	0,4
boot_texpoi:
		dc.w	0
		
boot_text:
		dc.b	"archaeologic space probe oxysat starting"
		dc.b	"mission: search for scene activity...   "
		dc.b	"entering system petra locusta...        "
		dc.b	"found signs of life...                  "
		dc.b	"investigate further...                  "
boot_textend:

boot_textsize = boot_textend-boot_text

boot_updatetext:	
		lea		boot_text,a0
		lea		boot_font+2,a1
		lea		boot_screen+40*128,a2
		
		move.w	boot_texpoi(pc),d4
		cmpi.w	#boot_textsize*4,d4
		bge.b	.skip
		addq.w	#1,boot_texpoi
				
		lsr.w	#2,d4
		
		adda.w	d4,a0
		
		move.w	d4,d5
		ext.l	d5
		divu.w	#40,d5	;ypos
		move.w	d5,d6
		mulu.w	#40,d6
		sub.w	d6,d4	;xpos
		
		mulu.w	#40*8,d5
		adda.w	d4,a2
		adda.w	d5,a2

		moveq	#0,d0
		move.b	(a0),d0
		cmpi.b	#$20,d0
		beq.b	.skip
		cmpi.b	#$40,d0
		blt.b	.special
		andi.b	#$1f,d0
.special:
		lsl.w	#3,d0
		lea		(a1,d0.w),a3
		
		moveq	#8-1,d5
.l2:	
		move.b	(a3)+,(a2)
		lea		40(a2),a2
		dbra	d5,.l2
.skip:
		rts

;--------------------------------------------------------------------

boot_updatescroll:
		move.l	#boot_screen,d0
		lea		boot_copperbpl,a6
		
		moveq	#0,d1
		move.w	boot_texpoi(pc),d1
		divu.w	#40*4,d1
		mulu.w	#40*8,d1
		add.l	d1,d0
		
		move.w	d0,6(a6)
		swap	d0
		move.w	d0,2(a6)
		rts
	
;--------------------------------------------------------------------
	
boot_initfade:
		lea		boot_coppercols,a0
		lea		boot_copperbackup,a1
		move.w	#285*4+1-1,d7
.l0:
		move.l	(a0)+,(a1)+
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------
	
		cnop	0,2
boot_infade:
		dc.w	0
	
boot_fadeout:
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)

		addq.w	#1,boot_infade
		bsr.w	boot_initfade

		moveq	#0,d7
.l0:
		move.w	d7,-(sp)
		
		bsr.w	boot_updatefade
		
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
		
		move.w	(sp)+,d7
		
		addq	#1,d7
		cmpi.w	#40,d7
		bne.b	.l0
		
		lea		boot_copperbpl2,a0
		move.l	#boot_line,d0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		
		lea		boot_coppersprites2,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		move.l	#boot_copperlist2,a0
		move.l	#boot_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
			
		moveq	#0,d7
.l1:
		move.w	d7,-(sp)
		
		bsr.w	boot_updatefade2
		
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
		
		move.w	(sp)+,d7
		
		addq	#1,d7
		cmpi.w	#40,d7
		bne.b	.l1
		
		bsr.w	boot_clear
		bset.b	#0,boot_line+22
		
		moveq	#32-1,d7
.l2:
		move.w	d7,d0
		lsr.w	#1,d0
		move.w	d0,d1
		move.w	d0,d2
		lsl.w	#4,d1
		lsl.w	#8,d2
		or.w	d1,d0
		or.w	d2,d0
		move.w	d0,$dff182
		
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
	
		dbra	d7,.l2
		rts
	
;--------------------------------------------------------------------

boot_updatefade:
		move.w	#40,d2
		sub.w	d7,d2
		move.l	#130*256,d0
		divs.w	d2,d0
		muls.w	d0,d0
		swap	d0
		neg.w	d0
		move.w	#285,d1
		sub.w	d0,d1
		sub.w	d0,d1
		
		ext.l	d1
		lsl.l	#8,d1
		divs.w	#285,d1
		ext.l	d1
		lsl.l	#8,d1
		swap	d0
		move.w	#$8000,d0
		
		lea		boot_copperbackup,a0
		lea		boot_coppercols,a1
		lea		boot_lineoffs,a2

		moveq	#0,d4
		
		move.l	#$1c0ffffe,d6
		move.w	#285-1,d7
.l0:
		move.l	d6,(a1)+
		
		move.l	d0,d2
		swap	d2
		move.w	d2,d3
		tst.w	d2
		bmi.b	.black
		cmpi.w	#285,d2
		bge.b	.black
		add.w	d2,d2
		move.l	a0,a3

		adda.w	(a2,d2.w),a3
		
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.w	d3,d2
		sub.w	d4,d2
		subq	#1,d2
		mulu.w	#40,d2
		move.w	#$0108,(a1)+
		move.w	d2,(a1)+
		bra.b	.noblack
.black:
		move.l	#$01800000,(a1)+
		move.l	#$01820000,(a1)+
		move.l	#$01020000,(a1)+
		move.l	#$0108ffd8,(a1)+
.noblack:		
		addi.l	#$01000000,d6
		cmpi.l	#$000ffffe,d6
		bne.b	.wrap
		move.l	#$ffdffffe,(a1)+
.wrap:	
		add.l	d1,d0
		move.w	d3,d4
		
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

		cnop	0,2
boot_fadepal:
		dc.w	$07b9,$08ca,$09db,$0aec,$0bfd,$0cfe,$0dff,$0eff,$0fff
		
boot_updatefade2:
		move.w	d7,d0
		mulu.w	#9,d0
		divu.w	#40,d0
		add.w	d0,d0
		lea		boot_fadepal,a0
		move.w	(a0,d0.w),$dff182

		move.w	#40,d2
		sub.w	d7,d2
		move.l	#120*256,d0
		divs.w	d2,d0
		muls.w	d0,d0
		swap	d0
		neg.w	d0
		move.w	#285,d1
		sub.w	d0,d1
		sub.w	d0,d1
		
		ext.l	d1
		lsl.l	#8,d1
		divs.w	#368,d1
		ext.l	d1
		lsl.l	#8,d1
		swap	d0
		move.w	#$8000,d0

		bsr.w	boot_clear
		
		lea		boot_line,a6
		
		moveq	#7,d6
		move.w	#368-1,d7
.l0:	
		move.l	d0,d2
		swap	d2
		move.w	d2,d3
		tst.w	d2
		bmi.b	.black
		cmpi.w	#285,d2
		bge.b	.black
		
		bset.b	d6,(a6)
.black:
		subq	#1,d6
		bpl.b	.l1
		moveq	#7,d6
		addq	#1,a6
.l1:	
		add.l	d1,d0
		
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

boot_clear:
		lea		boot_line,a6
		moveq	#48/4-1,d7
.l00:
		clr.l	(a6)+
		dbra	d7,.l00
		rts
		
;********************************************************************
				
				section "boot_data",data
				
				cnop	0,8
boot_font:
	incbin "../data/boot/c64font.prg"

boot_rndtab:
	incbin "../data/pic/rndtab.dat"

;********************************************************************

				section "boot_emptychip",bss,chip

				cnop	0,8
boot_screen:
				ds.b	320*340/8
			
;********************************************************************
				
				section "boot_empty",bss

				cnop	0,2
boot_copperbackup:
				ds.l	285*4+1
boot_lineoffs:
				ds.w	285
		
;********************************************************************

				section "boot_copper",data,chip

boot_copperlist:	
				dc.l	$008e1c81,$00902cc6,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

boot_copperbpl:	
				dc.l	$00e00000,$00e20000						;1 bitplane pointer

boot_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020020,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01001200						;wait x: 15, y: 1, turn on 1 bitplanes
				dc.l	$009c8010								;start irq
	
boot_coppercols:
				blk.l	285*5+1,$01800000
				
				dc.l	$fffffffe 								;wait for end
	
;--------------------------------------------------------------------

boot_copperlist2:	
				dc.l	$008eac81,$0090add1,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

boot_copperbpl2:	
				dc.l	$00e00000,$00e20000						;1 bitplane pointer

boot_coppersprites2:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01001200						;wait x: 15, y: 1, turn on 1 bitplanes
				dc.l	$01800000

				dc.l	$009c8010								;start irq
				
				dc.l	$fffffffe 								;wait for end
	
;--------------------------------------------------------------------

boot_line:
				blk.b	48,$ff

	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

	
			section	"move_code",code 
		
entrypoint:
		bra.b	city_start
		bra.b	city_end
		
city_start:
		move.l	a6,fw_jumptable
			
		bsr.w		city_movelogo
		rts
		
city_end:
;.xx:
;		jmp .xx

		;move.l	fw_jumptable,a6
		;jsr		SETBASECOPPER(a6)
		rts		
	
		cnop	0,4
fw_jumptable:
		dc.l	0

;--------------------------------------------------------------------

city_movelogo:
		lea		blur_logo+10,a0
		lea		city_movecoppercols,a1
		move.w	#$0180,d0
		moveq	#16-1,d7
.l0:		
		move.w	d0,(a1)+
		addq	#2,d0
		move.w	(a0)+,(a1)+
		dbra	d7,.l0
		
		lea		blur_logo,a0
		move.w	(a0)+,d0	;palette size in entries
		move.w	(a0)+,d1	;width of bitplane in bytes
		move.w	(a0)+,d2	;size of bitplane in bytes
		move.l	(a0)+,d3	;size of image in bytes
		add.w	d0,d0
		adda.w	d0,a0
		
		move.l	a0,d0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		addi.l	#60*40*1,d1
		addi.l	#60*40*2,d2
		addi.l	#60*40*3,d3
		lea		city_movecopperbpl,a6
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
		
		lea		city_movecopperscale,a0
		lea		city_copperpois,a1
		move.l	#$2c0ffffe,d0
		move.w	#256-1,d7
.l1:
		addq	#6,a0
		move.l	a0,(a1)+
		subq	#6,a0
		
		move.l	d0,(a0)+
		move.l	#$01000200,(a0)+	;turn off bitplanes
		addi.l	#$01000000,d0
		cmpi.l	#$000ffffe,d0
		bne.b	.l2
		move.l	#$ffdffffe,(a0)+
.l2:
		dbra	d7,.l1

		bsr.w	city_updatemovelogo
		
		lea		city_movecoppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)

		move.w	#TIME_CITYFADE_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#city_movecopperlist,a0
		move.l	#city_moveirq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		rts
			
;--------------------------------------------------------------------
	
city_moveirq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)

		bsr.w	city_updatemovelogo
	
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
	
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
	
;--------------------------------------------------------------------
	
		cnop	0,2
city_moveframe:
		dc.w	0
		
city_updatemovelogo:
		addq.w	#1,city_moveframe
		move.w	city_moveframe(pc),d0
		
		cmpi.w	#128,d0
		bge.b	.skip
						
		lea		city_copperpois,a0
		
		move.w	#256-1,d7
		moveq	#0,d3
.l0:
		move.l	(a0)+,a1
		move.w	d3,(a1)
		
		dbra	d7,.l0
		
		moveq	#0,d2
		move.w	#$4200,d3
		
		lea		city_copperpois,a0
		
		moveq	#128-1,d0
		sub.w	city_moveframe(pc),d0
		lea		city_fadeoutwave,a2
		adda.w	d0,a2

		moveq	#58-1,d7
.l01:
		moveq	#0,d4
		move.b	(a2)+,d4
		subq	#1,d4
		lsl.w	#3,d4
		add.w	d4,d2
		
		dbra	d7,.l01
		
		moveq	#58-1,d7
.l1:		
		move.l	(a0,d2.w),a1
		move.w	d3,(a1)

		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#3,d4
		subq	#4,d4
		
		add.w	d4,d2
		cmpi.w	#256*4,d2
		bge.b	.skip
		
		dbra	d7,.l1
.skip:
		rts
		
city_fadeoutwave:
		blk.b	$8a,1
		blk.b	5,2
		blk.b	6,3
		blk.b	9,4
		blk.b	2,5
		blk.b	10,4
		blk.b	5,3
		blk.b	6,2
		blk.b	256,1
		
		cnop	0,4
city_copperpois:
		ds.l	256
	
;********************************************************************

				section "move_copper",data,chip
			
					cnop	0,2
city_movecopperlist:
				dc.l	$008e2c81,$00902cc2,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

city_movecopperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;4 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000

city_movecoppercols:
				blk.l	16,$01800000
				
city_movecoppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01040000						;bplcon mode, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
				dc.l	$01020000								;scroll x odd and even planes

				dc.l	$2b0ffffe,$01000200						;wait x: 15, y: 1, turn on 4 bitplanes
city_movecopperscale:
				blk.l	2*256+1,$01800000

				dc.l	$009c8010								;wait x: 15, y: 33, start irq
						
				dc.l	$fffffffe 								;wait for end

				cnop	0,2
blur_logo:
	incbin "../data/blur/logo.ami"
	
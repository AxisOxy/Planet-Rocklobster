	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO

depth	= 5
bplsize	= width*height/8

	
			section	"pic_code",code 
		
entrypoint:
		bra.b	pic_start
		bra.b	pic_end
		
pic_start:
		move.l	a6,fw_jumptable
	
		bsr.w	pic_init

		lea		pic_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		move.w	#TIME_PIC1_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
		
		move.l	#pic_copperlist,a0
		move.l	#pic_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		bsr.w	pic_fadein
		
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#500,d0
		move.w	d0,pic_endframe
 		rts
		
pic_end:	
		move.l	fw_jumptable,a6
		move.w	pic_endframe(pc),d0
		jsr		WAITFORFRAME(a6)	

	ifd FADEOUT
		clr.w	pic_doblink

		bsr.w	pic_fadeout
	endc
		
		jsr		SETBASECOPPER(a6)	
		move.w	#$fff,$dff180
		rts
			
		cnop	0,4
fw_jumptable:
		dc.l	0
pic_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

pic_init:
		lea 	pic_image,a0
		move.w	(a0)+,d0	;palette size in entries
		move.w	(a0)+,d1	;width of bitplane in bytes
		move.w	(a0)+,d2	;size of bitplane in bytes
		move.l	(a0)+,d3	;size of image in bytes
		
		lea		$dff180,a1
		ext.l	d0
		subq.l	#1,d0
.l0:	
		clr.w	(a1)+
		addq	#2,a0
		dbra	d0,.l0
		
		move.l	a0,d0
		
		lea		pic_copperbpl,a0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		addi.l	#bplsize*1,d1
		addi.l	#bplsize*2,d2
		addi.l	#bplsize*3,d3
		addi.l	#bplsize*4,d4
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

pic_fadein:
		moveq	#1,d4
		
		moveq	#7-1,d6
		move.l	#16*2,a5
		moveq	#0,d0
		move.w	#68,d5
		bsr.w	pic_fadeloop
		
		moveq	#32-1,d7
		bsr.w	pic_waitloop
		
		moveq	#9-1,d6
		move.l	#23*2,a5
		moveq	#0,d0
		move.w	#68,d5
		bsr.w	pic_fadeloop

		move.w	#1,pic_doblink

		moveq	#32-1,d7
		bsr.w	pic_waitloop
		
		moveq	#16-1,d6
		move.l	#0*2,a5
		moveq	#0,d0
		move.w	#68,d5
		bra.w	pic_fadeloop
		
;--------------------------------------------------------------------

pic_fadeout:
		moveq	#-1,d4
		
		moveq	#9-1,d6
		move.l	#23*2,a5
		moveq	#67,d0
		move.w	#0,d5
		bsr.w	pic_fadeloop
		
		moveq	#32-1,d7
		bsr.w	pic_waitloop
		
		moveq	#7-1,d6
		move.l	#16*2,a5
		moveq	#67,d0
		move.w	#0,d5
		bra.w	pic_fadeloop

;--------------------------------------------------------------------
		
pic_waitloop:
.l0:
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
 	
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------
		
pic_fadeloop:
.l0:		
		bsr.w	pic_fade
	
		move.l	fw_jumptable(pc),a6
		jsr		VSYNC(a6)
 	
		add.w	d4,d0
		cmp.w	d5,d0
		bne.b	.l0
		rts

;--------------------------------------------------------------------

pic_fade:
		lea 	pic_image+10,a0
		lea		$dff180,a1
		adda.l	a5,a0
		adda.l	a5,a1
		move.w	d6,d7
.l0:	
		move.w	(a0)+,d1
		move.w	d1,d2
		move.w	d1,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		mulu.w	d0,d1
		mulu.w	d0,d2
		mulu.w	d0,d3
		lsr.l	#6,d1
		lsr.w	#6,d2
		lsr.w	#6,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		or.w	d2,d1
		or.w	d3,d1
		move.w	d1,(a1)+
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------

pic_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
 		 
		bsr.w	pic_updateblink
		 
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;--------------------------------------------------------------------

		cnop	0,2
pic_doblink:
		dc.w	0
pic_blinkframe:
		dc.w	0

pic_updateblink:
		tst.w	pic_doblink
		beq.b	.skip
		
		move.w	pic_blinkframe(pc),d0
		addq.w	#1,d0
		cmpi.w	#22,d0
		bne.b	.wrap
		moveq	#0,d0
.wrap:
		move.w	d0,pic_blinkframe
		
		cmpi.w	#8,d0
		bge.b	.skip

		moveq	#7,d1
		sub.w	d0,d1
	
		move.w	d1,d0
		lsl.w	#4,d1
		move.w	d1,d2
		lsl.w	#4,d2
		
		lea 	pic_image+10+23*2,a0
		lea		$dff180+23*2,a1
		moveq	#9-1,d7
.l0:
		move.w	(a0)+,d3
		move.w	d3,d4
		move.w	d3,d5

		move.w	#$f00,d6
		and.w	d6,d3
		add.w	d2,d3
		cmp.w	d6,d3
		ble.b	.wrap1
		move.w	d6,d3
.wrap1:

		move.w	#$0f0,d6
		and.w	d6,d4
		add.w	d1,d4
		cmp.w	d6,d4
		ble.b	.wrap2
		move.w	d6,d4
.wrap2:

		move.w	#$00f,d6
		and.w	d6,d5
		add.w	d0,d5
		cmp.w	d6,d5
		ble.b	.wrap3
		move.w	d6,d5
.wrap3:
		or.w	d4,d3
		or.w	d5,d3
		move.w	d3,(a1)+
		
		dbra	d7,.l0
		
.skip:		
		rts
		
;********************************************************************

				section "pic_copper",data,chip

PIC_COPSTART	= $008eac81-height/2*256
PIC_COPEND		= $0090acd1+height/2*256-$10000
				
pic_copperlist:	dc.l	PIC_COPSTART,PIC_COPEND,$00920030,$009400c8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

pic_copperbpl:	dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointers
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000
				
pic_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$010200ff,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01005200						;wait x: 15, y: 1, turn on 5 bitplanes

				dc.l	$210ffffe,$009c8010						;wait x: 15, y: 33, start irq
				
				dc.l	$fffffffe 								;wait for end

;--------------------------------------------------------------------
			
				cnop	0,8
pic_image:

VOXEL_DEPTHS	= 64
VOXEL_WIDTH 	= 160
VOXEL_HEIGHT 	= 100
VOXEL_PLANESIZE	= VOXEL_WIDTH*VOXEL_HEIGHT/4
	
VOXEL_NUMFRAMES		= 1200
VOXEL_FADEFRAMES	= 64
	
	include "../framework/hardware.i"
	include "../framework/framework.i"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
			
			section	"voxel_code",code 
		
entrypoint:
		bra.b	voxel_start
		bra.b	voxel_end

voxel_start:
		move.l	a6,fw_jumptable

		bsr.w	voxel_initcopper
		bsr.w	voxel_startfade

		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#68,d0
		move.w	d0,voxel_endframe
.xx:
;		jmp .xx
		rts
		
voxel_end:
		move.l	fw_jumptable,a6
		move.w	voxel_endframe(pc),d0
		jsr		WAITFORFRAME(a6)
		rts
		
		cnop	0,4
fw_jumptable:
		dc.l	0
voxel_endframe:
		dc.w	0
		
;--------------------------------------------------------------------

 MACRO<VOXEL_COPPERLINE>
		
 ENDM

voxel_initcopper:	
		lea		voxel_copperfadestretch,a0
		move.w	#$00ee,d2
		move.l	#$1c0ffffe,d0
		move.w	#143-1,d7
.l0:
		move.l	d0,(a0)+
		move.l	#$01005200,(a0)+
		move.w	#$0102,(a0)+
		move.w	d2,(a0)+
		subi.w	#$0022,d2
		bpl.b	.wrap
		move.w	#$00ee,d2
		move.l	#$0108ffd4,(a0)+
		move.l	#$010affd4,(a0)+
		bra.b	.nowrap
.wrap:		
		move.l	#$0108ffd2,(a0)+
		move.l	#$010affd2,(a0)+
.nowrap:
		addi.l	#$01000000,d0
		
		move.l	d0,(a0)+
		move.l	#$01000200,(a0)+
		addi.l	#$01000000,d0
	
		cmpi.l	#$000ffffe,d0
		bne.b	.l1
		move.l	#$ffdffffe,(a0)+
.l1:
		dbra	d7,.l0
		
		move.l	#$fffffffe,(a0)+
		rts
		
;--------------------------------------------------------------------

voxel_startfade:
		lea		voxel_copperfadesprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		lea		voxel_fadeplane,a0
		move.l	a0,d0
		addq	#2,d0
		
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		addi.l	#80*1,d1
		addi.l	#80*2,d2
		addi.l	#80*3,d3
		addi.l	#80*4,d4
		
		lea		voxel_copperfadebpl,a0
		move.w	d0,$06(a0)
		swap	d0
		move.w	d0,$02(a0)
		move.w	d1,$0e(a0)
		swap	d1
		move.w	d1,$0a(a0)
		move.w	d2,$16(a0)
		swap	d2
		move.w	d2,$12(a0)
		move.w	d3,$1e(a0)
		swap	d3
		move.w	d3,$1a(a0)
		move.w	d4,$26(a0)
		swap	d4
		move.w	d4,$22(a0)
				
		move.l	#voxel_copperfade,a0
		move.l	#voxel_fadeirq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		rts

;--------------------------------------------------------------------

		cnop	0,2
voxel_fadeoff:
		dc.w	-27*128

voxel_updatefade:
		addq.w	#1,fadeframe
	
		lea		voxel_fadeplane+4,a2
		lea		fademasks(pc),a0
		lea		voxel_fadesin,a1
		
		moveq	#19-1,d6
.l0:		
		move.w	d6,d1
		add.w	d1,d1
		add.w	d6,d1	;fast mulu #3
		move.w	fadeframe(pc),d0
		add.w	d1,d0
		addi.w	#$400,d0
		mulu.w	#50/8,d0	
		addi.w	#$170,d0
		andi.w	#$1fe,d0
		move.w	(a1,d0.w),d0
		addi.w	#$4000,d0
		mulu.w	#14*2,d0
		swap	d0
		
		move.w	voxel_fadeoff(pc),d1
		asr.w	#7,d1
		sub.w	d1,d0
		bpl.b	.cliptop
		moveq	#0,d0
.cliptop:
		cmpi.w	#17-1,d0
		blt.b	.clipbottom
		moveq	#17-1,d0
.clipbottom:
		
		bsr.w	voxel_fillpolyline
		
		addq	#4,a2
		
		dbra	d6,.l0
		
		addi.w	#16,voxel_fadeoff
		rts
		
;--------------------------------------------------------------------

voxel_clear:
		lea		voxel_fadeplane+80*5,a0
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		move.l	d6,a2
		move.l	d6,a3
		move.l	d6,a4
		
		moveq	#80*5/40-1,d7
.l0:
		movem.l	d0-d6/a2-a4,-(a0)
		dbra	d7,.l0
		rts

;--------------------------------------------------------------------
		
		cnop	0,2
fadeframe:
		dc.w	0
fademasks:
		dc.l	$ffffffff,$7ffffffe,$3ffffffc,$1ffffff8
		dc.l	$0ffffff0,$07ffffe0,$03ffffc0,$01ffff80
		dc.l	$00ffff00,$007ffe00,$003ffc00,$001ff800
		dc.l	$000ff000,$0007e000,$0003c000,$00018000
		dc.l	$00000000

;d0 - scale/color
;a0 - fademasks
;a2 - bitplane address
voxel_fillpolyline:
		move.w	d0,d2
		add.w	d0,d0
		add.w	d0,d0
		moveq	#-1,d1
		not.w	d2
		cmp.w	#15,d2
		blt.b	.clip
		moveq	#15,d2
.clip:
		btst	#0,d2
		beq.b	.skip0
		move.l	d1,80*0(a2)
.skip0:
		btst	#1,d2
		beq.b	.skip1
		move.l	d1,80*1(a2)
.skip1:
		btst	#2,d2
		beq.b	.skip2
		move.l	d1,80*2(a2)
.skip2:
		btst	#3,d2
		beq.b	.skip3
		move.l	d1,80*3(a2)
.skip3:
		move.l	(a0,d0.w),80*4(a2)
		rts
		
;--------------------------------------------------------------------

voxel_fadeirq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)

		move.w	fadeframe(pc),d0
		cmpi.w	#320,d0
		bgt.b	.skip
		bsr.w	voxel_clear
		bsr.w	voxel_updatefade
.skip:
		
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;********************************************************************

				section "voxel_copper",data,chip

voxel_copperfade:
				dc.l	$008e1c87,$00903cad,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

voxel_copperfadebpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointer
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000

voxel_copperfadesprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$0108ffd2,$010affd2						;modulo odd planes, modulo even planes

				dc.l	$010ffffe,$009c8010						;wait x: 15, y: 33, start irq
				dc.l	$01800000,$01820000,$01840000,$01860000
				dc.l	$01880000,$018a0000,$018c0000,$018e0000
				dc.l	$01900000,$01920000,$01940000,$01960000
				dc.l	$01980000,$019a0000,$019c0000,$019e0000
				dc.l	$01a00000,$01a20011,$01a40012,$01a60123
				dc.l	$01a80134,$01aa0235,$01ac0246,$01ae0257
				dc.l	$01b00357,$01b20368,$01b40479,$01b6047a
				dc.l	$01b8048b,$01ba059c,$01bc059d,$01be06ae
				dc.l	$01005200
				
voxel_copperfadestretch:
				ds.l	143*16+1
			
				dc.l	$fffffffe 	
				
;--------------------------------------------------------------------
				
				cnop	0,8
voxel_fadeplane:
				ds.b	5*80

				cnop	0,2
voxel_fadesin:				
	incbin "../data/sinplots/sintab256.dat"

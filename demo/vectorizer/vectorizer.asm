VECTORIZER_BPLSIZE	= 46*170

VECTORIZER_NUMFRAMES	= 448*2

	include "../framework/hardware.i"
	include "../framework/framework.i"	
	include "../launcher/timings.asm"	
	
	ifnd _DEMO
	include "../framework/parttester.asm"
	endc	// _DEMO
	
			
			section	"vectorizer_code",code 
		
entrypoint:
		move.l	a6,fw_jumptable
		bsr.w	vectorizer_init

		lea		vectorizer_coppersprites,a0
		move.l	fw_jumptable,a6
		jsr		CLEARSPRITES(a6)
		
		bsr.w	vectorizer_update
		bsr.w	vectorizer_page
		bsr.w	vectorizer_update
		bsr.w	vectorizer_page
		bsr.w	vectorizer_update
		bsr.w	vectorizer_page
		bsr.w	vectorizer_update
		bsr.w	vectorizer_page

		move.w	#TIME_VECTORIZER_START,d0
		move.l	fw_jumptable,a6
		jsr		WAITFORFRAME(a6)
				
		move.l	#vectorizer_copperlist,a0
		move.l	#vectorizer_irq,a1
		move.l	fw_jumptable,a6
		jsr		SETCOPPER(a6)
		
		bsr.w	vectorizer_fadeinborder
		
		move.w	#1,vectorizer_dofade
				
		move.l	fw_jumptable,a6
		jsr		GETFRAME(a6)
		addi.w	#VECTORIZER_NUMFRAMES,d0
		move.w	d0,vectorizer_endframe
			
vectorizer_main:
		bsr.w	vectorizer_update
.sync:
		tst.w	vectorizer_sync
		;beq.b	.sync
		clr.w	vectorizer_sync

		bsr.w	vectorizer_page
		
		btst	#$06,$bfe001
		beq.b	vectorizer_end
		
		move.w	vectorizer_endframe,d0
		move.l	fw_jumptable,a6
		jsr		ISFRAMEOVER(a6)
		bpl.b	vectorizer_main
vectorizer_end:
		move.l	fw_jumptable,a6
		jsr		SETBASECOPPER(a6)
		rts		

		cnop	0,4
fw_jumptable:
		dc.l	0
vectorizer_endframe:
		dc.w	0
		
;--------------------------------------------------------------------
		
		cnop	0,2
vectorizer_fadetab:
		dc.w	$0fff,$0eee,$0ddd,$0ccc,$0bbb,$0aaa,$0999,$0888
		dc.w	$0777,$0666,$0555,$0444,$0333,$0222,$0111,$0000

vectorizer_fadeinborder:
		move.l	fw_jumptable(pc),a6
		lea		vectorizer_fadetab,a0
		lea		vectorizer_col0smc2+2,a1
		bsr.w	.do
		
		lea		vectorizer_col0smc+10,a1
		bsr.w	.do
		rts
		
.do:
		moveq	#16-1,d7
.l0:	
		moveq	#16-1,d0
		sub.w	d7,d0
		add.w	d0,d0
		move.w	(a0,d0.w),(a1)
		
		jsr		VSYNC(a6)
		jsr		VSYNC(a6)
	
		dbra	d7,.l0
		rts
		
;--------------------------------------------------------------------

vectorizer_pal:
		; tunnel
		dc.w	$0378,$0599,$07bb,$09dc
		; starship
		incbin "../data/vectorizer/satpal.dat"

		cnop	0,2
vectorizer_fadeframe:
		dc.w	0
vectorizer_fadepal:
		ds.w	12
vectorizer_dofade:
		dc.w	0

vectorizer_updatefade:
		tst.w	vectorizer_dofade
		beq.b	.noinc
		addq.w	#1,vectorizer_fadeframe
.noinc:
		move.w	#$fff,d4
		
		move.w	vectorizer_fadeframe(pc),d0
		cmpi.w	#64,d0
		blt.w	.noinv
		clr.w	d4
		neg.w	d0
		add.w	#VECTORIZER_NUMFRAMES,d0
.noinv:		
		tst.w	d0
		bmi.w	.skip
		cmpi.w	#64,d0
		blt.w	.nornd
		lea		vectorizer_rndtab,a6
		lsr.w	#3,d0
		andi.w	#$ff,d0
		moveq	#$40,d1
		move.b	(a6,d0.w),d0
		cmpi.b	#20,d0
		bhi.b	.notdark
		moveq	#30,d1
.notdark:
		
		move.w	d1,d0
.nornd:
		lsr.w	#2,d0
		
		lea		vectorizer_pal(pc),a0
		lea		vectorizer_fadepal(pc),a1
		
		move.w	d4,d5
		move.w	d4,d6
		andi.w	#$f00,d4
		andi.w	#$0f0,d5
		andi.w	#$00f,d6
		
		moveq	#12-1,d7
.l0:
		move.w	(a0)+,d1
		move.w	d1,d2
		move.w	d1,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		sub.w	d4,d1
		sub.w	d5,d2
		sub.w	d6,d3
		muls.w	d0,d1
		muls.w	d0,d2
		muls.w	d0,d3
		asr.w	#4,d1
		asr.w	#4,d2
		asr.w	#4,d3
		add.w	d4,d1
		add.w	d5,d2
		add.w	d6,d3
		andi.w	#$f00,d1
		andi.w	#$0f0,d2
		andi.w	#$00f,d3
		or.w	d2,d1
		or.w	d3,d1
		move.w	d1,(a1)+
		dbra	d7,.l0
		
		move.w	d0,d4
		
		lea		vectorizer_fadepal(pc),a0
		lea		$dff180,a1
		movem.w	(a0),d0-d3
		move.w	d0,vectorizer_col0smc+2
		move.w	d1,$10(a1)
		move.w	d2,$20(a1)
		move.w	d3,$30(a1)
		
		movem.w	10(a0),d0-d6
		movem.w	d0-d6,$02(a1)
		movem.w	d0-d6,$12(a1)
		movem.w	d0-d6,$22(a1)
		movem.w	d0-d6,$32(a1)
.skip:
		rts

;--------------------------------------------------------------------
	
vectorizer_init:
		lea		vectorizer_lsl6add66tab,a2
		moveq	#0,d7
.l1:			
		move.w	d7,d0
		lsl.w	#6,d0
		add.w	#66,d0
		move.w	d0,(a2)+
		addq	#1,d7
		cmpi.w	#368,d7
		bne.b	.l1
		rts
		
;--------------------------------------------------------------------

vectorizer_update:
		bsr.w	vectorizer_fill
		bsr.w	vectorizer_clear
		bsr.w	vectorizer_showobjects
		;bsr.w	vectorizer_updatefade
		rts
		
;--------------------------------------------------------------------

vectorizer_clear:
		move.l	vectorizer_screens+4,a6
		adda.l	#170*46*5,a6
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		move.l	d0,a0
		move.l	d0,a1
		move.l	d0,a2
		move.l	d0,a3
		move.l	d0,a4
		move.l	#96,a5
		
		move.w	#170*46*5/(4*12*8)-1,d7
.l0:
		REPT	8
		movem.l	d0-d6/a0-a4,-(a6)
		ENDR
		dbra	d7,.l0
		
		REPT	6
		movem.l	d0-d6/a0-a4,-(a6)
		ENDR
		movem.l	d0-d6,-(a6)
		rts
						
;--------------------------------------------------------------------
	
octantbase 	= 3	; 1 for normal lines or 3 for fill lines
mintermbase	= $0b5a

		cnop	0,2
octanttab:
		dc.b	$10+octantbase
		dc.b	$50+octantbase
		dc.b	$00+octantbase
		dc.b	$40+octantbase
		dc.b	$14+octantbase
		dc.b	$54+octantbase
		dc.b	$08+octantbase
		dc.b	$48+octantbase
		
mintermtab:
		REPT 23
		dc.w	mintermbase+$0000
		dc.w	mintermbase+$1000
		dc.w	mintermbase+$2000
		dc.w	mintermbase+$3000
		dc.w	mintermbase+$4000
		dc.w	mintermbase+$5000
		dc.w	mintermbase+$6000
		dc.w	mintermbase+$7000
		dc.w	mintermbase+$8000
		dc.w	mintermbase+$9000
		dc.w	mintermbase+$a000
		dc.w	mintermbase+$b000
		dc.w	mintermbase+$c000
		dc.w	mintermbase+$d000
		dc.w	mintermbase+$e000
		dc.w	mintermbase+$f000
		ENDR

;--------------------------------------------------------------------

		MACRO<VECTORIZER_PREPARELINE>
		moveq	#0,d6				; octant

		sub.w 	d1,d3				; dy
		bpl.b	.oct2
		exg		d0,d2				
									; d3=p2-p1
									; d1=p1
		neg.w	d3					; d3=p1-p2
									; d1=p1
		sub.w	d3,d1				; d1=p1-p1+p2=p2
.oct2:
		subq	#1,d3

		move.w	d0,d4
		lsr.w	#3,d4				
		
		mulu.w	#46,d1
		
		add.w	d4,d1
		lea		(a5,d1.w),a1
		
		sub.w	d0,d2				; dx
		bpl.b	.oct1
		neg.w	d2
		addq	#2,d6
.oct1:
		cmp.w	d2,d3
		bmi.b	.oct3
		addq	#1,d6					
		exg		d2,d3
.oct3:
		move.w	d3,d4				; dy
		add.w	d4,d4				; 2*dy
		move.w	d3,d5
		sub.w	d2,d5				; dy-dx
		add.w	d5,d5				; 2*(dy-dx)
		
		add.w	d3,d3
		sub.w	d2,d3				; 2*dy-dx		
		addx.w	d6,d6
		
		add.w	d0,d0
		add.w	d2,d2
		
		move.b	(a0,d6.w),d6
		move.w	mintermtab-octanttab(a0,d0.w),d0
		move.w	(a4,d2.w),d2
		
		moveq	#$0e,d1	
		ENDM

;--------------------------------------------------------------------

		MACRO<VECTORIZER_SENDLINE>
.bltwait2:
		btst	d1,$02-BLTCON0(a6)
		bne.b	.bltwait2
		
		move.w 	d3,BLTAPTR+2-BLTCON0(a6)	; 2*dy-dx	initial error term
		movem.w d5/d4,BLTBMOD-BLTCON0(a6) 	; d6=2*dy		->BLTBMOD
											; d4=2*(dy-dx)	->BLTAMOD

		move.b	d6,BLTCON1+1-BLTCON0(a6)
		move.w	d0,BLTCON0-BLTCON0(a6)
		
		move.l  a1,BLTCPTR-BLTCON0(a6) 
		move.l  a1,BLTDPTR-BLTCON0(a6) 
		move.w	d2,BLTSIZE-BLTCON0(a6)		; size
		ENDM
		
;--------------------------------------------------------------------

vectorizer_showobjects:
		move.l	vectorizer_tunneldatapoi,a3
		move.l	vectorizer_screens+4,a2
		adda.l	#VECTORIZER_BPLSIZE*3,a2
		
		bsr.w	vectorizer_dolines
		
		lea		vectorizer_tunneldataend,a0
		cmp.l	a0,a3
		bne.b	.nowraptunnel
		lea		vectorizer_tunneldata,a3
.nowraptunnel:
		move.l	a3,vectorizer_tunneldatapoi
		
		move.l	vectorizer_shipdatapoi,a3
		move.l	vectorizer_screens+4,a2
		
		bsr.w	vectorizer_dolines
		
		lea		vectorizer_shipdataend,a0
		cmp.l	a0,a3
		bne.b	.nowrapship
		lea		vectorizer_shipdata,a3
.nowrapship:
		move.l	a3,vectorizer_shipdatapoi
		rts

;--------------------------------------------------------------------

			cnop	0,4
vectorizer_tunneldatapoi:
		dc.l	vectorizer_tunneldata
vectorizer_shipdatapoi:
		dc.l	vectorizer_shipdata

vectorizer_dolines:
		moveq	#0,d7
		move.b	(a3)+,d7	;numpoints
		subq	#1,d7
		bmi.b	.skipread
		moveq	#0,d6
		moveq	#0,d1
		lea		vectorizer_points,a6
.l0:
		subq	#1,d6
		bpl.b	.nonewhix
		move.b	(a3)+,d4
		moveq	#7,d6
.nonewhix:
		moveq	#0,d0
		move.b	(a3)+,d0	;x
		move.b	(a3)+,d1	;y
		add.b	d4,d4
		addx.w	d0,d0
		
		move.w	d0,(a6)+
		move.w	d1,(a6)+
				
		dbra	d7,.l0
.skipread:

		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
		
		lea		$dff000,a6
		
		move.l 	#$ffffffff,BLTAFWM(a6) 	; first and last mask
		move.w 	#$8000,BLTADAT(a6)
		move.w 	#$ffff,BLTBDAT(a6)
		move.w 	#46,BLTCMOD(a6) 	
		
		lea		BLTCON0(a6),a6			; smallest offet into blitter registers
		lea		octanttab,a0
		lea		vectorizer_lsl6add66tab,a4

		moveq	#0,d7
		move.b	(a3)+,d7	;numlines
		
vectorizer_dlloop:
		subq	#1,d7
		bmi.b	vectorizer_skiplines
		
		moveq	#0,d4
		move.b	(a3)+,d4	;o1
		moveq	#0,d5
		move.b	(a3)+,d5	;o2

		moveq	#0,d6		
		add.b	d5,d5
		addx.b	d6,d6
		add.b	d5,d5
		addx.b	d6,d6
		add.b	d4,d4
		addx.b	d6,d6
		add.b	d4,d4
		addx.b	d6,d6
		add.w	d6,d6
		add.w	d6,d6
		
		lea		vectorizer_points,a5
		movem.w	(a5,d4.w),d0/d1
		movem.w	(a5,d5.w),d2/d3
				
		lea		vectorizer_linejmps(pc),a5
		move.l	(a5,d6.w),a5
		jmp 	(a5)
vectorizer_skiplines:
		rts

vectorizer_linecol0:
		bra.w	vectorizer_dlloop

vectorizer_linecol1:
		move.l	a2,a5
		VECTORIZER_PREPARELINE
		VECTORIZER_SENDLINE
		bra.w	vectorizer_dlloop

vectorizer_linecol2:
		lea		VECTORIZER_BPLSIZE(a2),a5
		VECTORIZER_PREPARELINE
		VECTORIZER_SENDLINE
		bra.w	vectorizer_dlloop
		
vectorizer_linecol3:
		move.l	a2,a5
		VECTORIZER_PREPARELINE
		VECTORIZER_SENDLINE
vectorizer_linecol32:
		lea		VECTORIZER_BPLSIZE(a1),a1
		VECTORIZER_SENDLINE
		bra.w	vectorizer_dlloop
		
vectorizer_linecol4:
		lea		VECTORIZER_BPLSIZE*2(a2),a5
		VECTORIZER_PREPARELINE
		VECTORIZER_SENDLINE
		bra.w	vectorizer_dlloop
	
vectorizer_linecol5:
		move.l	a2,a5
		VECTORIZER_PREPARELINE
		VECTORIZER_SENDLINE
vectorizer_linecol52:
		lea		VECTORIZER_BPLSIZE*2(a1),a1
		VECTORIZER_SENDLINE
		bra.w	vectorizer_dlloop
	
vectorizer_linecol6:
		lea		VECTORIZER_BPLSIZE(a2),a5
		VECTORIZER_PREPARELINE
		VECTORIZER_SENDLINE
vectorizer_linecol62:
		lea		VECTORIZER_BPLSIZE(a1),a1
		VECTORIZER_SENDLINE
		bra.w	vectorizer_dlloop
	
vectorizer_linecol7:
		move.l	a2,a5
		VECTORIZER_PREPARELINE
		VECTORIZER_SENDLINE
vectorizer_linecol72:
		lea		VECTORIZER_BPLSIZE(a1),a1
		VECTORIZER_SENDLINE
vectorizer_linecol73:
		lea		VECTORIZER_BPLSIZE(a1),a1
		VECTORIZER_SENDLINE
		bra.w	vectorizer_dlloop

vectorizer_linejmps:
		dc.l	vectorizer_linecol0
		dc.l	vectorizer_linecol1
		dc.l	vectorizer_linecol2
		dc.l	vectorizer_linecol3
		dc.l	vectorizer_linecol4
		dc.l	vectorizer_linecol5
		dc.l	vectorizer_linecol6
		dc.l	vectorizer_linecol7
		
;--------------------------------------------------------------------

vectorizer_fill:
		move.l	fw_jumptable,a6
		jsr		BLTWAIT(a6)
				
		lea		BLTBASE,a6

        move.l	vectorizer_screens+8,a0
		adda.l	#5*170*46-2,a0
		
        clr.w	BLTAMOD(a6)
        clr.w	BLTDMOD(a6)
        move.w	#$09f0,BLTCON0(a6)	; minterm $f0 = a, channels $9 = a&d
		move.w	#$0012,BLTCON1(a6)	; descending and fill mode
		move.l	a0,BLTAPTR(a6)        			
        move.l	a0,BLTDPTR(a6)        			
        move.w	#$d497,BLTSIZE(a6)
	
		;bsr.w	bltwait
	    rts
		
;--------------------------------------------------------------------

		cnop	0,4
vectorizer_screens:
		dc.l	vectorizer_screen1,vectorizer_screen2,vectorizer_screen3,vectorizer_screen4
vectorizer_screen:
		dc.l	vectorizer_screen1

vectorizer_page:
		lea 	vectorizer_screens,a0
		
		move.l	$00(a0),d0
		move.l	$04(a0),d1
		move.l	$08(a0),d2
		move.l	$0c(a0),d3
		
		move.l	d0,$04(a0)
		move.l	d1,$08(a0)
		move.l	d2,$0c(a0)
		move.l	d3,$00(a0)
		
		move.l	d2,d0
		
		lea		vectorizer_copperbpl,a6
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		addi.l	#VECTORIZER_BPLSIZE*1,d1
		addi.l	#VECTORIZER_BPLSIZE*2,d2
		addi.l	#VECTORIZER_BPLSIZE*3,d3
		addi.l	#VECTORIZER_BPLSIZE*4,d4
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
		move.w	d4,$26(a6)
		swap	d4
		move.w	d4,$22(a6)
		rts

;--------------------------------------------------------------------

		cnop	0,2
vectorizer_sync:
		dc.w	0

vectorizer_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	fw_jumptable,a6
		jsr		MUSICPROXY(a6)
		addq.w	#1,vectorizer_sync
		bsr.w	vectorizer_updatefade
			
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
				
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;********************************************************************
			
				section "vectorizer_data",data

				cnop	0,2
vectorizer_tunneldata:
	incbin "../data/vectorizer/tunnel.dat"
vectorizer_tunneldataend:

vectorizer_shipdata:
	incbin "../data/vectorizer/sat.dat"
vectorizer_shipdataend:
				
				cnop	0,2
vectorizer_rndtab:
	incbin "../data/pic/rndtab.dat"

;********************************************************************
			
				section "vectorizer_empty",bss
				
				cnop	0,2
vectorizer_lsl6add66tab:
				ds.w	368
vectorizer_points:
				ds.w	2*64

;********************************************************************
			
				section "vectorizer_emptychip",bss,chip

				cnop	0,8
vectorizer_screen1:	ds.b	VECTORIZER_BPLSIZE*5
vectorizer_screen2:	ds.b	VECTORIZER_BPLSIZE*5
vectorizer_screen3:	ds.b	VECTORIZER_BPLSIZE*5
vectorizer_screen4:	ds.b	VECTORIZER_BPLSIZE*5

;********************************************************************

				section "vectorizer_copper",data,chip

vectorizer_copperlist:
				dc.l	$008e5481,$0090fcd1,$00920028,$009400d8	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
vectorizer_col0smc2:
				dc.l	$01800fff
vectorizer_copperbpl:	
				dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;5 bitplane pointer
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000
				
vectorizer_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes
	
				dc.l	$010ffffe,$01005200						;wait x: 15, y: 1, turn on 5 bitplanes
				dc.l	$400ffffe,$009c8010						;wait x: 15, y: 33, start irq
				dc.l	$540ffffe
vectorizer_col0smc:
				dc.l	$01800000
				dc.l	$fc0ffffe,$01800fff
				
				dc.l	$fffffffe 								;wait for end

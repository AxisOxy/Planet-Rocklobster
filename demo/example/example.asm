PIC_WIDTH 		= 320						;image width in pixels
PIC_HEIGHT		= 256						;image height in pixels
PIC_BPLSIZE		= PIC_WIDTH*PIC_HEIGHT/8	;size of a single bitplane of the image in bytes
PIC_NUMFRAMES	= 500						;runtime of part in vsyncs

	
		include "../framework/framework.i"	;include the framework
		include "../launcher/timings.asm"	;include the global demo timings
	
	ifnd _DEMO
	include "../framework/parttester.asm"	;if we are a stand-alone build, include the part-tester. 
											;this contains a system startup-code
											;and emulates how the framework would behave, if this is linked to a trackmo.
	endc	// _DEMO

	
			section	"pic_code",code 		;code section containing the entry-point. must be the first section
		
;since this should be useable as a transition to cover loading-times (executenextpartalt), 
;we begin the code with a jump-table to start and shutdown functions.
entrypoint:
		bra.b	pic_start					
		bra.b	pic_end
		
;start function
pic_start:									
		move.l	a6,fw_jumptable				;the base-adress of the framework is given into the part on a6. 
											;store it to a variable to use it later.
	
		bsr.w	pic_init					;initialise picture

		lea		pic_coppersprites,a0		;get sprite-block of copperlist
		move.l	fw_jumptable(pc),a6			;get framework jump-table
		jsr		CLEARSPRITES(a6)			;turn off all sprites
	
		move.w	#TIME_PIC2_START,d0			;get timing-mark for this part (in standalone builds, this should be 0). we dont want to wait until we can test.
		move.l	fw_jumptable(pc),a6			;get framework jump-table
		jsr		WAITFORFRAME(a6)			;wait for the start timing-mark before showing the picture
	
		move.l	#pic_copperlist,a0			;get this parts copperlist
		move.l	#pic_irq,a1					;get this parts irq
		move.l	fw_jumptable(pc),a6			;get framework jump-table
		jsr		SETCOPPER(a6)				;activate our own irq and copperlist
		
		bsr.w	pic_fadein					;fadein picture

		move.l	fw_jumptable(pc),a6			;get framework jump-table
		jsr		GETFRAME(a6)				;get the actual frame
		addi.w	#PIC_NUMFRAMES,d0			;add the amount of frames the picture should be visible to calc endframe
		move.w	d0,pic_endframe				;move endframe to a variable to use it later
		
	ifd _DEMO
		rts									;if we are a trackmo build, we return now to free the cpu for load and decrunch.
											;else just continue to wait for the endframe and fadeout the picture.
	endc ;_DEMO
		
;shutdown function
pic_end:	
		move.l	fw_jumptable(pc),a6			;get framework jump-table
		move.w	pic_endframe(pc),d0			;get the endframe
		jsr		WAITFORFRAME(a6)			;wait until the time is over

		bsr.w	pic_fadeout					;fadeout the picture
		
		jsr		SETBASECOPPER(a6)			;switch back to default irq and copperlist (empty screen)
		rts									;exit part
			
		cnop	0,4
fw_jumptable:
		dc.l	0							;the jumptable to the framework
pic_endframe:
		dc.w	0							;the frame when the part should be stopped
		
;--------------------------------------------------------------------

pic_init:
		lea 	pic_image,a0				;get pointer to image to parse header
		move.w	(a0)+,d0					;get palette size in numentries
		move.w	(a0)+,d1					;get width of bitplane in bytes
		move.w	(a0)+,d2					;get size of bitplane in bytes
		move.l	(a0)+,d3					;get size of image in bytes
		
		add.w	d0,d0
		ext.l	d0							;for a valid pointer we need a .l
		add.l	a0,d0						;skip palette, advance pointer by 2*numentries
		
		lea		pic_copperbpl,a0			;get copperlist bitplane pointers
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		move.l	d0,d4
		addi.l	#PIC_BPLSIZE*1,d1
		addi.l	#PIC_BPLSIZE*2,d2
		addi.l	#PIC_BPLSIZE*3,d3
		addi.l	#PIC_BPLSIZE*4,d4			;create the 5 bitplane pointers
		move.w	d0,$06(a0)
		move.w	d1,$0e(a0)
		move.w	d2,$16(a0)
		move.w	d3,$1e(a0)
		move.w	d4,$26(a0)					;store the 5 lo-words of the bitplane pointers
		swap	d0
		swap	d1
		swap	d2
		swap	d3
		swap	d4							;swap the 5 hi-words of the bitplane pointers down
		move.w	d0,$02(a0)
		move.w	d1,$0a(a0)
		move.w	d2,$12(a0)
		move.w	d3,$1a(a0)
		move.w	d4,$22(a0)					;store the 5 hi-words of the bitplane pointers
		rts

;--------------------------------------------------------------------
	
pic_fadein:
		moveq	#0,d0
.l0:
		move.w	d0,-(sp)					;backup d0

		move.w	#$6ae,d4					;fadein from light-blue
		bsr.w	pic_fade					;fade colors
		
		move.w	(sp)+,d0					;restore d0
		
		move.l	fw_jumptable(pc),a6			;get framework jump-table
		jsr		VSYNC(a6)					;wait until vsync
	
		addq	#1,d0
		cmpi.w	#65,d0						;count lerpfactor loop from 0-64
		bne.b	.l0
		rts
		
;--------------------------------------------------------------------

pic_fadeout:
		moveq	#64-1,d0
.l0:
		move.w	d0,-(sp)					;backup d0

		move.w	#$fff,d4					;fadeout to white
		bsr.w	pic_fade					;fade colors
		
		move.w	(sp)+,d0					;restore d0
		
		move.l	fw_jumptable(pc),a6			;get framework jump-table
		jsr		VSYNC(a6)					;wait until vsync
			
		subq	#1,d0						;count lerpfactor loop from 63-0
		bpl.b	.l0
		rts

;--------------------------------------------------------------------
	
pic_fade:
		lsr.w	#2,d0						;divide lerpfactor by 2, so we have 0-16

		lea 	pic_image,a0				;get picture
		move.w	(a0)+,d7					;get palette size in numentries
		addq.l	#8,a0						;skip unsused part of header
		
		move.w	d4,d5
		move.w	d5,d6
		andi.w	#$f00,d4					;fadeto-color r
		andi.w	#$0f0,d5					;fadeto-color g
		andi.w	#$00f,d6					;fadeto-color b
		
		lea		$dff180,a1					;amiga-colors regs
		subq	#1,d7						;palette size-1 for dbra loop
.l0:	
		move.w	(a0)+,d1					;get color from picture palette
		move.w	d1,d2
		move.w	d1,d3
		andi.w	#$f00,d1					;picture color r
		andi.w	#$0f0,d2					;picture color g
		andi.w	#$00f,d3					;picture color b
		sub.w	d4,d1						;delta r
		sub.w	d5,d2						;delta g
		sub.w	d6,d3						;delta b
		mulu.w	d0,d1						;delta r*lerpfactor
		mulu.w	d0,d2						;delta g*lerpfactor
		mulu.w	d0,d3						;delta b*lerpfactor
		lsr.w	#4,d1						;delta r*lerpfactor>>4
		lsr.w	#4,d2						;delta b*lerpfactor>>4
		lsr.w	#4,d3						;delta r*lerpfactor>>4
		add.w	d4,d1						;final r
		add.w	d5,d2						;final g
		add.w	d6,d3						;final b
		andi.w	#$f00,d1					;mask out unused bits
		andi.w	#$0f0,d2					;mask out unused bits
		andi.w	#$00f,d3					;mask out unused bits
		or.w	d2,d1
		or.w	d3,d1						;final color=r | g | b

		move.w	d1,(a1)+					;store color
		dbra	d7,.l0						;loop through all colors
		rts

;--------------------------------------------------------------------

pic_irq:		
		movem.l	d0-d7/a0-a6,-(sp)			;save all registers to stack
		
		move.l	fw_jumptable(pc),a6			;get framework jump-table
		jsr		MUSICPROXY(a6)				;call the base-irq function, this updates the musicplayer and increments the global framecounter.

		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)						;acknowledge the copper-irq.
		move.w	d0,(a6)						;this is done twice, due to some broken 68060 boards.
		
		movem.l	(sp)+,d0-d7/a0-a6			;retore all registers from stack
		nop									;this nop is also needed, because some 68060 cards are broken
		rte  								;end of irq

;********************************************************************

				section "pic_copper",data,chip		;section for copperlist

pic_copperlist:	dc.l	$008e2c81,$00902cc1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

pic_copperbpl:	dc.l	$00e00000,$00e20000,$00e40000,$00e60000	;declare 5 bitplane pointers, these will be filled by the init-function
				dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
				dc.l	$00f00000,$00f20000

pic_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers, used to disable all formerly visible sprites
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000
				
				dc.l	$01000200,$01020000,$01040000			;turn off all bitplanes, set scroll values to 0, clear bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes, both 0
			
				dc.l	$009c8010								;start the copper-irq
				dc.l	$2c0ffffe,$01005200						;wait x: 15, y: 44, turn on 5 bitplanes

				dc.l	$fffffffe 								;wait for end

;--------------------------------------------------------------------
				
				cnop	0,8
pic_image:
	incbin "../data/example/example.ami"		;include the picture into chip-mem

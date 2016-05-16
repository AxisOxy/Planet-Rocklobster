; This bootblock is heavily based on the one from Dep/TBL.
; Changes by Axis/Oxyron: - Changed memory allocation to handle chipmem only machines with >= 1 MB chipmem
;			  - Some size optimizations
;			  - The interface to the following framework stage

; vim: syntax=asm68k ts=8 sw=8

FUNCDEF		MACRO
_LVO\1		EQU lvocnt
lvocnt		SET lvocnt-LIB_VECTSIZE
		ENDM

		include "exec/execbase.i"

		include "hardware/adkbits.i"
		include "hardware/cia.i"
		include "hardware/custom.i"
		include "hardware/dmabits.i"
		include "hardware/intbits.i"

		include "lvo/lvo.i"

;		include main.i

trackbuffersize		= 6400*2
remaindersize		= _end-faststart

		rsreset
boot_AllocChip	rs.l	1
boot_AllocFast	rs.l	1
boot_LoadFunc	rs.l	1
boot_SIZE	EQU	__RS


MOTOR_FRAMES	equ	50	; #frames to keep motor running after load is done
BOOTBLOCKSZ	equ	1024	
CUSTOM		equ	$dff000

MEMF_ANY   	equ	(0)	; Any memory
MEMF_CHIP   	equ	(1<<1)	; Chip memory
MEMF_FAST	equ	(1<<2)	; Fast memory
MEMF_LOCAL  	equ	(1<<8)	; Memory that does not go away at RESET
MEMF_24BITDMA	equ	(1<<9)	; DMAable memory within 24 bits of address
MEMF_KICK	equ	(1<<10)	; Memory that can be used for KickTags
MEMF_CLEAR	equ	(1<<16)	; AllocMem: NULL out area before return
MEMF_LARGEST	equ	(1<<17)	; AvailMem: return the largest chunk size
MEMF_REVERSE	equ	(1<<18)	; AllocMem: allocate from the top down
MEMF_TOTAL	equ	(1<<19)	; AvailMem: return total size of memory
MEMF_NO_EXPUNGE	equ	(1<<31)	; AllocMem: Do not cause expunge on failure

		rsreset

_start:
		dc.b	'D','O','S',0		; disk type
		dc.l	0			; checksum
		dc.l	880			; root block

_entrypoint:
		; Because this is a bootblock, we will have ExecBase in a6 here

		lea.l	CUSTOM,a5

		move.l	#(MEMF_LARGEST|MEMF_CHIP|MEMF_CLEAR),d1
		lea.l	chipblock(pc),a4
		jsr		grab_mem(pc)
		
		move.l	#(MEMF_LARGEST|MEMF_ANY|MEMF_CLEAR),d1
		lea.l	fastblock(pc),a4
		jsr		grab_mem(pc)

		move.l	4(a4),d0
		cmpi.l	#100000,d0	; if we have less than 100 kb fastmem, no memory expansion is available. 
							; show out of memory error!
		blt.w	error
		
		lea		chipblock(pc),a0
		lea		chipblock2(pc),a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		
		;jsr		_LVOForbid(a6)
		;jsr		_LVODisable(a6)
		
		; move stack to fastmem
		move.l	#4096,d0
		jsr		alloc_fast
		add.w	#4096,a0
		move.l	a0,a7

		; Enter supervisor mode with user stack.
		;jsr	_LVOSuperState(a6)

initdsk:	move.w	#$4489,dsksync(a5)	; use stock MFM sync word
		move.w	#$7f00,adkcon(a5)	; clear all disk bits
		move.w	#ADKF_SETCLR|ADKF_MFMPREC|ADKF_FAST|ADKF_WORDSYNC,adkcon(a5)

		move.l	#DISKDATASZ,d0
		bsr		alloc_fast
		lea.l	dskdata(pc),a1
		move.l	a0,(a1)

		; assume we are at track 0
		btst	#CIAB_DSKTRACK0,(a4)
		bne	error
		
		move.l	#trackbuffersize,d0		; we will load 6400 words at a time (12800 bytes)
		jsr		alloc_chip
		lea.l	trackbuf(pc),a1
		move.l	a0,(a1)

		; Disable all interrupts and requests
		move.w	#$7fff,d0
		move.w	d0,intena(a5)
		move.w	d0,intreq(a5)
				
		if 1
		; Copy remainder of bootblock to chip continue to execute there
		move.l	#remaindersize,d0
		jsr		alloc_chip
		move.l	a0,a2
		lea.l	faststart(pc),a1
		subq.w	#1,d0
.copy:		move.b	(a1)+,(a0)+
		dbra	d0,.copy

		; TODO need _LVOClearCache(a6)...
	
		jmp	(a2)
		endif

		; ** Resume point in fastmem **
faststart:
		; allocate a bunch of space for the first part.. fixme
		move.l	#12*1024,d0
		jsr		alloc_fast
		lea.l	fastbuf(pc),a1
		move.l	a0,(a1)

		; Install interrupt handler
		moveq.l	#0,d0
		;move.w	AttnFlags(a6),d1
		;and.w	#1,d1
		;beq.s	.mc68k
		;dc.w $4e7a,$0801	; movec.l	vbr,d0
.mc68k:		move.l	d0,a0

		lea.l	vblank_handler(pc),a1
		move.l	a1,$6c(a0)

		lea.l	dskblk_handler(pc),a1
		move.l	a1,$64(a0)

		; Enable vblank interrupt
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB|INTF_DSKBLK,intena(a5)

		; Disable all DMA
		move.w	#$7FFF,dmacon(a5)

		move.w	#$000,$dff180

		; Enable master DMA bit and disk DMA
		move.w  #(DMAF_SETCLR|DMAF_MASTER|DMAF_DISK),dmacon(a5)

		move.l	fastbuf(pc),a0
		sub.l	a1,a1
		moveq	#3,d0
		move.w	#24,d1
		jsr		begin_load

		move.l	dskdata(pc),a1
.wait_boot:	tst.l	TargetPtr(a1)
		bne.s	.wait_boot

		move.l	a0,a2

		move.l	#8,d0
		jsr		alloc_fast

		lea.l	chipblock2(pc),a1
		move.l	a1,0(a0)
		lea.l	fastblock(pc),a1
		move.l	a1,4(a0)

		move.w	#$000,$dff180
		jmp	(a2)
error:
		move.w	#$f00,$dff180
		bra.s	error

grab_mem:	
		jsr	_LVOAvailMem(a6)
		cmp.l	#512*1024,d0
		blt.b	.clampmem
		move.l	#512*1024,d0
.clampmem:

		move.l	d0,(a4)
		jsr	_LVOAllocMem(a6)
		move.l	d0,4(a4)
		rts


CIAF_DSKSELx	EQU	CIAF_DSKSEL0|CIAF_DSKSEL1|CIAF_DSKSEL2|CIAF_DSKSEL3

DSKSTATE_SAME		EQU	-1	

DSKSTATE_IDLE		EQU	0
DSKSTATE_WAITMOTOR	EQU	2
DSKSTATE_SYNCTRACK	EQU	4
DSKSTATE_WAITREAD	EQU	6

DSKDIREC_TOCENTER	EQU	0
DSKDIREC_TOEDGE		EQU	1

		rsreset
DskWait		rs.w	1		; frames to wait before entering state machine again
CurState	rs.w	1		; index into into state code offset table
DmaDone		rs.w	1		; written=1 from disk interrupt handler, cleared before DMA
MotorTimeout	rs.w	1		; frames left to wait before turning off drive motor
TargetPtr	rs.l	1		; target data ptr, bumped after each track
CompletionPtr	rs.l	1		; ptr to word to write=1 when entire load is done for polling
		align	2
CurTrack	rs.b	1		; must start at even
CurSector	rs.b	1
		align	2
StartTrack	rs.b	1		; 0 - 79, must start at even
StartSector	rs.b	1		; 0 - 10
		align	2
EndTrack	rs.b	1		; 0 - 80, must start at even
EndSector	rs.b	1		; 0 - 10
TargTrack	rs.b	1
		align	4

DISKDATASZ	EQU	__RS

	; common setup for these state machine handlers:
	; a0 = dskdata
	; a3 = CIA-A Port A ($bfe001))
	; a4 = CIA-B Port B ($bfd100)
	; a5 = CUSTOM

dskhandlers:	; start point indexed by offsets for state machine jumping

idle:		tst.l	TargetPtr(a0)
		beq.s	.maybe_motor_off

		move.w	MotorTimeout(a0),d0
		bne.s	.already_on

		; Enable drive motor
		or.b	#CIAF_DSKSELx,(a4)	; deselect all drives
		bclr.b	#CIAB_DSKMOTOR,(a4)
		bclr.b	#CIAB_DSKSEL0,(a4)	; select drive 0

.already_on:	moveq	#DSKSTATE_WAITMOTOR,d0
		rts

.maybe_motor_off:
		move.w	MotorTimeout(a0),d0
		beq.s	delay			; motor already off

		subq.w	#1,d0
		move.w	d0,MotorTimeout(a0)
		bne.s	delay

		or.b	#CIAF_DSKMOTOR|CIAF_DSKSEL0,(a4)
		bclr.b	#CIAB_DSKSEL0,(a4)
		bset.b	#CIAB_DSKSEL0,(a4)

		; Common exit blocks to save space
delay:		move.w	#1,DskWait(a0)

same_state:	moveq	#DSKSTATE_SAME,d0
		rts

wait_motor:	btst.b	#CIAB_DSKRDY,(a3)
		bne.s	same_state
		moveq	#DSKSTATE_SYNCTRACK,d0
		rts

sync_track:	move.b	TargTrack(a0),d1
		move.b	d1,d0
		move.b	CurTrack(a0),d4
		move.b	d4,d2
		moveq	#-2,d3			; fffffffe
		and.b	d3,d0
		and.b	d3,d2
		cmp.b	d0,d2			; target cylinder reached?
		beq.s	begin_read
		blt.s	.step_in		; cur track less than target, seek in (towards higher cyl)

.step_out:	bset.b	#CIAB_DSKDIREC,(a4)
		subq.b	#2,d4
		bra.s	.dostep

.step_in:	bclr.b	#CIAB_DSKDIREC,(a4)
		addq.b	#2,d4

.dostep:	move.b	d4,CurTrack(a0)

		bclr.b	#CIAB_DSKSTEP,(a4)
		tst.w	$dff1fe			; delay
		bset.b	#CIAB_DSKSTEP,(a4)
		
		; Wait one frame for the seek to settle.
		; The max time is 15 ms for the step direction change + 3 ms for track change. 20 ms is enough.
		bra.s	delay

begin_read:
		; Select which head to use (even tracks are on lower side of the disk)
		; TODO: Does this need timing to work properly?
		;
		; DSKSIDE: Specify which disk head to use. Zero
		; indicates the upper head. DSKSIDE must be stable for 100
		; microseconds before writing. After writing, at least 1.3
		; milliseconds must pass before switching DSKSIDE.

		move.b	d1,CurTrack(a0)		; we're there

		btst	#0,d1
		beq	.lower
.upper:		bclr.b	#CIAB_DSKSIDE,(a4)
		bra	.head_ok
.lower:		bset.b	#CIAB_DSKSIDE,(a4)

.head_ok:	clr.w	DmaDone(a0)
		move.w	#INTF_DSKBLK,intreq(a5)		; clear disk int request in case there is a pending req
		move.l	trackbuf,dskpt(a5)		; set destination buffer
		move.w	#$8000+6400,d0			; load 6400 words, enable DMA bit in DMACON
		move.w	d0,dsklen(a5)
		move.w	d0,dsklen(a5)			; write dsklen twice to kick DMA
		moveq	#DSKSTATE_WAITREAD,d0
		rts

wait_read:	move.w	DmaDone(a0),d0
		beq.w	delay

		;move.w	#0,dsklen(a5)
		;move.w	#DMAF_DISK,dmacon(a5)

		move.l	trackbuf(pc),a1
		jsr	mfm_decode

		; done with this track
		add.b	#1,TargTrack(a0)
		move.b	TargTrack(a0),d0
		cmp.b	EndTrack(a0),d0
		bgt.s	.done

		moveq	#DSKSTATE_SYNCTRACK,d0
		rts

.done:		move.w	#MOTOR_FRAMES,MotorTimeout(a0)

		clr.l	TargetPtr(a0)

		move.l	CompletionPtr(a0),a1
		cmp.l	#0,a1
		beq.s	.leave
		move.w	#1,(a1)

.leave:		moveq	#DSKSTATE_IDLE,d0
		rts

dskst_offset:
		dc.w	idle-dskhandlers
		dc.w	wait_motor-dskhandlers
		dc.w	sync_track-dskhandlers
		dc.w	wait_read-dskhandlers

dskdata:	dc.l	0

dskblk_handler:
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	#CUSTOM,a5

		; Clear request bit & disable interrupt
		move.w	#INTF_DSKBLK,d0
		move.w	d0,intreq(a5)

		move.l	dskdata(pc),a0
		move.w	#1,DmaDone(a0)
.nope:
		movem.l	(sp)+,d0-d7/a0-a6
		rte
		
vblank_handler:
		movem.l	d0-d7/a0-a6,-(sp)

		move.l	dskdata(pc),a0
		lea.l	$bfe001,a3		; CIA-A port A
		lea.l	$bfd100,a4		; CIA-B port B
		lea.l	CUSTOM,a5

		; Clear request bit
		move.w	#INTF_VERTB,intreq(a5)

		; Decrement frame wait counter if any.
.pump:		move.w	DskWait(a0),d0
		beq.s	.advance
		subq.w	#1,DskWait(a0)
		bra.s	.leave

.advance:	move.w	CurState(a0),d0
		lea.l	dskst_offset(pc),a1
		move.w	(a1,d0),d0
		lea.l	dskhandlers(pc),a2
		adda.w	d0,a2
		moveq.l	#0,d0
		jsr	(a2)
		
		tst.w	d0
		bmi.s	.leave

		move.w	d0,CurState(a0)
		bra.s	.pump

.leave:		movem.l	(sp)+,d0-d7/a0-a6
		rte

alloc_fast:
		lea.l	fastblock(pc),a1
		bra.s	_doalloc
alloc_chip:
		lea.l	chipblock(pc),a1

_doalloc:	addq.l	#3,d0
		and.b	#$fc,d0
		sub.l	d0,(a1)
		move.l	4(a1),a0
		add.l	d0,4(a1)
		rts

; a0: dskdata structure
; a1: just loaded track buffer
;
; This procedure will decode desired sectors from the DMA buffer passed in a1
; and copy the resulting data to the target pointer defined in the dskdata struct.
mfm_decode:
		movem.l	a0-a6/d0-d7,-(sp)

		; mask to keep every other bit
		moveq.l	#0,d4		; count sectors decoded
		move.l	#$55555555,d5
		move.l	a1,a2
		add.l	#6400*2-400,a2	; max threshold, for error bounds

		move.w	#10,d7		; 11 sectors per track
.skip_sync:	move.w	#$4489,d6	; skip 0-2 sync words
		cmp.w	(a1),d6
		bne	.header
		adda.w	#2,a1
		cmp.w	(a1),d6
		bne	.header
		adda.w	#2,a1
.header:
		; Decode sector header.
		; Because sectors can appear in shifted order due to how the
		; drive loads them, we don't know which sector this is.
		; Consequently, we also don't know yet if the user wants this
		; sector decoded or not, so we much peek at the sector number.
		moveq.l	#0,d0
		move.w	2(a1),d0	; even bits
		move.w	6(a1),d1
		and.w	d5,d0
		and.w	d5,d1
		add.w	d0,d0	; d0 <<= 1
		or.w	d1,d0	; d0 = FF TT {SS SG}
		move.b	d0,d3	;
		lsr.w	#8,d0	; d0 = SS

		; should checksum here - no space to do it :)

		; compute an Track/Sector 16 bit id for this sector to see if it is in range
		; - do this by comparing words
		move.b	d0,CurTrack+1(a0)
		move.w	CurTrack(a0),d2
		;move.b	d0,d2			; d2 = CurTrack << 8 | CurSector
		;move.w	d2,CurTrack(a0)		; update word in memory too

		cmp.w	StartTrack(a0),d2
		blt.s	.nextsec		; sector lies before requested range
		cmp.w	EndTrack(a0),d2
		bge.s	.nextsec		; sector lies after requested range

		; Decode this sector as it is the range.

		; Shift down the sectors in the first track. E.g. if only sector 9 and 10
		; are wanted from the initial starting track, we subtract the starting sector.
		move.b	StartTrack(a0),d1
		cmp.b	CurTrack(a0),d1
		bne	.ok

		sub.b	StartSector(a0),d0

.ok:		; Compute offset into target buffer where the decoded data will end up.
		lsl.w	#8,d0
		add.w	d0,d0	; d1 = SS * 512

		move.l	TargetPtr(a0),a3
		add.w	d0,a3
		lea.l	56(a1),a4		; odd data
		lea.l	568(a1),a5		; even data

		addq.w	#1,d4

		; This should execute much faster on the blitter, even when the
		; target memory is in fast ram.
		;
		; Idea:
		; - Wait for blitter
		;
		; - loop for each sector
		;   - If target memory is in chip:
		;	Wait for blitter
		;	Set up blit directly from MFM buffer to dest buffer
		;   - If target memory is in fast:
		;	Set up blit to trash MFM buffer
		;	Wait for blitter
		;	Copy decoded MFM to fast (loop)
		;	Advanced version can double buffer copy and blitter
		;
		; - Wait for blitter

		move.w	#127,d6		; 128 longwords of mfm data = 512 bytes output
.decode:	move.l	(a4)+,d0
		move.l	(a5)+,d1
		and.l	d5,d0
		and.l	d5,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a3)+
		;move.l	d5,(a3)+	; for debugging, fill with 0101..
		dbra	d6,.decode
		
.nextsec:	add.w	#900,a1
.skip_gap:	cmp.w	#$4489,(a1)+	; this could fail..
		bne.s	.skip_gap

.continue:	dbra	d7,.skip_sync

.leave:		lsl.l	#8,d4
		add.l	d4,d4
		add.l	d4,TargetPtr(a0)

		movem.l	(sp)+,a0-a6/d0-d7
		rts
		
; -----------------------------------------------------------------------------
; Trackloader API
; -----------------------------------------------------------------------------

		; Begin loading sectors
		; a0.l = dest ptr
		; a1.l = completion word writeback
		; d0.w = first sector (0 - 1759)
		; d1.w = sector count (sectors are 512 bytes)

begin_load:	movem.l	a2/d2,-(sp)

		move.l	dskdata(pc),a2
		tst.l	TargetPtr(a2)
		bne	error

		move.w	d0,d2

		divu.w	#11,d0
		move.b	d0,StartTrack(a2)
		move.b	d0,TargTrack(a2)
		swap	d0
		move.b	d0,StartSector(a2)

		add.w	d1,d2
		divu.w	#11,d2
		move.b	d2,EndTrack(a2)
		swap	d2
		move.b	d2,EndSector(a2)

		move.l	a1,CompletionPtr(a2)
		move.l	a0,TargetPtr(a2)
		movem.l	(sp)+,a2/d2
		rts
	
chipblock:	dc.l	0,0
chipblock2:	dc.l	0,0
fastblock:	dc.l	0,0

trackbuf:	dc.l	0
fastbuf:	dc.l	0

_end:

CODESIZE	equ	_end-_start

		if CODESIZE>BOOTBLOCKSZ
		fail Bootblock is too big!
		endif
;_padding:
	;dcb.b BOOTBLOCKSZ-CODESIZE, 0

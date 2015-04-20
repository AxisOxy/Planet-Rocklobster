;global constants

;the delay for the music start in vsyncs
;this is to compensate between uae and original hardware
;uae always hangs 300 ms behind with the sound
;MUSIC_START_DELAY	= 1
MUSIC_START_DELAY	= 15


;reserved size for dynamic allocation in single part startup
;can be overriden with USE_CUSTOM_ALLOC defined
	ifnd USE_CUSTOM_ALLOC
CHIPMEM_SIZE = 4
FASTMEM_SIZE = 4
	endc ;USE_CUSTOM_ALLOC

MAX_MEMSTATES			= 3			; the amount of memory states
MAX_HUNKS				= 8			; maximum amount of hunks (increase this when a part produces the ERROR_TOOMANYHUNKS

;enum for memory allocation strategy
MEMMODE_UP				= 0			; memory will be allocated bottom->up
MEMMODE_DOWN			= 1			; memory will be allocated top->down

;structure describing a memory state
MEMSTATE_START			=  0		; lower boundary of memory stack
MEMSTATE_END			=  4		; upper boundary of memory stack
MEMSTATE_POINTERBOTTOM	=  8		; actual alocation stack pointer
MEMSTATE_POINTERTOP		= 12		; actual alocation stack pointer
MEMSTATE_SIZE			= 16		; size of memstate

;enum for memory types
MEMTYPE_GENERIC			= 0			; generic memory (can be fast or chipmem)
MEMTYPE_CHIP			= 1			; chip-memory
MEMTYPE_FAST			= 2			; fast-memory
MEMTYPE_STRANGE			= 3			; dont really know, what this is?!

;enum for hunk types
HUNK_HEADER				= $03F3		; executable header
HUNK_CODE				= $03E9		; hunk containing code
HUNK_DATA				= $03EA		; hunk containing data
HUNK_BSS				= $03EB		; empty memory hunk
HUNK_RELOC32			= $03EC		; hunk continaing relocation data
HUNK_END				= $03F2		; end of file hunk
			
;error codes
ERROR_OUTOFMEMORY		= $0f00			; one of the memory stacks ran out of memory
ERROR_TOOMANYHUNKS		= $00f0 		; the executable has too many hunks. see: MAX_HUNKS
ERROR_HUNKBROKEN		= $000f 		; one of the executables hunks is broken (e.g. header or compressed hunk).
ERROR_INVALID_PARAMS	= $0ff0			; one of the api functions was called with invalid parameters
ERROR_DISK				= $00ff			; error loading via trackloader

;--------------------------------------------------------------------
;	system lib vector offsets
;--------------------------------------------------------------------

_MemAny			= 0
_MemPublic		= 1
_MemChip		= 2
_MemFast		= 4
		
;--------------------------------------------------------------------
;	public framework
;--------------------------------------------------------------------

fw_start:
	
		ifd _DEMOSTARTUP

			include "../framework/startupcodetrackmo.asm"
	
		else // _DEMOSTARTUP
				
			include "../framework/startupcodesingle.asm"
			
		endc // _DEMOSTARTUP
		
;--------------------------------------------------------------------
	
fw_regclear:	blk.l	$0f,$00000000

fw_spritetab:	dc.l	$00000000,$00000000,$00000000,$00000000
				dc.l	$00000000,$00000000,$00000000,$00000000
				
;--------------------------------------------------------------------
;sets the base copperlist and irq (empty screen with musicplayer)
;destroys: a0-a1
setbasecopper:		
		move.l	fw_copperlist(pc),a0
		lea		fw_irq(pc),a1
		bra.w	setcopper
	
;--------------------------------------------------------------------
;sets a new copperlist and irq
;a0 - the new copperlist
;a1 - the new irq
setcopper:
		bsr.w	bltwait
		bsr.w	vsync
		move.l	a0,$dff080
		move.l	a1,$006c
		clr.w	$dff088
		move.w	#$8240,$dff096		;master & blitter dma
		;move.w	#$81a0,$dff096		;copper, bitplane & sprite dma
		move.w	#$8180,$dff096		;copper & bitplane dma
		move.w	#$c010,$dff09a		;copper IRQ
		rts
	
;--------------------------------------------------------------------
;waits until the blitter is finished
bltwait:	
		move.w	#$8400,$dff096
.bl0:	
		btst	#$0e,$dff002
		bne.b	.bl0
		move.w	#$0400,$dff096
		rts		

;--------------------------------------------------------------------
;waits for the next vertical blank
vsync:	
		btst	#$00,$dff005
		beq.b	vsync
.vs0: 
		btst	#$00,$dff005
        bne.b	.vs0
		rts		

;--------------------------------------------------------------------
;this function must be called by every part in the vbl-/copper-irq
;increases the global framecounter (for timing purposes) and calls the musicplayer
;destroys: d0-d7/a0-a6
musicproxy:
		;move.w	#$fff,$dff180
		lea		fw_start(pc),a5
		addq.w	#1,fw_framecounter-fw_start(a5)
	
		tst.w	music_enabled-fw_start(a5)
	;	beq.b	.skipmus
		;move.w	#$fff,$dff180
	;	bsr.w	musicplay
		;clr.w	$dff180
.skipmus:

		;move.w	#$000,$dff180
		rts

fw_framecounter:
		dc.w	0

;--------------------------------------------------------------------
;waits until the global framecounter reaches the given frame
;d0.w - frame to wait for
waitforframe:
		btst	#$06,$bfe001
		beq.b	.endwait
		
		cmp.w 	fw_framecounter(pc),d0
		bpl.b	waitforframe
.endwait:
		rts

;--------------------------------------------------------------------
;returns if the global framecounter reached the given frame
;d0.w - frame to check against
;signflag - positive if not reached, else negative
isframeover:
		cmp.w 	fw_framecounter(pc),d0
		rts

;--------------------------------------------------------------------
;waits the given amount of vsyncs
;d0.w - the amount of vsyncs to wait
waitxframes:
		add.w	fw_framecounter(pc),d0
		bra.b 	waitforframe

;--------------------------------------------------------------------
;returns the actual global framecounter in d0.w
getframe:
		move.w	fw_framecounter(pc),d0
		rts

;--------------------------------------------------------------------

		cnop	0,2
framestoreoffset:
		dc.w	0
framestore:
		ds.w	32

;stores the actual frame to the framestore list
;destroys: d0/d7/a0
storeframe:
		bsr.w	getframe
		lea		framestore(pc),a0
		move.w	framestoreoffset-framestore(a0),d7
		move.w	d0,(a0,d7.w)
		addq	#2,d7
		move.w	d7,framestoreoffset-framestore(a0)
		rts
		
;--------------------------------------------------------------------

;returns the framestore list in a0
;destroys: a0
getstoredframes:
		lea		framestore(pc),a0
		rts
		
;--------------------------------------------------------------------
;clears all sprites in the given copperlist
;a0 - pointer to a setspriteblock for 8 sprites inside a copperlist (dc.l $01200000,...,$013e0000)
;destroys: d0-d7/a0-a1
clearsprites:	
		lea		fw_spritetab(pc),a1
		;bra.b	setsprites
		
;--------------------------------------------------------------------
;sets all sprites in the given copperlist
;a0 - pointer to a setspriteblock for 8 sprites inside a copperlist (dc.l $01200000,...,$013e0000)
;a1 - pointer to pointerlist of 8 sprites
;destroys: d0-d7/a0-a1
setsprites:	
		addq.l	#2,a0
		movem.l	(a1),d0-d7
		move.w	d0,$04(a0)
		swap	d0
		move.w	d0,(a0)
		move.w	d1,$0c(a0)
		swap	d1
		move.w	d1,$08(a0)
		move.w	d2,$14(a0)
		swap	d2
		move.w	d2,$10(a0)
		move.w	d3,$1c(a0)
		swap	d3
		move.w	d3,$18(a0)
		move.w	d4,$24(a0)
		swap	d4
		move.w	d4,$20(a0)
		move.w	d5,$2c(a0)
		swap	d5
		move.w	d5,$28(a0)
		move.w	d6,$34(a0)
		swap	d6
		move.w	d6,$30(a0)
		move.w	d7,$3c(a0)
		swap	d7
		move.w	d7,$38(a0)
		rts  				
		
;--------------------------------------------------------------------
;starts the music playback with the given module
;a0 - pointer to the p61a module
startmusic:		
		lea		fw_start(pc),a5
		move.l	a0,fw_musicpoi-fw_start(a5)
		move.w	#1,music_enabled-fw_start(a5)
		move.w	#MUSIC_START_DELAY,fw_musictime-fw_start(a5)
		rts
;		bra.w	musicinit
		
;--------------------------------------------------------------------
;stops the music playback
stopmusic:
		lea		music_enabled(pc),a5
		clr.w	(a5)
		bra.w 	musicstop
		
;--------------------------------------------------------------------
;initializes the memory stacks for chip- and fast-mem
;destroys: d0-d1/a6
initmem:
		lea		fw_start(pc),a5

		lea		memstates_fast(pc),a6
		move.l	a6,memstate_fast-fw_start(a5)
		move.l	fast_stack(pc),d0
		move.l	fast_stackend(pc),d1
		move.l	d0,MEMSTATE_START(a6)
		move.l	d1,MEMSTATE_END(a6)
		move.l	d0,MEMSTATE_POINTERBOTTOM(a6)
		move.l	d1,MEMSTATE_POINTERTOP(a6)
		
		lea		memstates_chip(pc),a6
		move.l	a6,memstate_chip-fw_start(a5)
		move.l	chip_stack(pc),d0
		move.l	chip_stackend(pc),d1
		move.l	d0,MEMSTATE_START(a6)
		move.l	d1,MEMSTATE_END(a6)
		move.l	d0,MEMSTATE_POINTERBOTTOM(a6)
		move.l	d1,MEMSTATE_POINTERTOP(a6)
		
		move.w	#MEMMODE_UP,memstate_mode-fw_start(a5)
		rts
		
;--------------------------------------------------------------------
;switches the memory allocation strategy (top->down or bottom->up)
switchmemmode:
		lea		fw_start(pc),a5

		eori.w	#1,memstate_mode-fw_start(a5)
		rts

;--------------------------------------------------------------------
;pushes the actual memstate to the memstate stack and switches to the next free
;destroys: a5-a6
pushmemstate:
		lea		fw_start(pc),a4

		move.l	memstate_fast(pc),a6
		bsr.w	pushmemstatehelper
		move.l	a5,memstate_fast-fw_start(a4)
		
		move.l	memstate_chip(pc),a6
		bsr.w	pushmemstatehelper
		move.l	a5,memstate_chip-fw_start(a4)
		rts
		
;--------------------------------------------------------------------
;pops the last pushed memstate from the memstate stack and reuses it
;destroys: a6
popmemstate:
		lea		fw_start(pc),a4
	
		move.l	memstate_fast(pc),a6
		bsr.w	popmemstatehelper
		move.l	a6,memstate_fast-fw_start(a4)
		
		move.l	memstate_chip(pc),a6
		bsr.w	popmemstatehelper
		move.l	a6,memstate_chip-fw_start(a4)
		rts

;--------------------------------------------------------------------

		cnop	0,2
alloccnt:
		dc.w	0

;allocates the given amount of chipmem
;d0.l - size in bytes
;returns allocated pointer in a0			
;destroys: d0/a0-a1/a6
alloc_chip:
		;bsr.w	debugalloc
		
		move.l	memstate_chip(pc),a6
		bsr.w	allochelper
		cmp.l	#0,a0
		bne.b	.noerror
.error:
		move.l	d0,d1
		move.l	memstate_chip(pc),a5
		move.l	memstate_fast(pc),a6
		move.w	#ERROR_OUTOFMEMORY,d0
		bra.w	error
.noerror:
		rts
		
;--------------------------------------------------------------------
;allocates the given amount of fastmem. if theres not enough fast-mem, it falls back and returns chip-mem instead
;d0.l - size in bytes
;returns allocated pointer in a0				
;destroys: d0/a0-a1/a6
alloc_fast:
		;bsr.w	debugalloc
		
		move.l	memstate_fast(pc),a6
		bsr.w	allochelper
		cmp.l	#0,a0
		bne.b	.noerror
		bra.b	alloc_chip
.noerror:
		rts
		
debugalloc:
		movem.l	a4/d5,-(sp)
		lea		fw_start(pc),a4
		addq.w	#1,alloccnt-fw_start(a4)
		
		move.w	alloccnt(pc),d5
		cmpi.w	#76,d5
		beq.b	.error
		movem.l	(sp)+,a4/d5
		rts
.error:
		move.l	d0,d1
		move.l	memstate_chip(pc),a5
		move.l	memstate_fast(pc),a6
		move.w	#ERROR_OUTOFMEMORY,d0
		bra.w	error
		
;--------------------------------------------------------------------
;frees all allocated memory
;destroys: a6
freeall:
		bsr.w	freeall_chip
		bra.w	freeall_fast		
		
;--------------------------------------------------------------------
;waits for a disk-change. and then re-initializes the loader and reads the new directory
;destroys: d0-d7/a0-a6
nextdisk:		
		bsr.w	LoaderWaitDiskChange
		;bra.b	initloader
		
;--------------------------------------------------------------------
;initializes the trackloader and reads the disk directory
;destroys: d0-d7/a0-a6
initloader:		
		move.w	#255,d0				;Retries, 0-255
		bsr.w	LoaderInit			;Setup loader.
		
		moveq	#2,d0
		moveq	#1,d1
		lea		dirtrack(pc),a0
		lea		fw_start(pc),a4
		move.l	a0,dirpointer-fw_start(a4)
		bsr.w	trackload
		;bra.b	skipnextfile

;--------------------------------------------------------------------
;skips the next file from the trackmo disk
;destroys: a4
skipnextfile:		
		lea		fw_start(pc),a4
		addq.l	#8,dirpointer-fw_start(a4)
		rts

;--------------------------------------------------------------------
;allocates sufficient memory and loads the next file from the directory into this memory
;returns the loaded file in a5 and the eof-pointer in a4
;destroys: d0-d7/a0-a6
loadnextfile:		
		lea		dirtrackend(pc),a5
		move.l	dirpointer(pc),a6
		cmp.l	a5,a6
		bne.b	.noerror
		move.w	#ERROR_DISK,d0
		bra.w	error
.noerror:
		lea		fw_start(pc),a4

		move.l	(a6)+,d2		;start offset
		move.w	d2,d0
		andi.w	#$1fc,d0		;offset into first loaded sector for later correction of pointer
		move.w	d0,-(sp)
		lsr.l	#8,d2
		lsr.l	#1,d2			;start sector
		move.l	(a6)+,d3		;num sectors
		move.l	a6,dirpointer-fw_start(a4)
		
		move.l	d3,d0
		lsl.l	#8,d0
		add.l	d0,d0			;buffersize=numsectors*512
		move.l	d0,-(sp)
		bsr.w	alloc_fast
		;bsr.w	alloctmp_fast
		move.l	a0,-(sp)
		
		move.l	d2,d0
		move.l	d3,d1

		bsr.w	trackload
		
		move.l	(sp)+,a5
		move.l	(sp)+,d1
		move.w	(sp)+,d0
		adda.w	d0,a5
		lea		(a5,d1.l),a4	;eof pointer
		rts
		
;--------------------------------------------------------------------
;loads the next file from the directory into the given buffer
;buffer must be 512 bytes bigger than the filesize for sector padding reasons
;a0 - the buffer to load into
;returns the corrected pointer in a5
;destroys: d0-d7/a0-a6
loadnextfiletobuffer:
		move.l	dirpointer(pc),a6
		cmp.l	#dirtrackend,a6
		bne.b	.noerror
		move.w	#ERROR_DISK,d0
		bra.w	error
.noerror:
		lea		fw_start(pc),a4

		move.l	(a6)+,d2		;start offset
		move.w	d2,d0
		andi.w	#$1fc,d0		;offset into first loaded sector for later correction of pointer
		move.w	d0,-(sp)
		lsr.l	#8,d2
		lsr.l	#1,d2			;start sector
		move.l	(a6)+,d3		;num sectors
		move.l	a6,dirpointer-fw_start(a4)
		
		move.l	a0,-(sp)
		
		move.l	d2,d0
		move.l	d3,d1

		bsr.w	trackload
		
		move.l	(sp)+,a5
		move.w	(sp)+,d0
		adda.w	d0,a5
		rts

;--------------------------------------------------------------------
;shuts the trackloader down
;destroys: d0-d7/a0-a6
exitloader:		
		bra.w	LoaderExit				;Restore hardware registers.
		
;--------------------------------------------------------------------
;	private framework
;--------------------------------------------------------------------

		cnop	0,4
fw_musicpoi:
		dc.l	0
fw_musictime:
		dc.w	-1

fw_irq:		
		movem.l	d0-d7/a0-a6,-(sp)

		move.w	fw_musictime(pc),d0
		bmi.b	.skipinit
		lea		fw_musictime(pc),a6
		subq	#1,d0
		move.w	d0,(a6)
		bpl.b	.skipinit
		
		move.l	fw_musicpoi-fw_musictime(a6),a0
		bsr.w	musicinit
.skipinit:
		
		bsr.w	musicproxy
     
		lea		$dff09c,a6
		moveq	#$10,d0
		move.w	d0,(a6)
		move.w	d0,(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6
		nop
		rte  
		
;--------------------------------------------------------------------
;reads, allocates, decrunches and relocates all hunks from the given exe-stream 
;a5 - packed executable stream
;returns the launch address on a0
;destroys: d0-d7/a0-a6
decrunchpart:
		lea		fw_start(pc),a6

		move.l	a4,eof_pointer-fw_start(a6)
		
		; parse hunk header
		move.l	(a5)+,d0		;hunk id
		cmpi.l	#HUNK_HEADER,d0
		beq.b	.header_id_ok
		move.w	#ERROR_HUNKBROKEN,d0
		bra.w	error
.header_id_ok:
.readlibs:
		move.l	(a5)+,d0		;strlen
		beq.b	.endofheader
		adda.l	d0,a5			;skip string data
		bra.b	.readlibs
.endofheader:
		movem.l	(a5)+,d0-d2		
		
		move.l	d0,hunk_tablesize-fw_start(a6)
		move.l	d1,first_hunk-fw_start(a6)
		move.l	d2,last_hunk-fw_start(a6)

		move.l	d2,d3
		sub.l	d1,d3
		addq	#1,d3
		cmpi.l	#MAX_HUNKS,d3
		blt.b	.nooutofhunks
		move.w	#ERROR_TOOMANYHUNKS,d0
		bra.w	error
.nooutofhunks:
		
		lea		hunk_sizes(pc),a4
		move.l	d1,d4
		lsl.l	#2,d4
		adda.l	d4,a4
.readhunksizeloop:		
		move.l	(a5)+,(a4)+
		addq.l	#1,d1
		cmp.l	d1,d2
		bge.b	.readhunksizeloop
		
		clr.w	num_relocations-fw_start(a6)
		lea		hunk_sizes(pc),a4
		lea		hunk_pointers(pc),a3
		lea		relocation_data(pc),a2
		moveq	#0,d7			;hunk_count
		
.readhunkloop:		
		move.l	last_hunk(pc),d6
		addq	#2,d6
		cmp.l	d6,d7
		beq.b	.hunksend
		
		cmp.l	eof_pointer-fw_start(a6),a5
;		bge.b	.hunksend
		
		move.l	(a5)+,d0		;hunk_id
		;beq.b	.hunksend

		cmpi.l	#HUNK_CODE,d0
		bne.b	.nocodehunk
		bsr.w	readhunkcodedata
		move.l	a0,(a3)+
		addq	#1,d7
.nocodehunk:

		cmpi.l	#HUNK_DATA,d0
		bne.b	.nodatahunk
		bsr.w	readhunkcodedata
		move.l	a0,(a3)+
		addq	#1,d7
.nodatahunk:

		cmpi.l	#HUNK_BSS,d0
		bne.b	.nobsshunk
		bsr.w	readhunkbss
		move.l	a0,(a3)+
		addq	#1,d7
.nobsshunk:
		cmpi.l	#HUNK_RELOC32,d0
		bne.b	.norelochunk
		bsr.w	readhunkreloc
		addq	#1,d7
.norelochunk:

		bra.b	.readhunkloop

.hunksend:
		lea		hunk_pointers(pc),a3
		lea		relocation_data(pc),a2
		subq.w	#1,num_relocations-fw_start(a6)
		bmi.b	.endrelocation
		
.relocationloop:	
		bsr.w	parserelocation
		subq	#1,num_relocations-fw_start(a6)
		bpl.b	.relocationloop
.endrelocation:

		lea		hunk_pointers(pc),a0
		move.l	(a0),a0
		rts

		cnop	0,4
eof_pointer:
		dc.l	0	;the eof pointer of the file to decrunch
hunk_tablesize:
		dc.l	0	;amount of hunks in the stream
first_hunk:
		dc.l	0	;first hunk in the stream
last_hunk:
		dc.l	0	;last hunk in the stream
num_relocations:
		dc.w	0	;amount of found relocation hunks

;--------------------------------------------------------------------
;reads a code or data hunk from the stream, allocates and decrunch-fills its memory with packed data from the stream
;a5 - pointer to exe-stream
;a4 - hunk-sizes array
;returns the allocated buffer on a0
;detroys: d1-d7/a0-a6
readhunkcodedata:
		movem.l	d0/a6,-(sp)
		
		move.l	(a5)+,d1		;hunk size in longwords
		move.l	d1,d0
		lsl.l	#2,d0			;allocation size
		
		move.w	d7,d6
		subq	#1,d6
		lsl.w	#2,d6
		move.l	(a4,d6.w),d6	;hunk_size (upper 2 bits are memtype)
		rol.l	#2,d6
		andi.w	#$03,d6
		bsr.w	ischipmem
		bne.b	.nochipmem
		bsr.w	alloc_chip
		bra.b	.memend
.nochipmem:
		bsr.w	alloc_fast
.memend:		
		
		movem.l	d0-d7/a0/a2-a4,-(sp)
	
		move.l	a0,a1
		move.l	a5,a0
		bsr.w	doynaxdepack
		move.l	a0,d0
		addq	#3,d0
		andi.l	#$fffffffc,d0	;align input stream to next cnop 0,4 (otherwise compression can cause misalignment)
		move.l	d0,a5

		movem.l	(sp)+,d0-d7/a0/a2-a4

		movem.l	(sp)+,d0/a6
		rts
		
;--------------------------------------------------------------------
;reads a bss hunk from the stream, allocates and zeroes its memory
;a5 - pointer to exe-stream
;a4 - hunk-sizes array
;returns the allocated buffer on a0
;detroys: d1/d6-d7/a0-a1/a5-a6
readhunkbss:
		movem.l	d0/a6,-(sp)

		move.l	(a5)+,d1		;hunk size in longwords
		move.l	d1,d0
		lsl.l	#2,d0			;allocation size
		move.w	d7,d6
		subq	#1,d6
		lsl.w	#2,d6
		move.l	(a4,d6.w),d6	;hunk_size (upper 2 bits are memtype)
		rol.l	#2,d6
		andi.w	#$03,d6
		bsr.w	ischipmem
		bne.b	.nochipmem
		bsr.w	alloc_chip
		bra.b	.memend
.nochipmem:
		bsr.w	alloc_fast
.memend:		
	
		move.l	a0,a1			;copy pointer for clearloop

		subq	#1,d1
.l0:		
		clr.l	(a1)+
		dbra	d1,.l0
					
		movem.l	(sp)+,d0/a6
		rts
		
;--------------------------------------------------------------------
;reads, stores, and skips a relocation hunk
;the hunk gets read and skipped from the stream and will be stored in the relocation structure array.
;the relocation will be parsed and applied later, when all hunks are loaded to memory.
;a2 - relocation structure array (the hunk will be stored here)
;a5 - pointer to exe-stream
;d7 - last loaded hunk_id
;destroys: d1-d2/d7/a0/a2/a5
readhunkreloc:
		movem.l	d0/a6,-(sp)

		move.l	a5,(a2)+	;store relocation pointer
		move.l	d7,(a2)+	;store relocation hunk_id
		lea		fw_start(pc),a6
		addq.w	#1,num_relocations-fw_start(a6)
.loop:
		move.l	(a5)+,d0	;numoffsets
		move.l	(a5)+,d1	;target-hunk
		tst.l	d0
		beq.b	.end

		move.l	d0,d2
		add.l	d2,d2
		adda.l	d2,a5		;skip offsets

		bra.b	.loop

.end:
		suba.l	a0,a0
		
		move.l	a5,d0
		addq	#3,d0
		andi.l	#$fffffffc,d0	;align input stream to next cnop 0,4 (otherwise compression can cause misalignment)
		move.l	d0,a5
		
		movem.l	(sp)+,d0/a6
		rts
		
;--------------------------------------------------------------------
;parses and applies a relocation hunk
;a2 - relocation hunk structure (pointer to stream and target-hunk_id)
;a3 - pointerarray to all hunks
;destroys: d0-d1/d4/a1/a5
parserelocation:
		move.l	(a2)+,a5		;reloc-hunk
		move.l	(a2)+,d1		;target_hunk_id
		subq	#1,d1
		lsl.w	#2,d1
		move.l	(a3,d1.w),a1	;target_hunk
.l1:	
		move.l	(a5)+,d0		;numoffsets
		move.l	(a5)+,d1		;source-hunk_id
		
		subq	#1,d0
		bmi.b	.end

		lsl.w	#2,d1
		move.l	(a3,d1.w),d4	;source_hunk

.l0:		
		moveq	#0,d1
		move.w	(a5)+,d1		;offset
		add.l	d1,d1
		
		add.l	d4,(a1,d1.l)	;patch offset into target-hunk
		
		dbra	d0,.l0
		
		bra.b	.l1
.end:
		rts

;--------------------------------------------------------------------
;returns if the given memory type is chip-mem
;d6 - memtype
;returns true or false on equal flag
ischipmem:
		cmpi.w	#MEMTYPE_CHIP,d6
		rts
		
;--------------------------------------------------------------------

pushmemstatehelper:
		lea		MEMSTATE_SIZE(a6),a5
		move.l	MEMSTATE_POINTERBOTTOM(a6),MEMSTATE_START(a5)
		move.l	MEMSTATE_POINTERTOP(a6),MEMSTATE_END(a5)
		move.l	MEMSTATE_POINTERBOTTOM(a6),MEMSTATE_POINTERBOTTOM(a5)
		move.l	MEMSTATE_POINTERTOP(a6),MEMSTATE_POINTERTOP(a5)
		rts
		
;--------------------------------------------------------------------

popmemstatehelper:
		suba.l	#MEMSTATE_SIZE,a6
		rts
		
;--------------------------------------------------------------------

allochelper:
		lea		fw_start(pc),a0
		cmpi.w	#MEMMODE_UP,memstate_mode-fw_start(a0)
		beq.b	allocup
		cmpi.w	#MEMMODE_DOWN,memstate_mode-fw_start(a0)
		beq.b	allocdown
		move.w	#ERROR_INVALID_PARAMS,d0
		bra.w	error
	
;--------------------------------------------------------------------

allocup:
		move.l	MEMSTATE_POINTERBOTTOM(a6),a0
		addq	#3,d0
		andi.l	#$fffffffc,d0				; round up to next 'cnop 0,4' location
		lea		(a0,d0.l),a1
		cmp.l	MEMSTATE_POINTERTOP(a6),a1
		blt.w	.noerror
		suba.l	a0,a0						; return 0 to indicate error
		rts
.noerror:
		move.l	a1,MEMSTATE_POINTERBOTTOM(a6)
		rts

;--------------------------------------------------------------------

allocdown:
		move.l	MEMSTATE_POINTERTOP(a6),a0
		addq	#3,d0
		andi.l	#$fffffffc,d0				; round up to next 'cnop 0,4' location
		suba.l	d0,a0
		cmp.l	MEMSTATE_POINTERBOTTOM(a6),a0
		bgt.w	.noerror
		suba.l	a0,a0						; return 0 to indicate error
		rts
.noerror:
		move.l	a0,MEMSTATE_POINTERTOP(a6)
		rts

;--------------------------------------------------------------------

alloctmp_chip:
		move.l	memstate_chip(pc),a6
		bra.b	alloctmphelper
		
;--------------------------------------------------------------------

alloctmp_fast:
		move.l	memstate_fast(pc),a6
		;bra.b	alloctmphelper
		
;--------------------------------------------------------------------

alloctmphelper:
		lea		fw_start(pc),a0
		cmpi.w	#MEMMODE_UP,memstate_mode-fw_start(a0)
		beq.b	alloctmpup
		cmpi.w	#MEMMODE_DOWN,memstate_mode-fw_start(a0)
		beq.b	alloctmpdown
		move.w	#ERROR_INVALID_PARAMS,d0
		bra.w	error
		
;--------------------------------------------------------------------

alloctmpup:
		move.l	MEMSTATE_POINTERTOP(a6),a0
		addq	#3,d0
		andi.l	#$fffffffc,d0				; round up to next 'cnop 0,4' location
		suba.l	d0,a0
		rts
		
;--------------------------------------------------------------------

alloctmpdown:
		move.l	MEMSTATE_POINTERBOTTOM(a6),a0
		rts
		
;--------------------------------------------------------------------
;frees all allocated chip-mem
;destroys: a6
freeall_chip:
		move.l	memstate_chip(pc),a6
		bra.w	freeallhelper
		
;--------------------------------------------------------------------
;frees all allocated fast-mem
;destroys: a6
freeall_fast:
		move.l	memstate_fast(pc),a6
		bra.w	freeallhelper
		
;--------------------------------------------------------------------

freeallhelper:
		lea		memstate_mode(pc),a0
		cmpi.w	#MEMMODE_UP,(a0)
		beq.b	freeallup
		cmpi.w	#MEMMODE_DOWN,(a0)
		beq.b	freealldown
		move.w	#ERROR_INVALID_PARAMS,d0
		bra.w	error

;--------------------------------------------------------------------

freeallup:
		move.l	MEMSTATE_START(a6),MEMSTATE_POINTERBOTTOM(a6)
		rts
		
;--------------------------------------------------------------------

freealldown:
		move.l	MEMSTATE_END(a6),MEMSTATE_POINTERTOP(a6)
		rts
		
;--------------------------------------------------------------------
;d0 - starting blocknumber
;d1 - number of blocks to read
;a0	- buffer to read into
;destroys: d0-d7/a0-a6
trackload:
		moveq	#0,d2				;Drive 0, 0-3
		bsr.w	LoaderLoad
		tst.l	d0
		beq.w	.noerror
		move.w	#ERROR_DISK,d0
		bra.w	error
.noerror:	
		rts		
		
;--------------------------------------------------------------------
;endlessly loops and increases the background color to indicate an error
;d0.w - errorcode
error:
.l0:
		move.w	d0,$dff180
		bra.b	.l0
		
;--------------------------------------------------------------------

		cnop	0,4
		;jump table for all public functions of the framework
fw_jmptable:
		bra.w	setbasecopper
		bra.w	setcopper
		bra.w	bltwait
		bra.w	vsync
		bra.w	musicproxy
		bra.w	waitforframe
		bra.w	isframeover
		bra.w	waitxframes
		bra.w	getframe
		bra.w	clearsprites		
		bra.w	setsprites		
		bra.w	startmusic
		bra.w	stopmusic
		bra.w	switchmemmode
		bra.w	pushmemstate
		bra.w	popmemstate
		bra.w	alloc_chip
		bra.w	alloc_fast
		bra.w	freeall
		bra.w	initloader
		bra.w	loadnextfile
		bra.w	loadnextfiletobuffer
		bra.w	exitloader
		bra.w	nextdisk
		bra.w	skipnextfile
		bra.w	storeframe
		bra.w	getstoredframes
		
;----------------------------------------------------------------------------

		cnop	0,4
memstate_fast:
		dc.l	0
memstate_chip:
		dc.l	0
memstate_mode:
		dc.w	MEMMODE_UP
music_enabled:		
		dc.w	0
		
		cnop	0,4
memstates_fast:
		ds.b	MEMSTATE_SIZE*MAX_MEMSTATES		;stack of memory states for fast-mem		
memstates_chip:
		ds.b	MEMSTATE_SIZE*MAX_MEMSTATES		;stack of memory states for chip-mem		
		
		cnop	0,4
hunk_sizes:
		ds.l	MAX_HUNKS		;sizes of all hunks in the executable in longwords
hunk_pointers:
		ds.l	MAX_HUNKS		;pointers to all hunks in the executable
relocation_data:
		ds.l	MAX_HUNKS*2		;array of structure for relocation hunks (pointer and target-hunk_id)

		cnop	0,4
dirtrack:
		ds.l	128				;interleaved longs with starting sectorid and sectorcount for max 64 files
dirtrackend:
dirpointer:
		dc.l	0
		
ldr_TrackBuffer:
		dc.l	0
fast_stack:
		dc.l	0
fast_stackend:
		dc.l	0
chip_stack:
		dc.l	0
chip_stackend:
		dc.l	0
fw_copperlist:
		dc.l	0
fw_coppersprites:
		dc.l	0
		
;--------------------------------------------------------------------
	
		include "../soundplayer/soundplayer.asm"
		include "../framework/depacker_doynax.asm"
		include "../framework/loader.asm"
		
;********************************************************************

				cnop	0,2
mfw_copperlist:	dc.l	$008e2c81,$00902cc1,$00920038,$009400d0	;window start, window stop, bitplane start, bitplane stop
				dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem

mfw_coppersprites:
				dc.l	$01200000,$01220000,$01240000,$01260000 ;8 sprite pointers
				dc.l	$01280000,$012a0000,$012c0000,$012e0000
				dc.l	$01300000,$01320000,$01340000,$01360000
				dc.l	$01380000,$013a0000,$013c0000,$013e0000

				dc.l	$01000200,$01020000,$01040000			;bplcon mode, scroll values, bplcon prios
				dc.l	$01080000,$010a0000						;modulo odd planes, modulo even planes

				dc.l	$210ffffe,$009c8010						;wait x: 15, y: 33, start irq

				dc.l	$fffffffe 								;wait for end
mfw_copperlistend:

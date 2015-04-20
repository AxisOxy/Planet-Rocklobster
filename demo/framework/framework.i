;--------------------------------------------------------------------
;sets the base copperlist and irq (empty screen with musicplayer)
;destroys: a0-a1
SETBASECOPPER	=  0

;--------------------------------------------------------------------
;sets a new copperlist and irq
;a0 - the new copperlist
;a1 - the new irq
SETCOPPER		=  4

;--------------------------------------------------------------------
;waits until the blitter is finished
BLTWAIT			=  8

;--------------------------------------------------------------------
;waits for the next vertical blank
VSYNC			= 12

;--------------------------------------------------------------------
;this function must be called by every part in the vbl-/copper-irq
;increases the global framecounter (for timing purposes) and calls the musicplayer
;destroys: d0-d7/a0-a6
MUSICPROXY		= 16

;--------------------------------------------------------------------
;waits until the global framecounter reaches the given frame
;d0.w - frame to wait for
WAITFORFRAME	= 20

;--------------------------------------------------------------------
;returns if the global framecounter reached the given frame
;d0.w - frame to check against
;signflag - positive if not reached, else negative
ISFRAMEOVER		= 24

;--------------------------------------------------------------------
;waits the given amount of vsyncs
;d0.w - the amount of vsyncs to wait
WAITXFRAMES		= 28

;--------------------------------------------------------------------
;returns the actual global framecounter in d0.w
GETFRAME		= 32

;--------------------------------------------------------------------
;clears all sprites in the given copperlist
;a0 - pointer to a setspriteblock for 8 sprites inside a copperlist (dc.l $01200000,...,$013e0000)
;destroys: d0-d7/a0-a1
CLEARSPRITES	= 36

;--------------------------------------------------------------------
;sets all sprites in the given copperlist
;a0 - pointer to a setspriteblock for 8 sprites inside a copperlist (dc.l $01200000,...,$013e0000)
;a1 - pointer to pointerlist of 8 sprites
;destroys: d0-d7/a0-a1
SETSPRITES	= 40

;--------------------------------------------------------------------
;starts the music playback with the given module
;a0 - pointer to the p61a module
STARTMUSIC		= 44

;--------------------------------------------------------------------
;stops the music playback
STOPMUSIC		= 48

;--------------------------------------------------------------------
;switches the memory allocation strategy (top->down or bottom->up)
SWITCHMEMMODE	= 52

;--------------------------------------------------------------------
;pushes the actual memstate to the memstate stack and switches to the next free
;destroys: a5-a6
PUSHMEMSTATE	= 56

;--------------------------------------------------------------------
;pops the last pushed memstate from the memstate stack and reuses it
;destroys: a6
POPMEMSTATE		= 60

;--------------------------------------------------------------------
;allocates the given amount of chipmem
;d0.l - size in bytes
;returns allocated pointer in a0			
;destroys: d0/a0-a1/a6
ALLOC_CHIP		= 64

;--------------------------------------------------------------------
;allocates the given amount of fastmem. if theres not enough fast-mem, it falls back and returns chip-mem instead
;d0.l - size in bytes
;returns allocated pointer in a0				
;destroys: d0/a0-a1/a6
ALLOC_FAST		= 68

;--------------------------------------------------------------------
;frees all allocated memory
;destroys: a6
FREEALL			= 72

;--------------------------------------------------------------------
;initializes the trackloader and reads the disk directory
;destroys: d0-d7/a0-a6
INITLOADER		= 76

;--------------------------------------------------------------------
;allocates sufficient memory and loads the next file from the directory into this memory
;returns the loaded file in a5
;destroys: d0-d7/a0-a6
LOADNEXTFILE	= 80

;loads the next file from the directory into the given buffer
;buffer must be 512 bytes bigger than the filesize for sector padding reasons
;a0 - the buffer to load into
;returns the corrected pointer in a5
;destroys: d0-d7/a0-a6
LOADNEXTFILETOBUFFER = 84

;--------------------------------------------------------------------
;shuts the trackloader down
;destroys: d0-d7/a0-a6
EXITLOADER		= 88

;--------------------------------------------------------------------
;waits for a disk-change. and then re-initializes the loader and reads the new directory
;destroys: d0-d7/a0-a6
NEXTDISK		= 92

;--------------------------------------------------------------------
;skips the next file from the trackmo disk
;destroys: a4
SKIPNEXTFILE	= 96

;--------------------------------------------------------------------
;stores the actual frame to the framestore list
;destroys: d0/d7/a0
STOREFRAME	    = 100

;--------------------------------------------------------------------
;returns the framestore list in a0
;destroys: a0
GETSTOREDFRAMES	= 104

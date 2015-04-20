_DEMOSTARTUP	= 1

;initializes the whole trackmo system
;destroys: d0-d7/a0-a6
init:				
		bsr.w	appinit
		clr.w	$dff180
		bra.w	initloader
					
;--------------------------------------------------------------------

;shuts the trackmo system down
;destroys: d0-d7/a0-a6
shutdown:				
		bsr.w	exitloader
		bra.w	appshutdown
		
;--------------------------------------------------------------------
				
		cnop	0,4
musicdata:
		dc.l	0

;loads, depacks and starts the given music
;a0 - the buffer to load the music into
;destroys: d0-d7/a0-a6
loadmusic:
		move.l	a0,-(sp)
		bsr.w	loadnextfile
		move.l	a5,a0
		move.l	(sp)+,a1
		lea		fw_start,a4
		move.l	a1,musicdata-fw_start(a4)

		bsr.w	doynaxdepack
		
		bsr.w	checkshutdownalt
		
		move.l	musicdata(pc),a0
		bra.w	startmusic
		rts
	
;--------------------------------------------------------------------
;stops the actual playing music and frees its memory
;destroys: d0-d7/a0-a6
freemusic:
		bsr.w	stopmusic
		lea		fw_start,a4
		clr.l	musicdata-fw_start(a4)
		bsr.w	popmemstate
		bra.w	freeall
		
;--------------------------------------------------------------------
;loads, allocates, depacks and relocates all hunks from the next file
;executes the first hunk of the exe
;destroys: d0-d7/a0-a6
executenextpart:
		bsr.w	freeall
		bsr.w	loadnextfile
		bsr.w	decrunchpart
		
		bsr.w	checkshutdownalt
		
		lea		fw_jmptable(pc),a6
		jmp 	(a0)

;--------------------------------------------------------------------
;checks, if a alterante part shutdownhook is installed.
;if yes, it runs the hook and removes it, else nothing happens.
;destroys: d0-d7/a0-a6
checkshutdownalt:
		lea		shutdownhook,a5
		tst.l	(a5)
		beq.b	.skipshutdown
		move.l	a0,-(sp)
		move.l	(a5),a0
		jsr		2(a0)
		clr.l	(a5)

		;bsr.w	freealt

		move.l	(sp)+,a0
.skipshutdown:
		rts
		
;--------------------------------------------------------------------
;loads, allocates, depacks and relocates all hunks from the next file to alternative memory
;executes the first hunk of the exe
;this function can be used for background loading
;there can always be 1 normal part and 1 alternative part in memory at the same time as long as both parts fit together into the memory
;destroys: d0-d7/a0-a6
executenextpartalt:
		bsr.w	switchmemmode
		bsr.w	freeall
		bsr.w	loadnextfile
		bsr.w	decrunchpart
		lea		fw_jmptable(pc),a6
		lea		shutdownhook(pc),a5
		move.l	a0,(a5)
		jsr 	(a0)
		bra.w	switchmemmode

;--------------------------------------------------------------------
;frees alternative memory
;destroys: d0-d7/a0-a6
freealt:
		bsr.w	switchmemmode
		bsr.w	freeall
		bra.w	switchmemmode
				
shutdownhook:
		dc.l	0
		
		include "../framework/framework.asm"
		
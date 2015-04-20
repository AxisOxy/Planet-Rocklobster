;--------------------------------------------------------------------
;	system lib vector offsets
;--------------------------------------------------------------------

		include "lvo/lvo.i" 
		include "exec/libraries.i" 
		
_LVOCacheControl	= -648

;--------------------------------------------------------------------
;	startup code
;--------------------------------------------------------------------

appinit:
		lea		fw_start(pc),a5

		move.l	(a0)+,a1	;pointer to chipmem structure
		move.l	4(a1),a2
		move.l	a2,chip_stack-fw_start(a5)
		add.l	(a1),a2
		move.l	a2,chip_stackend-fw_start(a5)
		move.l	(a0)+,a1	;pointer to fastmem structure
		move.l	4(a1),a2
		move.l	a2,fast_stack-fw_start(a5)
		add.l	(a1),a2
		move.l	a2,fast_stackend-fw_start(a5)
				
		lea		chip_stack(pc),a0
		move.l	4(a0),d0
		sub.l	(a0),d0
		cmpi.l	#490000,d0	; if we have less than 490 kb chipmem, the disk symbol was shown before starting the demo (we loose 24 kb)
							; reset the machine!
		bgt.b	.nores
		bsr.w	Reset
.nores:
		
		bsr.w	bltwait
		move.w	#$7fff,$dff09a
		move.w	#$7fff,$dff09c
		move.w	#$7fff,$dff096
		move.w	#$7fff,$dff09e
		
		movem.l	fw_regclear(pc),d0-d7/a0-a6

		bsr.w	initmem
		
		move.l	4.w,a6

		cmp.w   #V37_EXEC,LIB_VERSION(a6)
		blt.s   .skipdisablecache
		
		moveq	#0,d0
		moveq	#-1,d1
		jsr		_LVOCacheControl(a6)
.skipdisablecache:

		lea		fw_start(pc),a5
		
		move.l 	#MFMBUFSIZE,d0
		bsr.w	alloc_chip
		move.l	a0,ldr_TrackBuffer-fw_start(a5)
		
		move.l 	#mfw_copperlistend-mfw_copperlist,d0
		bsr.w	alloc_chip
		move.l	a0,d0
		move.l	d0,fw_copperlist-fw_start(a5)
		move.l	d0,a1
		addi.l	#mfw_coppersprites-mfw_copperlist,d0
		move.l	d0,fw_coppersprites-fw_start(a5)

		lea		mfw_copperlist(pc),a0

		move.w	#(mfw_copperlistend-mfw_copperlist)/2-1,d7
.l0:	
		move.w	(a0)+,(a1)+		
		dbra	d7,.l0

		bsr.w	pushmemstate
		
		clr.w	fw_framecounter-fw_start(a5)

		move.l	fw_coppersprites(pc),a0
		bsr.w	clearsprites
		
		bsr.w	setbasecopper
		rts  
		
;--------------------------------------------------------------------
	
appshutdown:
		bra.b	appshutdown

;--------------------------------------------------------------------
	
MAGIC_ROMEND        EQU $01000000   ;End of Kickstart ROM
MAGIC_SIZEOFFSET    EQU -$14        ;Offset from end of ROM to Kickstart size
V36_EXEC            EQU 36          ;Exec with the ColdReboot() function
V37_EXEC            EQU 37          ;Exec with the CacheControl() function
TEMP_ColdReboot     EQU -726        ;Offset of the V36 ColdReboot function

Reset: 	move.l	4.w,a6
		cmp.w   #V36_EXEC,LIB_VERSION(a6)
		blt.s   old_exec
		jmp     TEMP_ColdReboot(a6)     ;Let Exec do it...
		;NOTE: Control flow never returns to here

;---- manually reset the Amiga ---------------------------------------------
old_exec:
		lea.l   GoAway(pc),a5           ;address of code to execute
        jsr     _LVOSupervisor(a6)      ;trap to code at (a5)...
        ;NOTE: Control flow never returns to here

;-------------- MagicResetCode ---------DO NOT CHANGE-----------------------
        CNOP    0,4                     ;IMPORTANT! Longword align!
GoAway: lea.l   MAGIC_ROMEND,a0         ;(end of ROM)
        sub.l   MAGIC_SIZEOFFSET(a0),a0 ;(end of ROM)-(ROM size)=PC
        move.l  4(a0),a0                ;Get Initial Program Counter
        subq.l  #2,a0                   ;now points to second RESET
        reset                           ;first RESET instruction
        jmp     (a0)                    ;CPU Prefetch executes this
        ;NOTE: the RESET and JMP instructions must share a longword!
;---------------------------------------DO NOT CHANGE-----------------------

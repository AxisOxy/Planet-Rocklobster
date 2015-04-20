;--------------------------------------------------------------------
;	system lib vector offsets
;--------------------------------------------------------------------

_LVOForbid			= -132
_LVOPermit			= -138
_LVODisable			= -$78
_LVOEnable  		= -126
_LVOAllocMem		= -198

;--------------------------------------------------------------------
;	startup code
;--------------------------------------------------------------------

appinit:		
		movem.l	d0-d7/a0-a6,fw_oldregs

		move.l	4.w,a6
		
		move.l 	#CHIPMEM_SIZE,d0
		moveq  	#_MemChip,d1
		jsr    	_LVOAllocMem(a6)
		bne.b	.noerror1
		move.w	#ERROR_OUTOFMEMORY,d0
		bra.w	error
.noerror1:
		move.l	d0,chip_stack
		addi.l	#CHIPMEM_SIZE,d0
		move.l	d0,chip_stackend
		
		move.l 	#12800,d0
		moveq  	#_MemChip,d1
		jsr    	_LVOAllocMem(a6)
		bne.b	.noerror2
		move.w	#ERROR_OUTOFMEMORY,d0
		bra.w	error
.noerror2:
		move.l	d0,ldr_TrackBuffer
		
		move.l 	#FASTMEM_SIZE,d0
		moveq  	#_MemAny,d1
		jsr    	_LVOAllocMem(a6)
		bne.b	.noerror3
		move.w	#ERROR_OUTOFMEMORY,d0
		bra.w	error
.noerror3:
		move.l	d0,fast_stack
		add.l	#FASTMEM_SIZE,d0
		move.l	d0,fast_stackend
		
		move.l 	#mfw_copperlistend-mfw_copperlist,d0
		moveq  	#_MemChip,d1
		jsr    	_LVOAllocMem(a6)
		bne.b	.noerror4
		move.w	#ERROR_OUTOFMEMORY,d0
		bra.w	error
.noerror4:
		move.l	d0,fw_copperlist
		move.l	d0,a1
		addi.l	#mfw_coppersprites-mfw_copperlist,d0
		move.l	d0,fw_coppersprites

		lea		mfw_copperlist,a0
		move.w	#(mfw_copperlistend-mfw_copperlist)/2-1,d7
.l0:	
		move.w	(a0)+,(a1)+		
		dbra	d7,.l0

		jsr		_LVOForbid(a6)
		jsr		_LVODisable(a6)
		
		bsr.w	bltwait
		move.w	$dff01c,d0
		move.w	#$7fff,$dff09a
		ori.w	#$8000,d0
		move.w	$dff01e,d1
		move.w	#$7fff,$dff09c
		ori.w	#$8000,d1
		move.w	$dff002,d2
		move.w	#$7fff,$dff096
		ori.w	#$8000,d2
		move.w	$dff010,d3
		move.w	#$7fff,$dff09e
		ori.w	#$8000,d3
		movem.w	d0-d3,fw_oldcontrols
		move.l	$006c,fw_oldirq
		
		movem.l	fw_regclear,d0-d7/a0-a6

		bsr.w	initmem
		
		clr.w	fw_framecounter

		move.l	fw_coppersprites,a0
		bsr.w	clearsprites
		
		bsr.w	setbasecopper
		rts  

;--------------------------------------------------------------------

fw_oldcontrols:	blk.w	$04,$0000

fw_oldregs:		ds.l	$10
				
fw_oldirq:		dc.l	$00000000		

;--------------------------------------------------------------------
		
appshutdown:
		bsr.w	bltwait
		bsr.w	vsync
		
		move.w	#$7fff,$dff09a
		move.w	#$7fff,$dff09c
		move.w	#$7fff,$dff096
		move.w	#$7fff,$dff09e
		move.l	fw_oldirq,$006c
		movea.l	$0004,a0
		movea.l	$9c(a0),a0
		move.l	$26(a0),$dff080
		move.l	$26(a0),$dff084
		clr.w	$dff088
		clr.w	$dff08a
		movem.w	fw_oldcontrols,d0-d3
		move.w	d3,$dff09e
		move.w	d2,$dff096
		move.w	d1,$dff09c
		move.w	d0,$dff09a
		movem.l	fw_oldregs,d0-d7/a0-a6
		rts			
		
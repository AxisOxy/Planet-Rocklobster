	IFND LIBRARIES_PPBASE_I
LIBRARIES_PPBASE_I	SET	1
**
**	$Filename: libraries/ppbase.i $
**	$Release: 1.3 $
**
**	(C) Copyright 1991 Nico François
**	    All Rights Reserved
**

	IFND EXEC_LISTS_I
	include "exec/lists.i"
	ENDC

	IFND EXEC_LIBRARIES_I
	include "exec/libraries.i"
	ENDC

PPNAME	MACRO
	dc.b "powerpacker.library",0
	ENDM

PPVERSION	equ	35

	STRUCTURE PPBase,LIB_SIZE
		UBYTE pp_Flags
		UBYTE pp_pad
		ULONG pp_SegList
		LABEL PPBase_SIZE

* decrunch colors for ppLoadData and ppDecrunchBuffer
DECR_COL0		equ	 0
DECR_COL1		equ	 1
DECR_POINTER		equ	 2
DECR_SCROLL		equ	 3
DECR_NONE		equ	 4

* error codes returned by ppLoadData
PP_OPENERR		equ	-1
PP_READERR		equ	-2
PP_NOMEMORY		equ	-3
PP_CRYPTED		equ	-4
PP_PASSERR		equ	-5
PP_UNKNOWNPP		equ	-6
PP_EMPTYFILE		equ	-7

* size of speedup buffer
SPEEDUP_BUFFLARGE	equ	 0
SPEEDUP_BUFFMEDIUM	equ	 1
SPEEDUP_BUFFSMALL	equ	 2

* crunching efficiency
CRUN_FAST		equ	 0
CRUN_MEDIOCRE		equ	 1
CRUN_GOOD		equ	 2
CRUN_VERYGOOD		equ	 3
CRUN_BEST		equ	 4

* possible return values from ppCrunchBuffer
PP_CRUNCHABORTED	equ	 0
PP_BUFFEROVERFLOW	equ	-1

	ENDC	; LIBRARIES_PPBASE_I

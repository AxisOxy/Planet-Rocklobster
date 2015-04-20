
**************** $VER: xpkLibHeader.i 1.5 (27.06.1998) *******************

	NOLIST
	INCLUDE "exec/types.i"
	INCLUDE "exec/execbase.i"
	INCLUDE "exec/initializers.i"
	INCLUDE "exec/libraries.i"
	INCLUDE "exec/lists.i"
	INCLUDE "exec/alerts.i"
	INCLUDE "exec/resident.i"
	INCLUDE "dos/dos.i"
	INCLUDE	"lvo.i"		; contains all needed lvo's
	LIST

**************************************************************************

;	XDEF	InitTable
;	XDEF	Open
;	XDEF	Close
;	XDEF	Expunge
;	XDEF	Null
;	XDEF	LibName

**************************************************************************

	SECTION	"0", Code
Start	MOVEQ	#-1,d0	; return an error in case someone
	RTS		; tried to run as a program

; A romtag structure.  Both "exec" and "ramlib" look for this structure to
; discover magic constants about you (such as where to start running you
; from...).

RomTag		DC.W	RTC_MATCHWORD	; UWORD rt_MatchWord
		DC.L	RomTag		; APTR  rt_MatchTag
		DC.L	EndCode		; APTR  rt_EndSkip
		DC.B	RTF_AUTOINIT	; UBYTE rt_Flags
		DC.B	VERSION		; UBYTE rt_Version
		DC.B	NT_LIBRARY	; UBYTE rt_type
		DC.B	0		; BYTE  rt_Pri
		DC.L	LibName		; APTR  rt_Name
		DC.L	IDString	; APTR  rt_IDString
		DC.L	InitTable	; APTR  rt_Init  table for InitResident()

; The romtag specified that we were "RTF_AUTOINIT". This means that the
; rt_Init structure member points to one of these tables below. If the
; AUTOINIT bit was not set then RT_INIT would point to a routine to run.

InitTable:
	DC.L	LIB_SIZE		; size of library base data space
	DC.L	funcTable		; pointer to function initializers
	DC.L	dataTable		; pointer to data initializers
	DC.L	initRoutine		; routine to run

funcTable:
;------ standard system routines
	DC.L	Open
	DC.L	Close
	DC.L	Expunge
	DC.L	Null
;------ the library definitions
	DC.L	_XpksPackerInfo
	DC.L	_XpksPackChunk
	DC.L	_XpksPackFree
	DC.L	_XpksPackReset
	DC.L	_XpksUnpackChunk
	DC.L	_XpksUnpackFree
;------ function table end marker
	DC.L	-1

; The data table initializes static data structures. The format is specified
; in exec/InitStruct routine's manual pages. The INITBYTE/INITWORD/INITLONG
; routines are in the file "exec/initializers.i". The first argument is the
; offset from the library base for this byte/word/long. The second argument
; is the value to put in that cell. The table is null terminated.

dataTable:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,LibName
	INITBYTE	LIB_FLAGS,LIBF_SUMUSED!LIBF_CHANGED
	INITWORD	LIB_VERSION,VERSION
	INITWORD	LIB_REVISION,REVISION
	INITLONG	LIB_IDSTRING,IDString
	DC.L		0

; This routine gets called after the library has been allocated. The library
; pointer is in D0. The segment list is in A0. If it returns non-zero then
; the library will be linked into the library list.

SegList		DC.L	0
initRoutine:
;------ get the library pointer into a convenient A register
	MOVE.L	A5,-(A7)
	MOVEA.L	D0,A5
;------ save a pointer to our loaded code
	MOVE.L	A0,SegList
;
; specific openings here
;
	JSR	_xInitCode
	TST.L	D0
	BNE.B	.kill
	MOVE.L	A5,D0
.end	MOVEA.L	(A7)+,A5
	RTS
.kill	JSR	_xExitCode
	MOVEQ	#0,D0
	BRA.B	.end

; here begins the system interface commands. When the user calls
; OpenLibrary/CloseLibrary/RemoveLibrary, this eventually gets translated
; into a call to the following routines (Open/Close/Expunge). Exec has
; already put our library pointer in A6 for us. Exec has turned off task
; switching while in these routines (via Forbid/Permit), so we should not
; take too long in them.

; Open returns the library pointer in D0 if the open was successful. If the
; open failed then null is returned. It might fail if we allocated memory
; on each open, or if only one application could have the library open at
; a time...

Open:		; (libptr:A6, version:D0)
;------ mark us as having another opener
	ADDQ.W	#1,LIB_OPENCNT(A6)
	BCLR	#LIBB_DELEXP,LIB_FLAGS(A6)
	MOVE.L	A6,D0
	RTS

; There are two different things that might be returned from the Close
; routine. If the library is no longer open and there is a delayed expunge
; then Close should return the segment list (as given to Init). Otherwise
; close should return NULL.

Close:		; (libptr:A6)
;------ set the return value
	MOVEQ	#0,D0
;------ mark us as having one fewer openers
	SUBQ.W   #1,LIB_OPENCNT(A6)
;------ see if there is anyone left with us open
	BNE.B	OneLeft
;------ do the expunge
	BTST	#LIBB_DELEXP,LIB_FLAGS(a6)
	BEQ.B	DelExp
	BSR.B	Expunge
OneLeft
DelExp	RTS

; There are two different things that might be returned from the Expunge
; routine. If the library is no longer open then Expunge should return the
; segment list (as given to Init). Otherwise Expunge should set the delayed
; expunge flag and return NULL.
; One other important note: because Expunge is called from the memory
; allocator, it may NEVER Wait() or otherwise take long time to complete.

Expunge:	; (libptr: A6)
	MOVEM.L	D2/A5/A6,-(A7)
	MOVEA.L	A6,A5
	MOVEA.L	4.W,A6
;------ see if anyone has us open
	TST.W	LIB_OPENCNT(A5)
	BEQ.B	DoIt
	BSET	#LIBB_DELEXP,LIB_FLAGS(A5)
	MOVEQ	#0,D0
	BRA.B	Expunge_End
DoIt
;------ go ahead and get rid of us.  Store our seglist in D2
	MOVE.L	SegList(PC),D2
;------ unlink from library list
	MOVEA.L	A5,A1
	JSR	_LVORemove(A6)
;
; device specific closings here...
	JSR	_xExitCode
;
;------ free our memory
	MOVEQ	#0,D0
	MOVEA.L	A5,A1
	MOVE.W	LIB_NEGSIZE(A5),D0
	SUBA.L	D0,A1
	ADD.W	LIB_POSSIZE(A5),D0
	MOVEA.L	4.W,A6
	JSR	_LVOFreeMem(A6)
;------ set up our return value
	MOVE.L	D2,D0

Expunge_End:
	MOVEM.L	(A7)+,D2/A5/A6
	RTS

Null:	MOVEQ	#0,D0
EndCode	RTS

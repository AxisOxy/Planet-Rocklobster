	INCLUDE	"xpk/xpkLibHeader.i"

******************** $VER: xpkLib.i 1.8 (27.06.1998) *********************

; Here the needed variables and strings are initialized. Do not change the
; format of the IDString. Only add some additional information after the
; second brake. An additional $VER: string is not needed!

VERSION		EQU	1		; version of your library
REVISION	EQU	0		; revision of your library

LibName		DC.B	'xpk____.library',0
IDString	DC.B	'xpk____ 1.0 (11.01.1997)',13,10,0
		CNOP	0,2

**************************************************************************

; Functions _xInitCode and _xExitCode give you the ability to do things on
; opening and closing of library. These functions are called by init
; routine or by Expunge. Init is the only funtion, that is allowed to set a
; value for an global variable. The library pointer is in A5, registers
; have to be saved!!! If _xInitCode returns not zero, the init function
; fails and thus the library cannot be opened!

; The _xInitCode function can for example be used for processor type checks:
; the <flag> place holder may be any of the following values:
; CPU's: AFF_68010, AFF_68020, AFF_68030, AFF_68040
; FPU's: AFF_68881, AFF_68882
; NOTE: for better processors (e.g. AFF_68030) the lower bits are set also
; (AFF_68020 and AFF_68010), so you only need to check one value!.
; The flags for CPU and FPU can be used both with (AFF_CPU | AFF_FPU).
;
;_xInitCode
;	MOVE.L	4.W,A0
;	MOVEQ	#0,D0
;       MOVE.W  AttnFlags(A0),D0
;	ANDI.W	#<flag>,D0
;	BEQ.B	.kill
;	MOVEQ	#0,D0			; all ok, library can be opened
;	RTS
;.kill	MOVEQ	#1,D0			; check failed, cannot open
;	RTS

; Sometimes you do not need functions _XpksPackReset, _XpksPackFree or
; _XpksUnpackFree. In this case you can set these dummies here:
;
;_XpksPackFree
;_XpksPackReset
;_XpksUnpackFree

; Dummy functions, mark out them if you want to use your own ones or above
; processor check.
_xInitCode
_xExitCode
		MOVEQ	#0,D0
		RTS
; or set these two if the functions are extern
;	XREF	_xInitCode
;	XREF	_xExitCode

**************************************************************************

; ASM: in assembler language use this file as an include with directive
;	INCLUDE	xpkLib____.i

; OTHER: In any other language compile this file with an assembler and get
; an object file (called like xpkLib____.o). Link this object file together
; with your other code. This file MUST be the first one (e.g. it is the
; startup code). Set the following external references.
;
;	XREF	_XpksPackerInfo
;	XREF	_XpksPackChunk
;	XREF	_XpksPackFree
;	XREF	_XpksPackReset
;	XREF	_XpksUnpackChunk
;	XREF	_XpksUnpackFree

**************************************************************************

    IFND UTILITY_TAGITEM_I
UTILITY_TAGITEM_I SET	1
**
**	$Filename: utility/tagitem.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.3 $
**	$Date: 91/01/24 $
**
**	extended specification mechanism
**
**	(C) Copyright 1989-1991 Commodore-Amiga Inc.
**		All Rights Reserved
**

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC

; =======================================================================
; ====	TagItem	==========================================================
; =======================================================================
; This data type may propagate through the system for more general use.
; In the meantime, it is used as a general mechanism of extensible data
; arrays for parameter specification and property inquiry (coming soon
; to a display controller near you).
;
; In practice, an array (or chain of arrays) of TagItems is used.

 STRUCTURE	TagItem,0
	ULONG	ti_Tag		; identifies the type of this item
	ULONG	ti_Data		; type-specific data, can be a pointer
	LABEL	ti_SIZEOF

; ----	system tag values -----------------------------
TAG_DONE	EQU	0  ; terminates array of TagItems. ti_Data unused
TAG_IGNORE	EQU	1  ; ignore this item, not end of array
TAG_MORE	EQU	2  ; ti_Data is pointer to another array of TagItems
			   ; note that this tag terminates the current array
TAG_SKIP	EQU	3  ; skip this and the next ti_Data items

; ----	user tag identification -----------------------
TAG_USER	EQU	$80000000  ; differentiates user tags from system tags

; until further notice, tag bits 16-30 are RESERVED and should be zero.
; Also, the value (TAG_USER | 0) should never be used as a tag value.

	ENDC

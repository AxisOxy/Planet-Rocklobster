	IFND	LIBRARIES_EXPANSION_I
LIBRARIES_EXPANSION_I	SET	1
**
**	$Filename: libraries/expansion.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.6 $
**	$Date: 90/11/05 $
**
**	External definitions for expansion.library
**
**	(C) Copyright 1989-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

	IFND	EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC	;EXEC_TYPES_I



EXPANSIONNAME	MACRO
		dc.b	'expansion.library',0
		ENDM


;flag for the AddDosNode() call
	BITDEF	ADN,STARTPROC,0

	ENDC	;LIBRARIES_EXPANSION_I

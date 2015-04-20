	IFND	RESOURCES_POTGO_I
RESOURCES_POTGO_I	EQU	1
**
**	$Filename: resources/potgo.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.0 $
**	$Date: 90/04/13 $
**
**	potgo resource name
**
**	(C) Copyright 1986-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**
POTGONAME MACRO
		dc.b	'potgo.resource',0
		ds.w	0
	ENDM

	ENDC	; RESOURCES_POTGO_I

	IFND	DOS_DOSHUNKS_I
DOS_DOSHUNKS_I	SET	1
**
**	$Filename: dos/doshunks.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.6 $
**	$Date: 91/02/10 $
**
**	Hunk definitions for object and load modules.
**
**	(C) Copyright 1989-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

* hunk types

HUNK_UNIT	EQU	999
HUNK_NAME	EQU	1000
HUNK_CODE	EQU	1001
HUNK_DATA	EQU	1002
HUNK_BSS	EQU	1003
HUNK_RELOC32	EQU	1004
HUNK_RELOC16	EQU	1005
HUNK_RELOC8	EQU	1006
HUNK_EXT	EQU	1007
HUNK_SYMBOL	EQU	1008
HUNK_DEBUG	EQU	1009
HUNK_END	EQU	1010
HUNK_HEADER	EQU	1011

HUNK_OVERLAY	EQU	1013
HUNK_BREAK	EQU	1014

HUNK_DREL32	EQU	1015
HUNK_DREL16	EQU	1016
HUNK_DREL8	EQU	1017

HUNK_LIB	EQU	1018
HUNK_INDEX	EQU	1019

* hunk_ext sub-types

EXT_SYMB	EQU	0	; symbol table
EXT_DEF		EQU	1	; relocatable definition
EXT_ABS		EQU	2	; Absolute definition
EXT_RES		EQU	3	; no longer supported
EXT_REF32	EQU	129	; 32 bit reference to symbol
EXT_COMMON	EQU	130	; 32 bit reference to COMMON block
EXT_REF16	EQU	131	; 16 bit reference to symbol
EXT_REF8	EQU	132	;  8 bit reference to symbol
EXT_DEXT32	EQU	133	; 32 bit data releative reference
EXT_DEXT16	EQU	134	; 16 bit data releative reference
EXT_DEXT8	EQU	135	;  8 bit data releative reference

	ENDC	; DOS_DOSHUNKS_I

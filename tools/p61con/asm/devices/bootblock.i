	IFND	DEVICES_BOOTBLOCK_I
DEVICES_BOOTBLOCK_I	SET	1
**
**	$Filename: devices/bootblock.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.6 $
**	$Date: 90/11/05 $
**
**	floppy BootBlock definition
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

	IFND	EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC

 STRUCTURE BB,0
	STRUCT	BB_ID,4			; 4 character identifier
	LONG	BB_CHKSUM		; boot block checksum (balance)
	LONG	BB_DOSBLOCK		; reserved for DOS patch
	LABEL	BB_ENTRY		; bootstrap entry point
	LABEL	BB_SIZE

BOOTSECTS	EQU	2		; 1K bootstrap

BBID_DOS	macro			; something that is bootable
		dc.b	'DOS',0
		endm

BBID_KICK	macro			; firmware image disk
		dc.b	'KICK'
		endm


BBNAME_DOS	EQU	$444F5300	; 'DOS\0'
BBNAME_KICK	EQU	$4B49434B	; 'KICK'

	ENDC	; DEVICES_BOOTBLOCK_I

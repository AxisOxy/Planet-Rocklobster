	IFND	WORKBENCH_STARTUP_I
WORKBENCH_STARTUP_I	EQU	1
**
**	$Filename: workbench/startup.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.4 $
**	$Date: 90/12/02 $
**
**	workbench startup definitions
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	All Rights Reserved
**

	IFND	EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC

	IFND	EXEC_PORTS_I
	INCLUDE	"exec/ports.i"
	ENDC

	IFND	LIBRARIES_DOS_I
	INCLUDE	"libraries/dos.i"
	ENDC

 STRUCTURE WBStartup,0
	STRUCT	sm_Message,MN_SIZE	; a standard message structure
	APTR	sm_Process		; the process descriptor for you
	BPTR	sm_Segment		; a descriptor for your code
	LONG	sm_NumArgs		; the number of elements in ArgList
	APTR	sm_ToolWindow		; description of window
	APTR	sm_ArgList		; the arguments themselves
	LABEL	sm_SIZEOF

 STRUCTURE WBArg,0
	BPTR	wa_Lock			; a lock descriptor
	APTR	wa_Name			; a string relative to that lock
	LABEL	wa_SIZEOF

	ENDC	; WORKBENCH_STARTUP_I


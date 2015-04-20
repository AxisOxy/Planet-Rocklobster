	IFND	DEVICES_INPUT_I
DEVICES_INPUT_I SET	1
**
**	$Filename: devices/input.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.0 $
**	$Date: 90/05/01 $
**
**	input device command definitions
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

   IFND	    EXEC_IO_I
   INCLUDE     "exec/io.i"
   ENDC

   DEVINIT

   DEVCMD	IND_ADDHANDLER
   DEVCMD	IND_REMHANDLER
   DEVCMD	IND_WRITEEVENT
   DEVCMD	IND_SETTHRESH
   DEVCMD	IND_SETPERIOD
   DEVCMD	IND_SETMPORT
   DEVCMD	IND_SETMTYPE
   DEVCMD	IND_SETMTRIG

	ENDC	; DEVICES_INPUT_I

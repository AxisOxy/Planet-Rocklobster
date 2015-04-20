	IFND	DEVICES_GAMEPORT_I
DEVICES_GAMEPORT_I	SET	1
**
**	$Filename: devices/gameport.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.1 $
**	$Date: 90/11/05 $
**
**	Game Port device command definitions
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

   IFND  EXEC_TYPES_I
   INCLUDE  "exec/types.i"
   ENDC

   IFND	 EXEC_IO_I
   INCLUDE  "exec/io.i"
   ENDC


******* GamePort commands *******
   DEVINIT

   DEVCMD   GPD_READEVENT
   DEVCMD   GPD_ASKCTYPE
   DEVCMD   GPD_SETCTYPE
   DEVCMD   GPD_ASKTRIGGER
   DEVCMD   GPD_SETTRIGGER

******* GamePort structures *******

*  gpt_Keys
   BITDEF	GPT,DOWNKEYS,0
   BITDEF	GPT,UPKEYS,1

 STRUCTURE  GamePortTrigger,0
       UWORD   gpt_Keys	       ;key transition triggers
       UWORD   gpt_Timeout     ;time trigger (vertical blank units)
       UWORD   gpt_XDelta      ;X distance trigger
       UWORD   gpt_YDelta      ;Y distance trigger
       LABEL   gpt_SIZEOF

******* Controller Types ******
GPCT_ALLOCATED	  EQU	-1     ; allocated by another user
GPCT_NOCONTROLLER EQU	0

GPCT_MOUSE	  EQU	1
GPCT_RELJOYSTICK  EQU	2
GPCT_ABSJOYSTICK  EQU	3


******* Errors ******
GPDERR_SETCTYPE	  EQU	1      ; this controller not valid at this time

	ENDC	; DEVICES_GAMEPORT_I

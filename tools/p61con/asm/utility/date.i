	IFND	UTILITY_DATE_I
UTILITY_DATE_I	SET	1
**
**	$Filename: utility/date.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.2 $
**	$Date: 91/03/04 $
**
**	Date conversion routines ClockData definition.
**
**	(C) Copyright 1989-1991 Commodore-Amiga Inc.
**		All Rights Reserved
**

	IFND EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC

 STRUCTURE CLOCKDATA,0
	UWORD	sec
	UWORD	min
	UWORD	hour
	UWORD	mday
	UWORD	month
	UWORD	year
	UWORD	wday
	LABEL	CD_SIZE

	ENDC	; UTILITY_DATE_I

#ifndef LIBRARIES_PPBASE_H
#define LIBRARIES_PPBASE_H
/*
**	$Filename: libraries/ppbase.h $
**	$Release: 1.3 $
**
**	(C) Copyright 1991 Nico François
**	    All Rights Reserved
*/

#ifndef	EXEC_TYPES_H
#include	<exec/types.h>
#endif	/* EXEC_TYPES_H */

#ifndef	EXEC_LISTS_H
#include	<exec/lists.h>
#endif	/* EXEC_LISTS_H */

#ifndef	EXEC_LIBRARIES_H
#include	<exec/libraries.h>
#endif	/* EXEC_LIBRARIES_H */

#define	PPNAME		"powerpacker.library"
#define	PPVERSION	35L

struct PPBase {
   struct Library LibNode;
   UBYTE pp_Flags;
   UBYTE pad;
   BPTR pp_SegList;
   };

/* decrunch colors for ppLoadData and ppDecrunchBuffer */
#define DECR_COL0		 0L
#define DECR_COL1		 1L
#define DECR_POINTER		 2L
#define DECR_SCROLL		 3L
#define DECR_NONE		 4L

/* error codes returned by ppLoadData */
#define PP_OPENERR		-1L
#define PP_READERR		-2L
#define PP_NOMEMORY		-3L
#define PP_CRYPTED		-4L
#define PP_PASSERR		-5L
#define PP_UNKNOWNPP		-6L
#define PP_EMPTYFILE		-7L

/* size of speedup buffer */
#define SPEEDUP_BUFFLARGE	 0L
#define SPEEDUP_BUFFMEDIUM	 1L
#define SPEEDUP_BUFFSMALL	 2L

/* crunching efficiency */
#define CRUN_FAST		 0L
#define CRUN_MEDIOCRE		 1L
#define CRUN_GOOD		 2L
#define CRUN_VERYGOOD		 3L
#define CRUN_BEST		 4L

/* possible return values from ppCrunchBuffer() */
#define PP_CRUNCHABORTED	 0L
#define PP_BUFFEROVERFLOW	 ((ULONG)~0L)

#endif	/* LIBRARIES_PPBASE_H */

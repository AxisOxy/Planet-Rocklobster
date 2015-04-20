   IFND  GRAPHICS_COPPER_I
GRAPHICS_COPPER_I SET	1
**
**	$Filename: graphics/copper.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 37.1 $
**	$Date: 91/02/12 $
**
**	graphics copper list intruction definitions
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

    IFND    EXEC_TYPES_I
    include 'exec/types.i'
    ENDC

COPPER_MOVE equ 0	* pseude opcode for move #XXXX,dir
COPPER_WAIT equ 1	* pseudo opcode for wait y,x
CPRNXTBUF   equ 2	* continue processing with next buffer
CPR_NT_LOF  equ $8000	* copper instruction only for short frames
CPR_NT_SHT  equ $4000	* copper instruction only for long frames
CPR_NT_SYS  equ $2000	* copper user instruction only

   STRUCTURE   CopIns,0
      WORD  ci_OpCode	      * 0 = move, 1 = wait
      STRUCT   ci_nxtlist,0   * UNION
      STRUCT   ci_VWaitPos,0
      STRUCT   ci_DestAddr,2

      STRUCT   ci_HWaitPos,0
      STRUCT   ci_DestData,2

   LABEL ci_SIZEOF

* structure of cprlist that points to list that hardware actually executes
   STRUCTURE   cprlist,0
      APTR  crl_Next
      APTR  crl_start
      WORD  crl_MaxCount
   LABEL crl_SIZEOF

   STRUCTURE   CopList,0
      APTR  cl_Next	   * next block for this copper list
      APTR  cl__CopList    * system use
      APTR  cl__ViewPort   * system use
      APTR  cl_CopIns	   * start of this block
      APTR  cl_CopPtr	   * intermediate ptr
      APTR  cl_CopLStart   * mrgcop fills this in for Long Frame
      APTR  cl_CopSStart   * mrgcop fills this in for Short Frame
      WORD  cl_Count	   * intermediate counter
      WORD  cl_MaxCount    * max # of copins for this block
      WORD  cl_DyOffset    * offset this copper list vertical waits
   LABEL cl_SIZEOF

   STRUCTURE   UCopList,0
      APTR     ucl_Next
      APTR     ucl_FirstCopList * head node of this copper list
      APTR     ucl_CopList	* node in use
   LABEL ucl_SIZEOF

*  private graphics data structure
   STRUCTURE   copinit,0
	STRUCT	copinit_vsync_hblank,4
	STRUCT	copinit_diwstart,8
	STRUCT	copinit_diagstrt,8
	STRUCT	copinit_sprstrtup,2*(2*8*2)
	STRUCT	copinit_wait14,2*(2+2)
	STRUCT	copinit_genloc,2*(4+(2*2)+2)
	STRUCT	copinit_sprstop,8
   LABEL copinit_SIZEOF

   ENDC	; GRAPHICS_COPPER_I

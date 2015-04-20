	IFND LIBRARIES_ASL_I
LIBRARIES_ASL_I	SET	1
**
**	$Filename: libraries/asl.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.5 $
**	$Date: 91/11/08 $
**
**	ASL library name and useful definitions.
**
**	(C) Copyright 1989,1990 Charlie Heath
**	(C) Copyright 1989-1991 Commodore-Amiga, Inc.
**		All Rights Reserved
**

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC

	IFND EXEC_LIBRARIES_I
	INCLUDE "exec/libraries.i"
	ENDC

	IFND EXEC_LISTS_I
	INCLUDE "exec/lists.i"
	ENDC

	IFND	UTILITY_TAGITEM_I
	INCLUDE	"utility/tagitem.i"
	ENDC

***********************************************************************

AslName	MACRO
	dc.b	'asl.library',0
	ds.w	0
	ENDM


************************************************************************
* REQUESTER TYPES, these are passed to AllocAslRequest
************************************************************************

ASL_FileRequest		equ	0
ASL_FontRequest		equ	1


*************************************************************************
*									*
*	The ASL file requester data structure...			*
*									*
* The fields described here are for READ ACCESS to the structure	*
* returned by AllocAslRequest( ASL_FileRequest, ... )			*
*									*
* Any modifications MUST be done via TAGS either at the time of		*
* creation by AllocAslRequest(), or when used, via AslRequest()		*
*									*
*************************************************************************

	STRUCTURE FileRequester,0
	STRUCTURE FileRequestr,0		; obsolete spelling
		CPTR	rf_Reserved1
		CPTR	rf_File		; *Filename array (FCHARS+1)
		CPTR	rf_Dir			; *Directory array (DSIZE+1)
		CPTR	rf_Reserved2
		UBYTE	rf_Reserved3
		UBYTE	rf_Reserved4
		APTR	rf_Reserved5
		WORD	rf_LeftEdge
		WORD	rf_TopEdge
		WORD	rf_Width
		WORD	rf_Height
		WORD	rf_Reserved6
		LONG	rf_NumArgs
		APTR	rf_ArgList
		APTR	rf_UserData
		APTR	rf_Reserved7
		APTR	rf_Reserved8
		CPTR	rf_Pat			; *Pattern array

*****************************************************************************
*
* The following defined values are the ASL_FuncFlags tag values which
* are defined for the ASL file request.  These values may be passed
* as a TagItem to modify the way the requester is presented.  Each
* flag value defined has a description of the particular action.
*
* Also related to the ASL_FuncFlags values is the ASL_HookFunc tagitem,
* which provides a callback function to allow the application to
* interact with the requester.	If an ASL_HookFunc TagItem is
* defined, that function will be called as follows:
*
* ULONG rf_Function(ULONG Mask, CPTR Object, CPTR AslRequester)
*
* The Mask value is a copy of the specific ASL_FuncFlags value
* the callback is for; Object is a pointer to a data object.
* AslRequester is a pointer to the requester structure.
*
* For the ASL file and font requesters, two ASL_FuncFlags values
* are currently defined; FILF_DOWILDFUNC and FILF_DOMSGFUNC.
*
*****************************************************************************

* Pass these flags with the tag ASL_FuncFlags
	BITDEF	FIL,PATGAD,0		; Request a pattern gadget
	BITDEF	FIL,MULTISELECT,3	; Request multiple selection returns -
					; MUTUAL EXCLUSIVE WITH SAVE
	BITDEF	FIL,NEWIDCMP,4	; Force a new IDCMP (only if rf_Window != NULL)
	BITDEF	FIL,SAVE,5	; Use this bit for SAVE requesters
	BITDEF	FIL,DOMSGFUNC,6	; Called with Object=IDCMP messages
				;  for other windows of shered port.
				;  You must return pointer to Object,
				;  asl will reply the Object for you.
	BITDEF	FIL,DOWILDFUNC,7 ; Called with an AnchorPath,
				 ;	ZERO return accepts.


* Pass these flags with the tag ASL_ExtFlags
	BITDEF	FIL1,NOFILES,0	  ; Do not want a file gadget, no files shown
	BITDEF	FIL1,MATCHDIRS,1  ; Patgad/rf_Pat should screen files AND DIRS

*****************************************************************************
* Obsolete - Use FIL flag names instead
	BITDEF	RF,DOWILDFUNC,7 ; Called me with an AnchorPath,
				;	ZERO return accepts.
	BITDEF	RF,DOMSGFUNC,6	; You get all IDCMP message not for FileRequest()
	BITDEF	RF,DOCOLOR,5	; This bit is used for FILE SAVE operations.
	BITDEF	RF,NEWIDCMP,4	; Force a new IDCMP (only if rf_Window != NULL)
	BITDEF	RF,MULTISELECT,3 ; Request multiple selection returns -
				;	MUTUAL EXCLUSIVE WITH DOCOLOR
	BITDEF	RF,PATGAD,0	; Request a pattern gadget
*********************************************************************************

	STRUCTURE FontRequester,0
		CPTR	fo_Reserved1
		CPTR	fo_Reserved2
		APTR	fo_Name		; Returned name
		USHORT	fo_YSize
		UBYTE	fo_Style
		UBYTE	fo_Flags
		UBYTE	fo_FrontPen
		UBYTE	fo_BackPen
		UBYTE	fo_DrawMode
		UBYTE	fo_Reserved3

		APTR	fo_UserData

		SHORT	fo_LeftEdge
		SHORT	fo_TopEdge

		SHORT	fo_Width
		SHORT	fo_Height


******* BITDEFS for ASL_FuncFlags - FONT requester

	BITDEF	FON,FRONTCOLOR,0	; Display Front Color palette selector?
	BITDEF	FON,BACKCOLOR,1		; Display Back Color palette selector?
	BITDEF	FON,STYLES,2		; Display Styles checkboxes?
	BITDEF	FON,DRAWMODE,3		; Display DrawMode NWAY selector?
	BITDEF	FON,FIXEDWIDTH,4	; Only allow fixed-width (SYS) fonts?
	BITDEF	FON,NEWIDCMP,5		; Request a NEW IDCMP port,
					;	rather than shared.
	BITDEF	FON,DOMSGFUNC,6		; Called with Object=IDCMP message
					;  for other windows sharing port.
					; You must return pointer to Object.
					; asl will reply the object for you.
	BITDEF	FON,DOWILDFUNC,7	; Called with Object=TextAttr
					;	NON-Zero return accepts

****	Tag values for AslRequest()	*************************************

ASL_Dummy	equ	TAG_USER+$80000

ASL_Hail	equ	ASL_Dummy+1
ASL_Window	equ	ASL_Dummy+2

ASL_LeftEdge	equ	ASL_Dummy+3
ASL_TopEdge	equ	ASL_Dummy+4
ASL_Width	equ	ASL_Dummy+5
ASL_Height	equ	ASL_Dummy+6

ASL_HookFunc	equ	ASL_Dummy+7

ASL_File	equ	ASL_Dummy+8
ASL_Dir		equ	ASL_Dummy+9

* OVERLAP HERE file and font stuffskies!!!
ASL_Pattern	equ	ASL_Dummy+10

* Font specific, some overlap!!!
ASL_FontName	equ	ASL_Dummy+10
ASL_FontHeight	equ	ASL_Dummy+11
ASL_FontStyles	equ	ASL_Dummy+12
ASL_FontFlags	equ	ASL_Dummy+13
ASL_FrontPen	equ	ASL_Dummy+14
ASL_BackPen	equ	ASL_Dummy+15
ASL_MinHeight	equ	ASL_Dummy+16
ASL_MaxHeight	equ	ASL_Dummy+17

ASL_OKText	equ	ASL_Dummy+18
ASL_CancelText	equ	ASL_Dummy+19

ASL_FuncFlags	equ	ASL_Dummy+20

ASL_ModeList	equ	ASL_Dummy+21

*** Pass the FIL1 extended flag bits using this tag
ASL_ExtFlags1	equ	ASL_Dummy+22

	ENDC	!LIBRARIES_ASL_I

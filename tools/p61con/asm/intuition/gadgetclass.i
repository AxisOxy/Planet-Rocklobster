    IFND INTUITION_GADGETCLASS_I
INTUITION_GADGETCLASS_I SET 1
**
** $Filename: intuition/gadgetclass.i $
** $Release: 2.04 Includes, V37.4 $
** $Revision: 36.10 $
** $Date: 91/11/08 $
**
** Custom and 'boopsi' gadget class interface
**
**  (C) Copyright 1989-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC

	IFND INTUITION_INTUITION_I
	INCLUDE "intuition/intuition.i"
	ENDC

	IFND UTILITY_TAGITEM_I
	INCLUDE "utility/tagitem.i"
	ENDC


*
* NOTE:  intuition/iobsolete.i is included at the END of this file!
*

; Gadget Class attributes

GA_Dummy		EQU	(TAG_USER+$30000)
GA_Left			EQU	(GA_Dummy+$0001)
GA_RelRight		EQU	(GA_Dummy+$0002)
GA_Top			EQU	(GA_Dummy+$0003)
GA_RelBottom		EQU	(GA_Dummy+$0004)
GA_Width		EQU	(GA_Dummy+$0005)
GA_RelWidth		EQU	(GA_Dummy+$0006)
GA_Height		EQU	(GA_Dummy+$0007)
GA_RelHeight		EQU	(GA_Dummy+$0008)
GA_Text			EQU	(GA_Dummy+$0009)  ; ti_Data is (UBYTE *)
GA_Image		EQU	(GA_Dummy+$000A)
GA_Border		EQU	(GA_Dummy+$000B)
GA_SelectRender		EQU	(GA_Dummy+$000C)
GA_Highlight		EQU	(GA_Dummy+$000D)
GA_Disabled		EQU	(GA_Dummy+$000E)
GA_GZZGadget		EQU	(GA_Dummy+$000F)
GA_ID			EQU	(GA_Dummy+$0010)
GA_UserData		EQU	(GA_Dummy+$0011)
GA_SpecialInfo		EQU	(GA_Dummy+$0012)
GA_Selected		EQU	(GA_Dummy+$0013)
GA_EndGadget		EQU	(GA_Dummy+$0014)
GA_Immediate		EQU	(GA_Dummy+$0015)
GA_RelVerify		EQU	(GA_Dummy+$0016)
GA_FollowMouse		EQU	(GA_Dummy+$0017)
GA_RightBorder		EQU	(GA_Dummy+$0018)
GA_LeftBorder		EQU	(GA_Dummy+$0019)
GA_TopBorder		EQU	(GA_Dummy+$001A)
GA_BottomBorder		EQU	(GA_Dummy+$001B)
GA_ToggleSelect		EQU	(GA_Dummy+$001C)

* internal use only, until further notice, please
GA_SysGadget		EQU	(GA_Dummy+$001D)
* bool, sets GTYP_SYSGADGET field in type
GA_SysGType		EQU	(GA_Dummy+$001E)
* e.g., GTYP_WUPFRONT, ...

GA_Previous		EQU	(GA_Dummy+$001F)
* previous gadget (or (struct Gadget **)) in linked list
* NOTE: This attribute CANNOT be used to link new gadgets
* into the gadget list of an open window or requester.
* You must use AddGList().

GA_Next			EQU	(GA_Dummy+$0020)
* not implemented

GA_DrawInfo		EQU	(GA_Dummy+$0021)
* some fancy gadgets need to see a DrawInfo
* when created or for layout

* You should use at most ONE of GA_Text, GA_IntuiText, and GA_LabelImage
GA_IntuiText		EQU	(GA_Dummy+$0022)
* ti_Data is (struct IntuiText	*)

GA_LabelImage		EQU	(GA_Dummy+$0023)
* ti_Data is an image (object), used in place of
* GadgetText

GA_TabCycle		EQU	(GA_Dummy+$0024)
* New for V37:
* Boolean indicates that this gadget is to participate in
* cycling activation with Tab or Shift-Tab.

* PROPGCLASS attributes

PGA_Dummy		EQU	(TAG_USER+$31000)
PGA_Freedom		EQU	(PGA_Dummy+$0001)
* either or both of FREEVERT and FREEHORIZ
PGA_Borderless		EQU	(PGA_Dummy+$0002)
PGA_HorizPot		EQU	(PGA_Dummy+$0003)
PGA_HorizBody		EQU	(PGA_Dummy+$0004)
PGA_VertPot		EQU	(PGA_Dummy+$0005)
PGA_VertBody		EQU	(PGA_Dummy+$0006)
PGA_Total		EQU	(PGA_Dummy+$0007)
PGA_Visible		EQU	(PGA_Dummy+$0008)
PGA_Top			EQU	(PGA_Dummy+$0009)
; New for V37:
PGA_NewLook		EQU	(PGA_Dummy+$000A)

* STRGCLASS attributes

STRINGA_Dummy			EQU	(TAG_USER+$32000)
STRINGA_MaxChars	EQU	(STRINGA_Dummy+$0001)
STRINGA_Buffer		EQU	(STRINGA_Dummy+$0002)
STRINGA_UndoBuffer	EQU	(STRINGA_Dummy+$0003)
STRINGA_WorkBuffer	EQU	(STRINGA_Dummy+$0004)
STRINGA_BufferPos	EQU	(STRINGA_Dummy+$0005)
STRINGA_DispPos		EQU	(STRINGA_Dummy+$0006)
STRINGA_AltKeyMap	EQU	(STRINGA_Dummy+$0007)
STRINGA_Font		EQU	(STRINGA_Dummy+$0008)
STRINGA_Pens		EQU	(STRINGA_Dummy+$0009)
STRINGA_ActivePens	EQU	(STRINGA_Dummy+$000A)
STRINGA_EditHook	EQU	(STRINGA_Dummy+$000B)
STRINGA_EditModes	EQU	(STRINGA_Dummy+$000C)

* booleans
STRINGA_ReplaceMode	EQU	(STRINGA_Dummy+$000D)
STRINGA_FixedFieldMode	EQU	(STRINGA_Dummy+$000E)
STRINGA_NoFilterMode	EQU	(STRINGA_Dummy+$000F)

STRINGA_Justification	EQU	(STRINGA_Dummy+$0010)
* GACT_STRINGCENTER, GACT_STRINGLEFT, GACT_STRINGRIGHT
STRINGA_LongVal		EQU	(STRINGA_Dummy+$0011)
STRINGA_TextVal		EQU	(STRINGA_Dummy+$0012)

STRINGA_ExitHelp	EQU	(STRINGA_Dummy+$0013)
* STRINGA_ExitHelp is new for V37, and ignored by V36.
* Set this if you want the gadget to exit when Help is
* pressed.  Look for a code of 0x5F, the rawkey code for Help

SG_DEFAULTMAXCHARS	EQU	(128)

* Gadget Layout related attributes

LAYOUTA_Dummy		EQU	(TAG_USER+$38000)
LAYOUTA_LayoutObj	EQU	(LAYOUTA_Dummy+$0001)
LAYOUTA_Spacing		EQU	(LAYOUTA_Dummy+$0002)
LAYOUTA_Orientation	EQU	(LAYOUTA_Dummy+$0003)

* orientation values
LORIENT_NONE		EQU	0
LORIENT_HORIZ		EQU	1
LORIENT_VERT		EQU	2

; Custom gadget hook command ID's 
; (gadget class method/message ID's)

GM_HITTEST EQU		0	; return GMR_GADGETHIT if you are clicked
				; (whether or not you are disabled)
GM_RENDER EQU		1	; draw yourself, in the appropriate state
GM_GOACTIVE EQU		2	; you are now going to be fed input
GM_HANDLEINPUT EQU	3	; handle that input
GM_GOINACTIVE EQU	4	; whether or not by choice, you are done

; Parameter "Messages" passed to gadget class methods

; All parameter structure begin with a MethodID field
; This definition of an abstract generic "message" is
; equivalent to a better one in intuition/classusr.i, but
; it's left here for historic reasons
 STRUCTURE MsgHeader,0
	ULONG	MethodID
	LABEL	methodid_SIZEOF

; GM_HITTEST
 STRUCTURE	gpHitTest,methodid_SIZEOF
    APTR	gpht_GInfo
    WORD	gpht_MouseX
    WORD	gpht_MouseY

; GM_HITTEST return value
GMR_GADGETHIT	EQU $00000004	; if no hit, return 0

; GM_RENDER
 STRUCTURE	gpRender,methodid_SIZEOF
    APTR	gpr_GInfo	; gadget context
    APTR	gpr_RPort	; all ready for use
    LONG	gpr_Redraw	; might be a "highlight pass"

; values of gpr_Redraw
GREDRAW_UPDATE	EQU 2	; update for change in attributesvalues
GREDRAW_REDRAW	EQU 1	; redraw gadget
GREDRAW_TOGGLE	EQU 0	; toggle highlight, if applicable

; GM_GOACTIVE, GM_HANDLEINPUT
 STRUCTURE	gpInput,methodid_SIZEOF
    APTR	gpi_GInfo
    APTR	gpi_IEvent
    APTR	gpi_Termination
    WORD	gpi_MouseX
    WORD	gpi_MouseY

; GM_HANDLEINPUT and GM_GOACTIVE  return code flags
; return GMR_MEACTIVE (0) alone if you want more input.
; Otherwise, return ONE of GMR_NOREUSE and GMR_REUSE, and optionally
; GMR_VERIFY.

; here are the original constant "equates"
GMR_MEACTIVE	EQU $0000 	; (bugfix: was $0001 during beta)
GMR_NOREUSE	EQU $0002
GMR_REUSE	EQU $0004
GMR_VERIFY	EQU $0008	; you MUST set cgp_Termination

* New for V37:
* You can end activation with one of GMR_NEXTACTIVE and GMR_PREVACTIVE,
* which instructs Intuition to activate the next or previous gadget
* that has GFLG_TABCYCLE set.
*
GMR_NEXTACTIVE	EQU $0010
GMR_PREVACTIVE	EQU $0020

; here are standard bit/flag pairs
GMRB_NOREUSE	EQU 1
GMRB_REUSE	EQU 2
GMRB_VERIFY	EQU 3
GMRB_NEXTACTIVE	EQU 4
GMRB_PREVACTIVE	EQU 5

GMRF_NOREUSE	EQU $0002
GMRF_REUSE	EQU $0004
GMRF_VERIFY	EQU $0008
GMRF_NEXTACTIVE	EQU $0010
GMRF_PREVACTIVE	EQU $0020

; GM_GOINACTIVE
 STRUCTURE	gpGoInactive,methodid_SIZEOF
    APTR	gpgi_GInfo

* V37 field only!  DO NOT attempt to read under V36!
    ULONG	gpgi_Abort	; gpgi_Abort=1 if gadget was aborted
				; by Intuition and 0 if gadget went
				; inactive at its own request

* Include obsolete identifiers:
	IFND	INTUITION_IOBSOLETE_I
	INCLUDE "intuition/iobsolete.i"
	ENDC

	ENDC

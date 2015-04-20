	IFND LIBRARIES_GADTOOLS_I
LIBRARIES_GADTOOLS_I	SET	1
**
**	$Filename: libraries/gadtools.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.13 $
**	$Date: 91/10/09 $
**
**	gadtools.library definitions
**
**	(C) Copyright 1989-1991 Commodore-Amiga, Inc.
**	All Rights Reserved.
**

*------------------------------------------------------------------------*

	IFND EXEC_TYPES_I
	INCLUDE 'exec/types.i'
	ENDC

	IFND UTILITY_TAGITEM_I
	INCLUDE 'utility/tagitem.i'
	ENDC

	IFND INTUITION_INTUITION_I
	INCLUDE 'intuition/intuition.i'
	ENDC

*------------------------------------------------------------------------*

*	The kinds (almost classes) of gadgets in the toolkit.  Use these
*	identifiers when calling CreateGadgetA()

GENERIC_KIND	EQU	0
BUTTON_KIND	EQU	1
CHECKBOX_KIND	EQU	2
INTEGER_KIND	EQU	3
LISTVIEW_KIND	EQU	4
MX_KIND		EQU	5
NUMBER_KIND	EQU	6
CYCLE_KIND	EQU	7
PALETTE_KIND	EQU	8
SCROLLER_KIND	EQU	9
* Kind number 10 is reserved
SLIDER_KIND	EQU	11
STRING_KIND	EQU	12
TEXT_KIND	EQU	13

NUM_KINDS	EQU	14

*------------------------------------------------------------------------*

*  These two definitions are obsolete, but are here for backwards
*  compatibility.  You never need to worry about these:
GADTOOLBIT	EQU	$8000

*  Use this mask to isolate the user part: *
GADTOOLMASK	EQU	~GADTOOLBIT

*------------------------------------------------------------------------*

*  'Or' the appropriate set together for your Window IDCMPFlags: *

ARROWIDCMP	EQU	GADGETUP!GADGETDOWN!INTUITICKS!MOUSEBUTTONS

BUTTONIDCMP	EQU	GADGETUP
CHECKBOXIDCMP	EQU	GADGETUP
INTEGERIDCMP	EQU	GADGETUP
LISTVIEWIDCMP	EQU	GADGETUP!GADGETDOWN!MOUSEMOVE!ARROWIDCMP

MXIDCMP		EQU	GADGETDOWN
NUMBERIDCMP	EQU	0
CYCLEIDCMP	EQU	GADGETUP
PALETTEIDCMP	EQU	GADGETUP

*  Use ARROWIDCMP!SCROLLERIDCMP if your scrollers have arrows: *
SCROLLERIDCMP	EQU	GADGETUP!GADGETDOWN!MOUSEMOVE
SLIDERIDCMP	EQU	GADGETUP!GADGETDOWN!MOUSEMOVE
STRINGIDCMP	EQU	GADGETUP

TEXTIDCMP	EQU	0

*------------------------------------------------------------------------*

*  Typical suggested spacing between "elements": *
INTERWIDTH	EQU	8
INTERHEIGHT	EQU	4

*------------------------------------------------------------------------*

*  Generic NewGadget used by several of the gadget classes: *

    STRUCTURE NewGadget,0

	WORD	gng_LeftEdge
	WORD	gng_TopEdge	; gadget position
	WORD	gng_Width
	WORD	gng_Height	;  gadget size
	APTR	gng_GadgetText	; gadget label
	APTR	gng_TextAttr	; desired font for gadget label
	UWORD	gng_GadgetID	; gadget ID
	ULONG	gng_Flags	; see below
	APTR	gng_VisualInfo	; Set to retval of GetVisualInfo()
	APTR	gng_UserData	; gadget UserData

	LABEL	gng_SIZEOF

*   ng_Flags control certain aspects of the gadget.  The first five control
*   the placement of the descriptive text.  All larger groups supply a
*   default:

PLACETEXT_LEFT	EQU	$0001	* Right-align text on left side
PLACETEXT_RIGHT	EQU	$0002	* Left-align text on right side
PLACETEXT_ABOVE	EQU	$0004	* Center text above
PLACETEXT_BELOW	EQU	$0008	* Center text below
PLACETEXT_IN	EQU	$0010	* Center text on

NG_HIGHLABEL	EQU	$0020	* Highlight the label

*------------------------------------------------------------------------*

* Fill out an array of these and pass that to CreateMenus():

    STRUCTURE NewMenu,0

	UBYTE	gnm_Type		; See below
	UBYTE	gnm_Pad			; alignment padding
	APTR	gnm_Label		; Menu's label
	APTR	gnm_CommKey		; MenuItem Command Key Equiv
	UWORD	gnm_Flags		; Menu or MenuItem flags (see note)
	LONG	gnm_MutualExclude	; MenuItem MutualExclude word
	APTR	gnm_UserData		; For your own use, see note

	LABEL	gnm_SIZEOF

*  Each nm_Type should be one of these:
NM_TITLE	EQU	1
NM_ITEM		EQU	2
NM_SUB		EQU	3
NM_END		EQU	0

MENU_IMAGE	EQU	128

* For an image menu-item or sub-item, use one of these.  Set
* nm_Label to point at the Image structure you wish to use.
* NOTE: At present, you may only use conventional images.
* Custom images created from Intuition image-classes do not work.

IM_ITEM		EQU	NM_ITEM!MENU_IMAGE
IM_SUB		EQU	NM_SUB!MENU_IMAGE

*  If you set your label to NM_BARLABEL, you'll get a separator bar.
NM_BARLABEL	EQU	-1


*   The nm_Flags field is used to fill out either the Menu->Flags or
*   MenuItem->Flags field.  Note that the sense of the MENUENABLED or
*   ITEMENABLED bit is inverted between this use and Intuition's use,
*   in other words, NewMenus are enabled by default.  The following
*   labels are provided to disable them:

NM_MENUDISABLED	EQU	MENUENABLED
NM_ITEMDISABLED	EQU	ITEMENABLED

*   The following are pre-cleared (COMMSEQ, ITEMTEXT, and HIGHxxx are set
*   later as appropriate):

NM_FLAGMASK	EQU	~(COMMSEQ!ITEMTEXT!HIGHFLAGS)

*   You may choose among CHECKIT, MENUTOGGLE, and CHECKED.
*   Toggle-select menuitems are of type CHECKIT!MENUTOGGLE, along
*   with CHECKED if currently selected.  Mutually exclusive ones
*   are of type CHECKIT, and possibly CHECKED too.  The nm_MutualExclude
*   is a bit-wise representation of the items excluded by this one,
*   so in the simplest case (choose 1 among n), these flags would be
*   ~1, ~2, ~4, ~8, ~16, etc.  See the Intuition Menus chapter.

*   A UserData pointer can be associated with each Menu and MenuItem structure.
*   The CreateMenus() call allocates space for a UserData after each
*   Menu or MenuItem (header, item or sub-item).  You should use the
*   GTMENU_USERDATA or GTMENUITEM_USERDATA macro to extract it. */

GTMENU_USERDATA	MACRO
		move.l	mu_SIZEOF(\1),\2
		ENDM

GTMENUITEM_USERDATA	MACRO
		move.l	mi_SIZEOF(\1),\2
		ENDM

*  Here is an old one for compatibility.  Do not use in new code!
MENU_USERDATA	MACRO
		move.l	mi_SIZEOF(\1),\2
		ENDM


*  These return codes can be obtained through the GTMN_SecondaryError tag:
GTMENU_TRIMMED	EQU	$00000001	; Too many menus, items, or subitems,
					; menu has been trimmed down
GTMENU_INVALID	EQU	$00000002	; Invalid NewMenu array
GTMENU_NOMEM	EQU	$00000003	; Out of memory


*------------------------------------------------------------------------*

*  Tags for toolkit functions:

GT_TagBase	EQU	TAG_USER+$80000 ; Begin counting tags

GTVI_NewWindow	EQU	GT_TagBase+$01	; NewWindow struct for GetVisualInfo
GTVI_NWTags	EQU	GT_TagBase+$02	; NWTags for GetVisualInfo

GT_Private0	EQU	GT_TagBase+$03	; (private)

GTCB_Checked	EQU	GT_TagBase+$04	; State of checkbox

GTLV_Top	EQU	GT_TagBase+$05	; Top visible one in listview
GTLV_Labels	EQU	GT_TagBase+$06	; List to display in listview
GTLV_ReadOnly	EQU	GT_TagBase+$07	; TRUE if listview is to be read-only
GTLV_ScrollWidth	EQU	GT_TagBase+$08	; Width of scrollbar

GTMX_Labels	EQU	GT_TagBase+$09	; NULL-terminated array of labels
GTMX_Active	EQU	GT_TagBase+$0A	; Active one in mx gadget

GTTX_Text	EQU	GT_TagBase+$0B	; Text to display
GTTX_CopyText	EQU	GT_TagBase+$0C	; Copy text label instead of referencing it

GTNM_Number	EQU	GT_TagBase+$0D	; Number to display

GTCY_Labels	EQU	GT_TagBase+$0E	; NULL-terminated array of labels
GTCY_Active	EQU	GT_TagBase+$0F	; The active one in the cycle gad

GTPA_Depth	EQU	GT_TagBase+$10	; Number of bitplanes in palette
GTPA_Color	EQU	GT_TagBase+$11	; Palette color
GTPA_ColorOffset	EQU	GT_TagBase+$12	; First color to use in palette
GTPA_IndicatorWidth	EQU	GT_TagBase+$13	; Width of current-color indicator
GTPA_IndicatorHeight	EQU	GT_TagBase+$14	; Height of current-color indicator

GTSC_Top	EQU	GT_TagBase+$15	; Top visible in scroller
GTSC_Total	EQU	GT_TagBase+$16	; Total in scroller area
GTSC_Visible	EQU	GT_TagBase+$17	; Number visible in scroller
GTSC_Overlap	EQU	GT_TagBase+$18	; Unused

* GT_TagBase+$19 through GT_TagBase+$25 are reserved

GTSL_Min	EQU	GT_TagBase+$26	; Slider min value
GTSL_Max	EQU	GT_TagBase+$27	; Slider max value
GTSL_Level	EQU	GT_TagBase+$28	; Slider level
GTSL_MaxLevelLen	EQU	GT_TagBase+$29	; Max length of printed level
GTSL_LevelFormat	EQU	GT_TagBase+$2A	; Format string for level
GTSL_LevelPlace	EQU	GT_TagBase+$2B	; Where level should be placed
GTSL_DispFunc	EQU	GT_TagBase+$2C	; Callback for number calculation before display

GTST_String	EQU	GT_TagBase+$2D	; String gadget's displayed string
GTST_MaxChars	EQU	GT_TagBase+$2E	; Max length of string

GTIN_Number	EQU	GT_TagBase+$2F	; Number in integer gadget
GTIN_MaxChars	EQU	GT_TagBase+$30	; Max number of digits

GTMN_TextAttr	EQU	GT_TagBase+$31	; MenuItem font TextAttr
GTMN_FrontPen	EQU	GT_TagBase+$32	; MenuItem text pen color

GTBB_Recessed	EQU	GT_TagBase+$33	; Make BevelBox recessed

GT_VisualInfo	EQU	GT_TagBase+$34	; result of VisualInfo call

GTLV_ShowSelected	EQU	GT_TagBase+$35	; show selected entry beneath listview,
			; set tag data = NULL for display-only, or pointer
			; to a string gadget you've created
GTLV_Selected	EQU	GT_TagBase+$36	; Set ordinal number of selected entry in the list
GT_Reserved1	EQU	GT_TagBase+$38	; Reserved for future use

GTTX_Border	EQU	GT_TagBase+$39	; Put a border around Text-display gadgets
GTNM_Border	EQU	GT_TagBase+$3A	; Put a border around Number-display gadgets

GTSC_Arrows	EQU	GT_TagBase+$3B	; Specify size of arrows for scroller
GTMN_Menu	EQU	GT_TagBase+$3C	; Pointer to Menu for use by
			; LayoutMenuItems()
GTMX_Spacing	EQU	GT_TagBase+$3D	; Added to font height to
			; figure spacing between mx choices.  Use this
			; instead of LAYOUTA_SPACING for mx gadgets.

*  New to V37 GadTools.  Ignored by GadTools V36.
GTMN_FullMenu	EQU	GT_TagBase+$3E  ; Asks CreateMenus() to
		; validate that this is a complete menu structure
GTMN_SecondaryError	EQU	GT_TagBase+$3F  ; ti_Data is a pointer
		; to a ULONG to receive error reports from CreateMenus()
GT_Underscore	EQU	GT_TagBase+$40	; ti_Data points to the symbol
		; that preceeds the character you'd like to underline in a
		; gadget label
GTST_EditHook	EQU	GT_TagBase+$37	; String EditHook

*  Old definition, now obsolete:
GT_Reserved0	EQU	GTST_EditHook

*------------------------------------------------------------------------*

* "NWay" is an old synonym for cycle gadgets

NWAY_KIND	EQU	CYCLE_KIND
NWAYIDCMP	EQU	CYCLEIDCMP

GTNW_Labels	EQU	GTCY_Labels
GTNW_Active	EQU	GTCY_Active

	ENDC

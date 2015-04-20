	IFND  INTUITION_SCREENS_I
INTUITION_SCREENS_I	SET  1
**
**	$Filename: intuition/screens.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 36.18 $
**	$Date: 91/10/07 $
**
**	The Screen and NewScreen structures and attributes
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**
	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC

	IFND GRAPHICS_GFX_I
	INCLUDE "graphics/gfx.i"
	ENDC

	IFND GRAPHICS_CLIP_I
	INCLUDE "graphics/clip.i"
	ENDC

	IFND GRAPHICS_VIEW_I
	INCLUDE "graphics/view.i"
	ENDC

	IFND GRAPHICS_RASTPORT_I
	INCLUDE "graphics/rastport.i"
	ENDC

	IFND GRAPHICS_LAYERS_I
	INCLUDE "graphics/layers.i"
	ENDC

	IFND UTILITY_TAGITEM_I
	INCLUDE "utility/tagitem.i"
	ENDC

*
* NOTE:  intuition/iobsolete.i is included at the END of this file!
*

; ========================================================================
; === DrawInfo =========================================================
; ========================================================================

* This is a packet of information for graphics rendering.  It originates
* with a Screen, and is gotten using GetScreenDrawInfo( screen );

* If you find dri_Version >= DRI_VERSION, you know this structure
* has at least the fields defined in this version of the include file

DRI_VERSION	EQU	1

 STRUCTURE DrawInfo,0
    UWORD	dri_Version	 ; will be  DRI_VERSION
    UWORD	dri_NumPens	 ; guaranteed to be >= NUMDRIPENS
    APTR	dri_Pens	 ; pointer to pen array
    APTR	dri_Font	 ; screen default font
    UWORD	dri_Depth	 ; (initial) depth of screen bitmap
    ; from DisplayInfo database for initial display mode
    UWORD	dri_ResolutionX
    UWORD	dri_ResolutionY
    ULONG	dri_Flags
   STRUCT	dri_longreserved,28

DRIF_NEWLOOK	EQU	$00000001 ; specified SA_Pens, full treatment
DRIB_NEWLOOK	EQU	0

    ; rendering pen number indexes into DrawInfo.dri_Pens[]
    ENUM
    EITEM	DETAILPEN	; compatible Intuition rendering pens
    EITEM	BLOCKPEN,
    EITEM	TEXTPEN		; text on background (pen = 0)
    EITEM	SHINEPEN	; bright edge on bas-relief
    EITEM	SHADOWPEN	; dark edge
    EITEM	FILLPEN		; active window fill
    EITEM	FILLTEXTPEN	; text over FILLPEN
    EITEM	BACKGROUNDPEN	; always color 0
    EITEM	HIGHLIGHTTEXTPEN  ; highlighted text, against BACKGROUNDPEN
    EITEM	NUMDRIPENS


; ========================================================================
; === Screen =============================================================
; ========================================================================
 STRUCTURE Screen,0

    APTR sc_NextScreen		; linked list of screens
    APTR sc_FirstWindow		; linked list Screen's Windows

    WORD sc_LeftEdge		; parameters of the screen
    WORD sc_TopEdge		; parameters of the screen

    WORD sc_Width		; null-terminated Title text
    WORD sc_Height		; for Windows without ScreenTitle

    WORD sc_MouseY		; position relative to upper-left
    WORD sc_MouseX		; position relative to upper-left

    WORD sc_Flags		; see definitions below

    APTR sc_Title
    APTR sc_DefaultTitle

    ; Bar sizes for this Screen and all Window's in this Screen
    BYTE sc_BarHeight
    BYTE sc_BarVBorder
    BYTE sc_BarHBorder
    BYTE sc_MenuVBorder
    BYTE sc_MenuHBorder
    BYTE sc_WBorTop
    BYTE sc_WBorLeft
    BYTE sc_WBorRight
    BYTE sc_WBorBottom

    BYTE sc_KludgeFill00	; This is strictly for word-alignment

    ; the display data structures for this Screen
    APTR sc_Font			; this screen's default font
    STRUCT sc_ViewPort,vp_SIZEOF	; describing the Screen's display
    STRUCT sc_RastPort,rp_SIZEOF	; describing Screen rendering
    STRUCT sc_BitMap,bm_SIZEOF		; auxiliary graphexcess baggage
    STRUCT sc_LayerInfo,li_SIZEOF	; each screen gets a LayerInfo

    APTR sc_FirstGadget

    BYTE sc_DetailPen		; for bar/border/gadget rendering
    BYTE sc_BlockPen		; for bar/border/gadget rendering

    ; the following variable(s) are maintained by Intuition to support the
    ; DisplayBeep() color flashing technique
    WORD sc_SaveColor0

    ; This layer is for the Screen and Menu bars
    APTR sc_BarLayer		; was "BarLayer"

    APTR sc_ExtData

    APTR sc_UserData		; general-purpose pointer to User data

    LABEL sc_SIZEOF	; actually, you have no business talking about
			; or relying on the size of a screen structure


; --- FLAGS SET BY INTUITION -------------------------------------------------
; The SCREENTYPE bits are reserved for describing various Screen types
; available under Intuition.
SCREENTYPE	EQU	$000F	; all the screens types available
; --- the definitions for the Screen Type ------------------------------------
WBENCHSCREEN	EQU	$0001	; identifies the Workbench screen
PUBLICSCREEN	EQU	$0002	; public shared (custom) screen
CUSTOMSCREEN	EQU	$000F	; for that special look

SHOWTITLE	EQU	$0010	; this gets set by a call to ShowTitle()

BEEPING	EQU	$0020	; set when Screen is beeping

CUSTOMBITMAP	EQU	$0040	; if you are supplying your own BitMap

SCREENBEHIND	EQU	$0080	; if you want your screen to open behind
				; already open screens

SCREENQUIET	EQU	$0100	; if you do not want Intuition to render
				; into your screen (gadgets, title)

SCREENHIRES	EQU	$0200	; do not use lowres gadgets (set by intuition)

STDSCREENHEIGHT	EQU	-1	; supply in NewScreen.Height
STDSCREENWIDTH	EQU	-1	; supply in NewScreen.Width

NS_EXTENDED	EQU	$1000	; means ns_Extenion is valid
AUTOSCROLL	EQU	$4000	; automatic scrolling of large raster

* Screen attribute tag ID's.  These are used in the ti_Tag field of
* TagItem arrays passed to OpenScreenTagList() (or in the
* ExtNewScreen.Extension field).

* Screen attribute tags.  Please use these versions, not those in
* iobsolete.h.

 ENUM TAG_USER+33
* 
*   these items specify items equivalent to fields in NewScreen
    EITEM SA_Left	; traditional screen positions	and dimensions
    EITEM SA_Top
    EITEM SA_Width
    EITEM SA_Height
    EITEM SA_Depth	; screen bitmap depth
    EITEM SA_DetailPen	; serves as default for windows, too
    EITEM SA_BlockPen
    EITEM SA_Title	; default screen title

    EITEM SA_Colors	; ti_Data is an array of struct ColorSpec, 
			; terminated by ColorIndex = -1.  Specifies 
			; initial screen palette colors.

    EITEM SA_ErrorCode	; ti_Data points to LONG error code (values below)
    EITEM SA_Font	; equiv. to NewScreen.Font
    EITEM SA_SysFont	; Selects one of the preferences system fonts:
			;	0 - old DefaultFont, fixed-width
			;	1 - WB Screen preferred font


    EITEM SA_Type	; equiv. to NewScreen.Type
    EITEM SA_BitMap	; ti_Data is pointer to custom BitMap.  This
			; implies type of CUSTOMBITMAP	

    EITEM SA_PubName	; presence of this tag means that the screen
			; is to be a public screen.  Please specify
			; BEFORE the two tags below

    EITEM SA_PubSig
    EITEM SA_PubTask	; Task ID and signal for being notified that
			; the last window has closed on a public screen.


    EITEM SA_DisplayID	; ti_Data is new extended display ID from 
			; <graphics/displayinfo.h>.

    EITEM SA_DClip	; ti_Data points to a rectangle which defines
			; screen display clip region

    EITEM SA_Overscan	; was S_STDDCLIP.  Set to one of the OSCAN_
			; specifiers below to get a system standard
			; overscan region for your display clip,
			; screen dimensions (unless otherwise specified),
			; and automatically centered position (partial
			; support only so far).

    EITEM SA_Obsolete1	; obsolete S_MONITORNAME

*   booleans *
    EITEM SA_ShowTitle	; boolean equivalent to flag SHOWTITLE
    EITEM SA_Behind	; boolean equivalent to flag SCREENBEHIND
    EITEM SA_Quiet	; boolean equivalent to flag SCREENQUIET
    EITEM SA_AutoScroll	; boolean equivalent to flag AUTOSCROLL
    EITEM SA_Pens	; array as in DrawInfo, terminated by -1
    EITEM SA_FullPalette ; boolean: initialize color table to entire
   			 ;  preferences palette (32 for V36), rather
			 ; than compatible pens 0-3, 17-19, with
			 ; remaining palette as returned by GetColorMap()


* OpenScreen error codes, which are returned in the (optional) LONG
* pointed to by ti_Data for the SA_ErrorCode tag item

OSERR_NOMONITOR	EQU	(1)	; named monitor spec not available
OSERR_NOCHIPS	EQU	(2)	; you need newer custom chips	
OSERR_NOMEM	EQU	(3)	; couldn't get normal memory
OSERR_NOCHIPMEM	EQU	(4)	; couldn't get chipmem
OSERR_PUBNOTUNIQUE	EQU (5)	; public screen name already used
OSERR_UNKNOWNMODE	EQU (6)	; don't recognize mode asked for

; ========================================================================
; === NewScreen ==========================================================
; ========================================================================
; NOTE: to use Extension field, you need to use ExtNewScreen, below
 STRUCTURE NewScreen,0

    WORD ns_LeftEdge		; initial Screen dimensions
    WORD ns_TopEdge		; initial Screen dimensions
    WORD ns_Width		; initial Screen dimensions
    WORD ns_Height		; initial Screen dimensions
    WORD ns_Depth		; initial Screen dimensions

    BYTE ns_DetailPen		; default rendering pens (for Windows too)
    BYTE ns_BlockPen		; default rendering pens (for Windows too)

    WORD ns_ViewModes		; display "modes" for this Screen

    WORD ns_Type		; Intuition Screen Type specifier

    APTR ns_Font		; default font for Screen and Windows

    APTR ns_DefaultTitle	; Title when Window doesn't care

    APTR ns_Gadgets		; UNUSED:  Leave this NULL

    ; if you are opening a CUSTOMSCREEN and already have a BitMap 
    ; that you want used for your Screen, you set the flags CUSTOMBITMAP in
    ; the Types variable and you set this variable to point to your BitMap
    ; structure.  The structure will be copied into your Screen structure,
    ; after which you may discard your own BitMap if you want
    APTR ns_CustomBitMap
 LABEL    ns_SIZEOF

; For compatibility reasons, we need a new structure for extending
; NewScreen.  Use this structure is you need to use the new Extension
; field.
; NOTE WELL: this structure may be extended again in the future.
;Writing code which depends on its size is not allowed.

 STRUCTURE ExtNewScreen,ns_SIZEOF

    APTR ens_Extension		; struct TagItem *
				; more specification data, scanned if
				; NS_EXTENDED is set in ns_Type

 LABEL    ens_SIZEOF

* === Overscan Types ===
OSCAN_TEXT	EQU	1	; entirely visible
OSCAN_STANDARD	EQU	2	; just past edges
OSCAN_MAX	EQU	3	; as much as possible
OSCAN_VIDEO	EQU	4	; even more than is possible


* === Public Shared Screen Node ===

* This is the representative of a public shared screen.
* This is an internal data structure, but some functions may
* present a copy of it to the calling application.  In that case,
* be aware that the screen pointer of the structure can NOT be
* used safely, since there is no guarantee that the referenced
* screen will remain open and a valid data structure.

 STRUCTURE PubScreenNode,LN_SIZE
    APTR	psn_Screen	; pointer to screen itself
    UWORD	psn_Flags	; below
    WORD	psn_Size	; includes name buffer size
    WORD	psn_VisitorCount ; how many visitor windows
    APTR	psn_SigTask	; who to signal when visitors gone
    UBYTE	psn_SigBit	; which signal
    UBYTE	psn_Pad1	; word align
 LABEL		psn_SIZEOF

* psn_Flags values
PSNF_PRIVATE	EQU	$0001

* NOTE: Due to a bug in NextPubScreen(), make sure your buffer
* actually has MAXPUBSCREENNAME+1 characters in it!

MAXPUBSCREENNAME EQU	139	; names no longer, please

; pub screen modes
SHANGHAI	EQU	$0001	; put workbench windows on pub screen
POPPUBSCREEN	EQU	$0002	; pop pub screen to front when visitor opens

* Include obsolete identifiers:
	IFND	INTUITION_IOBSOLETE_I
	INCLUDE "intuition/iobsolete.i"
	ENDC

	ENDC

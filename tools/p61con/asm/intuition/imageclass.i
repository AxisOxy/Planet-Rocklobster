    IFND INTUITION_IMAGECLASS_I
INTUITION_IMAGECLASS_I SET 1
**
**  $Filename: intuition/imageclass.i $
**  $Release: 2.04 Includes, V37.4 $
**  $Revision: 36.5 $
**  $Date: 91/11/08 $
**
**  Definitions for the image classes
**
**  (C) Copyright 1989-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

    IFND UTILITY_TAGITEM_I
    INCLUDE "utility/tagitem.i"
    ENDC

*
* NOTE:  intuition/iobsolete.i is included at the END of this file!
*

CUSTOMIMAGEDEPTH	EQU (-1)
* if image.Depth is this, it's a new Image class object

******************************************************
IMAGE_ATTRIBUTES	EQU (TAG_USER+$20000)

IA_Left		EQU (IMAGE_ATTRIBUTES+$0001)
IA_Top		EQU (IMAGE_ATTRIBUTES+$0002)
IA_Width	EQU (IMAGE_ATTRIBUTES+$0003)
IA_Height	EQU (IMAGE_ATTRIBUTES+$0004)
IA_FGPen	EQU (IMAGE_ATTRIBUTES+$0005)
		    ; IA_FGPen also means "PlanePick"
IA_BGPen	EQU (IMAGE_ATTRIBUTES+$0006)
		    ; IA_BGPen also means "PlaneOnOff"
IA_Data		EQU (IMAGE_ATTRIBUTES+$0007)
		    ; bitplanes, for classic image,
		    ; other image classes may use it for other things
IA_LineWidth	EQU (IMAGE_ATTRIBUTES+$0008)
IA_Pens		EQU (IMAGE_ATTRIBUTES+$000E)
		    ; pointer to UWORD pens[],
		    ; ala DrawInfo.Pens, MUST be
		    ; terminated by ~0.  Some classes can
		    ; choose to have this, or SYSIA_DrawInfo,
		    ; or both.
IA_Resolution	EQU (IMAGE_ATTRIBUTES+$000F)
		    ; packed uwords for x/y resolution into a longword
		    ; ala DrawInfo.Resolution

* see class documentation to learn which 
* classes recognize these
IA_APattern	EQU (IMAGE_ATTRIBUTES+$0010)
IA_APatSize	EQU (IMAGE_ATTRIBUTES+$0011)
IA_Mode		EQU (IMAGE_ATTRIBUTES+$0012)
IA_Font		EQU (IMAGE_ATTRIBUTES+$0013)
IA_Outline	EQU (IMAGE_ATTRIBUTES+$0014)
IA_Recessed	EQU (IMAGE_ATTRIBUTES+$0015)
IA_DoubleEmboss	EQU (IMAGE_ATTRIBUTES+$0016)
IA_EdgesOnly	EQU (IMAGE_ATTRIBUTES+$0017)

* "sysiclass" attributes
SYSIA_Size	EQU (IMAGE_ATTRIBUTES+$000B)
		    ; EQU's below
SYSIA_Depth	EQU (IMAGE_ATTRIBUTES+$000C)
		    ; this is unused by Intuition.  SYSIA_DrawInfo
		    ; is used instead for V36
SYSIA_Which	EQU (IMAGE_ATTRIBUTES+$000D)
		    ; see EQU's below
SYSIA_DrawInfo	EQU (IMAGE_ATTRIBUTES+$0018)
		    ; pass to sysiclass, please

*  obsolete: don't use these, use IA_Pens
SYSIA_Pens	EQU IA_Pens
IA_ShadowPen	EQU (IMAGE_ATTRIBUTES+$0009)
IA_HighlightPen	EQU (IMAGE_ATTRIBUTES+$000A)

* next attribute: (IMAGE_ATTRIBUTES+$0019)
******************************************************

* data values for SYSIA_Size
SYSISIZE_MEDRES	EQU (0)
SYSISIZE_LOWRES	EQU (1)
SYSISIZE_HIRES	EQU (2)

*
* SYSIA_Which tag data values:
* Specifies which system gadget you want an image for.
* Some numbers correspond to internal Intuition #defines
DEPTHIMAGE	EQU ($00)
ZOOMIMAGE	EQU ($01)
SIZEIMAGE	EQU ($02)
CLOSEIMAGE	EQU ($03)
SDEPTHIMAGE	EQU ($05)		; screen depth gadget
LEFTIMAGE	EQU ($0A)
UPIMAGE		EQU ($0B)
RIGHTIMAGE	EQU ($0C)
DOWNIMAGE	EQU ($0D)
CHECKIMAGE	EQU ($0E)
MXIMAGE		EQU ($0F)	; mutual exclude "button"

* image message id's
IM_DRAW		EQU ($0202)	; draw yourself, with "state"
IM_HITTEST	EQU ($0203)	; return TRUE if click hits image
IM_ERASE	EQU ($0204)	; erase yourself
IM_MOVE		EQU ($0205)	; draw new and erase old, smoothly

IM_DRAWFRAME	EQU ($0206)	; draw with specified dimensions
IM_FRAMEBOX	EQU ($0207)	; get recommended frame around some box
IM_HITFRAME	EQU ($0208)	; hittest with dimensions
IM_ERASEFRAME	EQU ($0209)	; hittest with dimensions

* image draw states or styles, for IM_DRAW
IDS_NORMAL		EQU (0)
IDS_SELECTED		EQU (1)	; for selected gadgets
IDS_DISABLED		EQU (2)	; for disabled gadgets
IDS_BUSY		EQU (3)	; for future functionality
IDS_INDETERMINATE	EQU (4)	; for future functionality
IDS_INACTIVENORMAL	EQU (5)	; normal, in inactive window border
IDS_INACTIVESELECTED	EQU (6)	; selected, in inactive border
IDS_INACTIVEDISABLED	EQU (7)	; disabled, in inactive border

* oops, please forgive spelling error by jimm
IDS_INDETERMINANT EQU IDS_INDETERMINATE

* IM_FRAMEBOX
 STRUCTURE impFrameBox,4		; starts with ULONG MethodID
    APTR	impf_ContentsBox	; input: relative box of contents
    APTR	impf_FrameBox	; output: rel. box of encl frame
    APTR	impf_DrInfo	; NB: May be NULL
    LONG	impf_FrameFlags

; Make do with the dimensions of FrameBox provided.
FRAMEB_SPECIFY	EQU (0)
FRAMEF_SPECIFY	EQU (1)


* IM_DRAW, IM_DRAWFRAME
 STRUCTURE impDraw,4		; starts with ULONG MethodID
    APTR	impd_RPort
    WORD	impd_OffsetX
    WORD	impd_OffsetY
    ULONG	impd_State
    APTR	impd_DrInfo	; NB: May be NULL
    ; these parameters only valid for IM_DRAWFRAME
    WORD	impd_DimensionsWidth
    WORD	impd_DimensionsHeight

* IM_ERASE, IM_ERASEFRAME
* NOTE: This is a subset of impDraw
 STRUCTURE impErase,4		; starts with ULONG MethodID
    APTR	impe_RPort
    WORD	impe_OffsetX
    WORD	impe_OffsetY
    ; these parameters only valid for IM_ERASEFRAME
    WORD	impe_DimensionsWidth
    WORD	impe_DimensionsHeight

* IM_HITTEST, IM_HITFRAME
 STRUCTURE impHitTest,4		; starts with ULONG MethodID
    ; these parameters only valid for IM_ERASEFRAME
    WORD	imph_PointX
    WORD	imph_PointY
    ; these parameters only valid for IM_HITFRAME
    WORD	imph_DimensionsWidth
    WORD	imph_DimensionsHeight


* Include obsolete identifiers:
	IFND	INTUITION_IOBSOLETE_I
	INCLUDE "intuition/iobsolete.i"
	ENDC

    ENDC

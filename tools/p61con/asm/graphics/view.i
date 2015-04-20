    IFND    GRAPHICS_VIEW_I
GRAPHICS_VIEW_I SET 1
**
**	$Filename: graphics/view.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 37.0 $
**	$Date: 91/01/07 $
**
**	graphics view/viewport definitions
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

    IFND    EXEC_TYPES_I
    include 'exec/types.i'
    ENDC

    IFND    GRAPHICS_GFX_I
    include 'graphics/gfx.i'
    ENDC

    IFND    GRAPHICS_COPPER_I
    include 'graphics/copper.i'
    ENDC

    IFND    GRAPHICS_GFXNODES_I
    include 'graphics/gfxnodes.i'
    ENDC

GENLOCK_VIDEO		EQU	$2
V_LACE			EQU	$4
V_SUPERHIRES		EQU	$20
V_PFBA			EQU	$40
V_EXTRA_HALFBRITE	EQU	$80
GENLOCK_AUDIO		EQU	$100
V_DUALPF		EQU	$400
V_HAM			EQU	$800
V_EXTENDED_MODE	EQU	$1000
V_VP_HIDE		EQU	$2000
V_SPRITES		EQU	$4000
V_HIRES		EQU	$8000

EXTEND_VSTRUCT		EQU	$1000

VPF_DENISE	EQU	$80
VPF_A2024	EQU	$40
VPF_AGNUS	EQU	$20
VPF_TENHZ	EQU	$20
VPF_ILACE	EQU	$10

   STRUCTURE   ColorMap,0
	BYTE	cm_Flags
	BYTE	cm_Type
	WORD	cm_Count
	APTR	cm_ColorTable
	APTR	cm_vpe
	APTR	cm_TransparencyBits
	BYTE	cm_TransparenyPlane
	BYTE	cm_reserved1
	WORD	cm_reserved2
	APTR	cm_vp
	APTR	cm_NormalDisplayInfo
	APTR	cm_CoerceDisplayInfo
	APTR	cm_batch_items
	LONG	cm_VPModeID
   LABEL cm_SIZEOF

COLORMAP_TYPE_V1_2	EQU	$00
COLORMAP_TYPE_V1_4	EQU	$01
COLORMAP_TYPE_V36 EQU COLORMAP_TYPE_V1_4	; use this definition

COLORMAP_TRANSPARENCY	EQU	$01
COLORPLANE_TRANSPARENCY EQU	$02
BORDER_BLANKING		EQU	$04
BORDER_NOTRANSPARENCY	EQU	$08
VIDEOCONTROL_BATCH	EQU	$10
USER_COPPER_CLIP	EQU	$20

   STRUCTURE	  ViewPort,0
   LONG    vp_Next
   LONG    vp_ColorMap
   LONG    vp_DspIns
   LONG    vp_SprIns
   LONG    vp_ClrIns
   LONG    vp_UCopIns
   WORD    vp_DWidth
   WORD    vp_DHeight
   WORD    vp_DxOffset
   WORD    vp_DyOffset
   WORD    vp_Modes
   BYTE    vp_SpritePriorities
   BYTE    vp_ExtendedModes
   APTR    vp_RasInfo
   LABEL   vp_SIZEOF


   STRUCTURE View,0
   LONG    v_ViewPort
   LONG    v_LOFCprList
   LONG    v_SHFCprList
   WORD    v_DyOffset
   WORD    v_DxOffset
   WORD    v_Modes
   LABEL   v_SIZEOF


   STRUCTURE ViewExtra,XLN_SIZE
   APTR    ve_View
   APTR    ve_Monitor
   LABEL   ve_SIZEOF


   STRUCTURE ViewPortExtra,XLN_SIZE
   APTR    vpe_ViewPort
   STRUCT  vpe_DisplayClip,ra_SIZEOF
   LABEL   vpe_SIZEOF


   STRUCTURE  collTable,0
   LONG    cp_collPtrs,16
   LABEL   cp_SIZEOF


   STRUCTURE  RasInfo,0
   APTR    ri_Next
   LONG    ri_BitMap
   WORD    ri_RxOffset
   WORD    ri_RyOffset
   LABEL   ri_SIZEOF

	ENDC	; GRAPHICS_VIEW_I

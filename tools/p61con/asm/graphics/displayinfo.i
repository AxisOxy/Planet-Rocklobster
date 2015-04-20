	IFND	GRAPHICS_DISPLAYINFO_I
GRAPHICS_DISPLAYINFO_I	SET	1
**
**	$Filename: graphics/displayinfo.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 37.7 $
**	$Date: 91/11/08 $
**
**	include define file for display control registers
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

    IFND	EXEC_TYPES_I
    include 'exec/types.i'
    ENDC

    IFND	GRAPHICS_GFX_I
    include 'graphics/gfx.i'
    ENDC

    IFND	GRAPHICS_MONITOR_I
    include 'graphics/monitor.i'
    ENDC

    IFND	UTILITY_TAGITEM_I
    include 'utility/tagitem.i'
    ENDC

* datachunk type identifiers

DTAG_DISP	equ		  $80000000
DTAG_DIMS	equ		  $80001000
DTAG_MNTR	equ		  $80002000
DTAG_NAME	equ		  $80003000


    STRUCTURE	QueryHeader,0
	ULONG	qh_StructID	; datachunk type identifier
	ULONG	qh_DisplayID	; copy of display record key
	ULONG	qh_SkipID	; TAG_SKIP -- see tagitems.h
	ULONG	qh_Length	; length of data in double-longwords
    LABEL qh_SIZEOF

    STRUCTURE	DisplayInfo,qh_SIZEOF
	UWORD	dis_NotAvailable	  ; if NULL available, else see defines
	ULONG	dis_PropertyFlags	  ; Properties of this mode see defines
	STRUCT	dis_Resolution,tpt_SIZEOF ; ticks-per-pixel X/Y
	UWORD	dis_PixelSpeed		  ; aproximation in nanoseconds
	UWORD	dis_NumStdSprites	  ; number of standard amiga sprites
	UWORD	dis_PaletteRange	  ; distinguishable shades available
	STRUCT	dis_SpriteResolution,tpt_SIZEOF ; sprite ticks-per-pixel X/Y
	STRUCT	dis_pad,4
	STRUCT	dis_reserved,8		  ; terminator
    LABEL dis_SIZEOF

* availability

DI_AVAIL_NOCHIPS	equ	$0001
DI_AVAIL_NOMONITOR	equ	$0002
DI_AVAIL_NOTWITHGENLOCK	equ	$0004

* mode properties

DIPF_IS_LACE		equ	$00000001
DIPF_IS_DUALPF		equ	$00000002
DIPF_IS_PF2PRI		equ	$00000004
DIPF_IS_HAM		equ	$00000008

DIPF_IS_ECS		equ	$00000010	;*	note: ECS modes (SHIRES, VGA, and **
*								;*	PRODUCTIVITY) do not support	  **
*								;*	attached sprites.		  **
DIPF_IS_PAL		equ	$00000020
DIPF_IS_SPRITES		equ	$00000040
DIPF_IS_GENLOCK		equ	$00000080

DIPF_IS_WB		equ	$00000100
DIPF_IS_DRAGGABLE	equ	$00000200
DIPF_IS_PANELLED	equ	$00000400
DIPF_IS_BEAMSYNC	equ	$00000800

DIPF_IS_EXTRAHALFBRITE equ	$00001000

    STRUCTURE DimensionInfo,qh_SIZEOF
	UWORD	dim_MaxDepth		; log2( max number of colors
	UWORD	dim_MinRasterWidth	; minimum width in pixels
	UWORD	dim_MinRasterHeight	; minimum height in pixels
	UWORD	dim_MaxRasterWidth	; maximum width in pixels
	UWORD	dim_MaxRasterHeight	; maximum height in pixels
	STRUCT	dim_Nominal,ra_SIZEOF	; "standard" dimensions
	STRUCT	dim_MaxOScan,ra_SIZEOF	; fixed, hardware dependant
	STRUCT	dim_VideoOScan,ra_SIZEOF ; fixed, hardware dependant
	STRUCT	dim_TxtOScan,ra_SIZEOF	; editable via preferences
	STRUCT	dim_StdOScan,ra_SIZEOF	; editable via preferences
	STRUCT	dim_pad,14
	STRUCT	dim_reserved,8		; terminator
    LABEL dim_SIZEOF

    STRUCTURE MonitorInfo,qh_SIZEOF
	APTR	mtr_Mspc		; pointer to monitor specification
	STRUCT	mtr_ViewPosition,tpt_SIZEOF	; editable via preferences
	STRUCT	mtr_ViewResolution,tpt_SIZEOF	; monitor ticks-per-pixel
	STRUCT	mtr_ViewPositionRange,ra_SIZEOF	; fixed, hardware dependant
	UWORD	mtr_TotalRows		; display height in scanlines
	UWORD	mtr_TotalColorClocks	; scanline width in 280 ns units
	UWORD	mtr_MinRow		; absolute minimum active scanline
	WORD	mtr_Compatibility	; how this coexists with others
	STRUCT	mtr_pad,36
	STRUCT	mtr_DefaultViewPosition,tpt_SIZEOF	; original, never changes
	ULONG	mtr_PreferredModeID				; for preferences
	STRUCT	mtr_reserved,8		; terminator
    LABEL mtr_SIZEOF

* monitor compatibility

MCOMPAT_MIXED		equ  0	; can share display with other MCOMPAT_MIXED
MCOMPAT_SELF		equ  1	; can share only within same monitor
MCOMPAT_NOBODY		equ -1	; only one viewport at a time

DISPLAYNAMELEN		equ 32

    STRUCTURE NameInfo,qh_SIZEOF
	STRUCT	nif_Name,DISPLAYNAMELEN
	STRUCT	nif_reserved,8		; terminator
    LABEL nif_SIZEOF

* DisplayInfoRecord identifiers

INVALID_ID		equ	-1

*normal identifiers

MONITOR_ID_MASK		equ	$FFFF1000

DEFAULT_MONITOR_ID	equ	$00000000
NTSC_MONITOR_ID		equ	$00011000
PAL_MONITOR_ID		equ	$00021000

* the following 20 composite keys are for Modes on the default Monitor
* ntsc & pal "flavors" of these particular keys may be made by or'ing
* the ntsc or pal MONITOR_ID with the desired MODE_KEY...

LORES_KEY		equ	$00000000 
HIRES_KEY		equ	$00008000 
SUPER_KEY		equ	$00008020 
HAM_KEY			equ	$00000800 
LORESLACE_KEY		equ	$00000004 
HIRESLACE_KEY		equ	$00008004 
SUPERLACE_KEY		equ	$00008024 
HAMLACE_KEY		equ	$00000804 
LORESDPF_KEY		equ	$00000400 
HIRESDPF_KEY		equ	$00008400 
SUPERDPF_KEY		equ	$00008420 
LORESLACEDPF_KEY	equ	$00000404 
HIRESLACEDPF_KEY	equ	$00008404 
SUPERLACEDPF_KEY	equ	$00008424 
LORESDPF2_KEY		equ	$00000440 
HIRESDPF2_KEY		equ	$00008440 
SUPERDPF2_KEY		equ	$00008460 
LORESLACEDPF2_KEY	equ	$00000444 
HIRESLACEDPF2_KEY	equ	$00008444 
SUPERLACEDPF2_KEY	equ	$00008464 
EXTRAHALFBRITE_KEY	equ	$00000080
EXTRAHALFBRITELACE_KEY	equ	$00000084

* vga identifiers

VGA_MONITOR_ID		equ	$00031000 

VGAEXTRALORES_KEY	equ	$00031004 
VGALORES_KEY		equ	$00039004 
VGAPRODUCT_KEY 		equ	$00039024 
VGAHAM_KEY		equ	$00031804 
VGAEXTRALORESLACE_KEY	equ	$00031005 
VGALORESLACE_KEY	equ	$00039005 
VGAPRODUCTLACE_KEY	equ	$00039025 
VGAHAMLACE_KEY		equ	$00031805 
VGAEXTRALORESDPF_KEY	equ	$00031404 
VGALORESDPF_KEY		equ	$00039404 
VGAPRODUCTDPF_KEY	equ	$00039424 
VGAEXTRALORESLACEDPF_KEY equ	$00031405 
VGALORESLACEDPF_KEY	equ	$00039405 
VGAPRODUCTLACEDPF_KEY	equ	$00039425 
VGAEXTRALORESDPF2_KEY	equ	$00031444 
VGALORESDPF2_KEY	equ	$00039444 
VGAPRODUCTDPF2_KEY	equ	$00039464 
VGAEXTRALORESLACEDPF2_KEY equ	$00031445 
VGALORESLACEDPF2_KEY	equ	$00039445 
VGAPRODUCTLACEDPF2_KEY	equ	$00039465 
VGAEXTRAHALFBRITE_KEY	equ	$00031084
VGAEXTRAHALFBRITELACE_KEY equ	$00031085

* a2024 identifiers

A2024_MONITOR_ID	equ	$00041000 

A2024TENHERTZ_KEY 	equ	$00041000 
A2024FIFTEENHERTZ_KEY   equ	$00049000 

* prototype identifiers

PROTO_MONITOR_ID	equ	$00051000 

    ENDC	; GRAPHICS_DISPLAYINFO_I 

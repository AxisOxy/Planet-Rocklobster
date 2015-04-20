    IFND    GRAPHICS_GFXBASE_I
GRAPHICS_GFXBASE_I  SET 1
**
**	$Filename: graphics/gfxbase.i $
**	$Release: 2.04 Includes, V37.4 $
**	$Revision: 37.3 $
**	$Date: 91/04/15 $
**
**	graphics base definitions
**
**	(C) Copyright 1985-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

    IFND    EXEC_LISTS_I
    include 'exec/lists.i'
    ENDC
    IFND    EXEC_LIBRARIES_I
    include 'exec/libraries.i'
    ENDC
    IFND    EXEC_INTERRUPTS_I
    include 'exec/interrupts.i'
    ENDC

 STRUCTURE  GfxBase,LIB_SIZE
    APTR    gb_ActiView     ; struct *View
    APTR    gb_copinit	    ; struct *copinit; ptr to copper start up list
    APTR    gb_cia	; for 6526 resource use
    APTR    gb_blitter	    ; for blitter resource use
    APTR    gb_LOFlist	    ; current copper list being run
    APTR    gb_SHFlist	    ; current copper list being run
    APTR    gb_blthd	    ; struct *bltnode
    APTR    gb_blttl	    ;
    APTR    gb_bsblthd	    ;
    APTR    gb_bsblttl	    ;
    STRUCT  gb_vbsrv,IS_SIZE
    STRUCT  gb_timsrv,IS_SIZE
    STRUCT  gb_bltsrv,IS_SIZE
    STRUCT  gb_TextFonts,LH_SIZE
    APTR    gb_DefaultFont
    UWORD   gb_Modes	    ; copy of bltcon0
    BYTE    gb_VBlank
    BYTE    gb_Debug
    UWORD   gb_BeamSync
    WORD    gb_system_bplcon0
    BYTE    gb_SpriteReserved
    BYTE    gb_bytereserved

    WORD    gb_Flags
    WORD    gb_BlitLock
	WORD	gb_BlitNest
	STRUCT	gb_BlitWaitQ,LH_SIZE
	APTR	gb_BlitOwner
	STRUCT	gb_TOF_WaitQ,LH_SIZE

	WORD	gb_DisplayFlags
	APTR	gb_SimpleSprites
	WORD	gb_MaxDisplayRow
	WORD	gb_MaxDisplayColumn
	WORD	gb_NormalDisplayRows
	WORD	gb_NormalDisplayColumns
	WORD	gb_NormalDPMX
	WORD	gb_NormalDPMY

	APTR	gb_LastChanceMemory
	APTR	gb_LCMptr

	WORD	gb_MicrosPerLine	; usecs per line times 256
	WORD	gb_MinDisplayColumn

	UBYTE	gb_ChipRevBits0		; agnus/denise new features
	STRUCT	gb_crb_reserved,5

	STRUCT	gb_monitor_id,2	; normally null
	STRUCT	gb_hedley,4*8
	STRUCT	gb_hedley_sprites,4*8
	STRUCT	gb_hedley_sprites1,4*8
	WORD	gb_hedley_count
	WORD	gb_hedley_flags
	WORD	gb_hedley_tmp
	APTR	gb_hash_table
	UWORD	gb_current_tot_rows
	UWORD	gb_current_tot_cclks
	UBYTE	gb_hedley_hint
	UBYTE	gb_hedley_hint2
	STRUCT	gb_nreserved,4*4
	APTR	gb_a2024_sync_raster
	WORD	gb_control_delta_pal
	WORD	gb_control_delta_ntsc
	APTR	gb_current_monitor
	STRUCT	gb_MonitorList,LH_SIZE
	APTR	gb_default_monitor
	APTR	gb_MonitorListSemaphore
	APTR	gb_DisplayInfoDataBase
	WORD	lapad;					; alignment
	APTR	gb_ActiViewCprSemaphore
	APTR	gb_UtilityBase
	APTR	gb_ExecBase
    LABEL   gb_SIZE

* bits for dalestuff, which may go away when blitter becomes a resource
OWNBLITTERn equ 0   * blitter owned bit
QBOWNERn    equ 1   * blitter owned by blit queuer

* flag bits for ChipRevBits
	BITDEF	GFX,BIG_BLITS,0
	BITDEF	GFX,HR_AGNUS,0
	BITDEF	GFX,HR_DENISE,1


QBOWNER     equ 1<<QBOWNERn

* flag bits for DisplayFlags

NTSCn		equ 0
NTSC		equ 1<<NTSCn

GENLOCn		equ 1
GENLOC		equ 1<<GENLOCn

PALn		equ 2
PAL		equ 1<<PALn

TODA_SAFEn	equ 3
TODA_SAFE	equ 1<<TODA_SAFEn

BLITMSG_FAULTn	equ 2
BLITMSG_FAULT	equ 1<<BLITMSG_FAULTn

* handy name macro

GRAPHICSNAME	MACRO
		DC.B  'graphics.library',0
		ENDM

    ENDC	; GRAPHICS_GFXBASE_I

	IFND	XPK_XPKPREFS_I
XPK_XPKPREFS_I	SET	1

**
**	$VER: xpk/xpkprefs.i 4.14 (03.06.1998) by SDI
**
**	(C) Copyright 1997-1998 by Dirk Stöcker
**	    All Rights Reserved
**

	IFND	EXEC_SEMAPHORES_I
	INCLUDE "exec/semaphores.i"
	ENDC
	
	IFND	LIBRARIES_IFFPARSE_I
	INCLUDE "libraries/iffparse.i"
	ENDC

ID_XPKT 	EQU	'XPKT'
ID_XPKM 	EQU	'XPKM'

*****************************************************************************
*
*
*     XpkTypeData structure
*
*

XTD_NoPack	EQU	$0001 ; filetype should not be crunched
XTD_ReturnError	EQU	$0002 ; return error XPKERR_NOMETHOD
* These two cannot be set same time!

   STRUCTURE XpkTypeData,0
	ULONG	xtd_Flags	; see above XTD flags
	ULONG   xtd_StdID	; holding the ID --> 'NUKE'
	ULONG	xtd_ChunkSize	; maybe useless with external crunchers
	UWORD	xtd_Mode	; PackMode
	UWORD   xtd_Version	; structure version --> 0 at the moment
	APTR	xtd_Password	; not used at the moment
	APTR	xtd_Memory	; memory pointer - when should be freed by
	ULONG	xtd_MemorySize	; memory size    - receiver (xpkmaster)
	LABEL	XpkTypeData_SIZEOF

******************************************************************************
*
*
*     XpkTypePrefs structure
*
*

XPKT_NamePattern	EQU	$0001 ; File Pattern is given
XPKT_FilePattern	EQU	$0002 ; Name Pattern is given
* These can both be set (in loading this means File AND Name Pattern have
* to match), but one is needed

   STRUCTURE XpkTypePrefs,0
	ULONG	xtp_Flags	; See above XPKT Flags
	APTR 	xtp_TypeName	; Name of this file type (for prefs program)
	APTR 	xtp_NamePattern ; Pointer to NamePattern
	APTR 	xtp_FilePattern ; Pointer to FilePattern
	ULONG   xtp_PackerData  ; Pointer to PackerData
	LABEL	XpkTypePrefs_SIZEOF

*****************************************************************************
*
*
*     XpkMainPrefs structure
*
*

XPKM_UseXFD		EQU	$0001 ; Use xfdmaster.library for unpacking
XPKM_UseExternals	EQU	$0002 ; Use xex libraries
XPKM_AutoPassword	EQU	$0004 ; Use the automatic password requester

    STRUCTURE XpkMainPrefs,0
	ULONG	xmp_Version	; version of structure ==> 0
	ULONG	xmp_Flags	; above defined XPKM flags
	APTR	xmp_DefaultType ; sets the mode used as default (struct XpkTypeData *)
	UWORD	xmp_Timeout	; Timeout for password requester
				; given in seconds, zero means no timeout
	LABEL	XpkMainPrefs_SIZEOF

* The library internal defaults are:
*  XPKM_UseXFD			FALSE
*  XPKM_AutoPassword		FALSE
*  XPKM_UseExternals		TRUE
*  XTD_ReturnError		defined as default
*  xmp_TimeOut			set to 120	(two minutes)
*
* These defaults are used, when no preferences file is given.

*****************************************************************************
*
*
*     XpkMasterPrefs Semaphore structure
*
*  find with FindSemaphore(XPKPREFSSEMNAME);
*
*  obtain with ObtainSemaphoreShared(),
*  programs WRITING into the structure fields must know:
*   - only write to them, when you created the semaphore
*   - use ObtainSemaphore() instead of ObtainSemaphoreShared()
*

XPKPREFSSEMNAME	MACRO
		DC.B '« XpkMasterPrefs »',0
		ENDM

* Defines used for xps_PrefsType. These help to find out, which preferences
* type is used.

XPREFSTYPE_STANDARD	EQU	$58504B4D	; 'XPKM'
XPREFSTYPE_CYB		EQU	$20435942	; ' CYB'

    STRUCTURE XpkPrefsSemaphore,0
	STRUCT	xps_Semaphore,SS_SIZE
	ULONG	xps_Version	; at the moment 0
	ULONG	xps_PrefsType	; preferences type
	APTR	xps_PrefsData	; preferences data
	APTR	xps_MainPrefs	; defined defaults (struct XpkMainPrefs *)
	ULONG	xps_RecogSize	; needed size of Recogbuffer
	APTR	xps_RecogFunc	; Recog function
	APTR	xps_ProgressHook; hook function
	APTR	xps_MasterTask  ; Creater's task
	LABEL	XpkPrefsSemaphore_SIZEOF

* Use Signal(sem->xps_MasterTask, SIGBREAKF_CTRL_C); to get the installer
* program to remove the semaphore.

	ENDC

    IFND INTUITION_CGHOOKS_I
INTUITION_CGHOOKS_I SET 1
**
** $Filename: intuition/cghooks.i $
** $Release: 2.04 Includes, V37.4 $
** $Revision: 36.4 $
** $Date: 91/11/08 $
**
**  Custom gadget processing
**
**  (C) Copyright 1988-1991 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

    IFND EXEC_TYPES_I
    INCLUDE "exec/types.i"
    ENDC

    IFND INTUITION_INTUITION_I
    INCLUDE "intuition/intuition.i"
    ENDC

; ========================================================================
; === Gadget Info =========================================================
; ========================================================================

; Package of information passed to custom and 'boopsi'
; gadget "hook" functions.  This structure is READ ONLY.

 STRUCTURE GadgetInfo,0
;    APTR ggi_Gadget

    APTR ggi_Screen
    APTR ggi_Window	 ; null for screen gadgets
    APTR ggi_Requester	 ; null if not GTYP_REQGADGET

    ; rendering information:
    ; don't use these without cloning/locking.
    ; Official way is to call ObtainRPort()
    APTR ggi_RastPort
    APTR ggi_Layer

    ; copy of dimensions of screen/window/g00/req/group
    ; that gadget resides in.  Left/Top of this box is
    ; offset from window mouse coordinates to gadget coordinates
    ; 	screen gadgets:			0,0 (from screen coords)
    ;	window gadgets (no g00):  	0,0
    ;  GZZGADGETs (borderlayer): 	0,0
    ;  GZZ innerlayer gadget:  	borderleft, bordertop
    ;  Requester gadgets: 		reqleft, reqtop
    STRUCT 	ggi_Domain,ibox_SIZEOF

    ; these are the pens for the window or screen
    STRUCT	ggi_Pens,2	; detail and block pen UBYTE's

    ; the Detail and Block pens in ggi_DrInfo->dri_Pens[] are
    ; for the screen. Use the above for window-sensitive
    ; colors.
    APTR ggi_DrInfo

    ; the size of this struct is not defined, since it is allocated
    ; ONLY by Intuition.
    ;	 LABEL ggi_SIZEOF


    ENDC

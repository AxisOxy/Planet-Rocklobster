	IFND	XPK_XPKSUB_I
XPK_XPKSUB_I	SET	1

**
**	$VER: xpk/xpksub.i 4.10 (03.06.1998) by SDI
**
**	(C) Copyright 1991-1998 by 
**          Urban Dominik Mueller, Bryan Ford,
**          Christian Schneider, Christian von Roques,
**	    Dirk Stöcker
**	    All Rights Reserved
**

	IFND	XPK_XPK_I
	INCLUDE "xpk/xpk.i"
	ENDC

**************************************************************************
*
*        Sublibs return this structure to xpkmaster when asked nicely
*
*

 STRUCTURE XpkInfo,0
	UWORD	xi_XpkInfoVersion ; /* Version number of this structure   */
	UWORD	xi_LibVersion	  ; /* The version of this sublibrary     */
	UWORD	xi_MasterVersion  ; /* The required master lib version    */
	UWORD	xi_ModesVersion	; /* Longword align                     */
	APTR	xi_Name		; /* Brief name of the packer           */
	APTR	xi_LongName	; /* Full name of the packer            */
	APTR	xi_Description	; /* One line description of packer     */
	LONG	xi_ID		; /* ID the packer goes by (XPK format) */
	LONG	xi_Flags	; /* Defined below                      */
	LONG	xi_MaxPkInChunk	; /* Max input chunk size for packing   */
	LONG	xi_MinPkInChunk	; /* Min input chunk size for packing   */
	LONG	xi_DefPkInChunk	; /* Default packing chunk size         */
	APTR	xi_PackMsg	; /* Packing message, present tense     */
	APTR	xi_UnpackMsg	; /* Unpacking message, present tense   */
	APTR	xi_PackedMsg	; /* Packing message, past tense        */
	APTR	xi_UnpackedMsg	; /* Unpacking message, past tense      */
	UWORD	xi_DefMode	; /* Default mode number                */
	UWORD	xi_Pad		; /* for future use                     */
	APTR	xi_Modes	; /* Array of compression modes         */
	STRUCT	xi_Reserved,6*4	; /* Future expansion - set to zero     */
	LABEL	xi_SIZEOF	; /* Size of the *first* part only	*/

* Defines for XpkInfo.Flags: see xpk.i, XPKIF_xxxxx

**************************************************************************
*
*                     The XpkSubParams structure
*
*/

 STRUCTURE XpkSubParams,0
	APTR	xsp_InBuf	; /* The input data               */
	ULONG	xsp_InLen	; /* The number of bytes to pack  */
	APTR	xsp_OutBuf	; /* The output buffer            */
	ULONG	xsp_OutBufLen	; /* The length of the output buf */
	ULONG	xsp_OutLen	; /* Number of bytes written      */
	ULONG	xsp_Flags	; /* Flags for master/sub comm.   */
	ULONG	xsp_Number	; /* The number of this chunk     */
	LONG	xsp_Mode	; /* The packing mode to use      */
	APTR	xsp_Password	; /* The password to use          */
	UWORD	xsp_LibVersion	; /* SublibVersion used to pack   */
	UWORD	xsp_Pad		; /* Reserved; don't use          */
	STRUCT	xsp_Arg,3*4	; /* Reserved; don't use          */
	STRUCT	xsp_Sub,4*4	; /* Sublib private data          */
	LABEL	xsp_SIZEOF


* xsp_LibVersion is the version number of the sublibrary used to pack
* this chunk. It can be used to create backwards compatible sublibraries
* with a totally different fileformat.

XSF_STEPDOWN	EQU	1	; /* May reduce pack eff. to save mem   */
XSF_PREVCHUNK	EQU	2	; /* Previous chunk available on unpack */

	ENDC

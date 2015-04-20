	IFND LIBRARIES_COMMODITIES_I
LIBRARIES_COMMODITIES_I	SET 1
**   $Filename: libraries/commodities.i $
**   $Release: 2.04 Includes, V37.4 $
**   $Revision: 37.0 $
**   $Date: 91/04/15 $
**
**   Commodities definitions
**
**   (C) Copyright 1988-1991 Commodore-Amiga Inc.
**	All Rights Reserved
*-----------------------------------------------------------*

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"

	ENDC
	IFND DEVICES_INPUTEVENT_I
	INCLUDE "devices/inputevent.i"
	ENDC


***************
* Broker stuff
***************

* buffer sizes
CBD_NAMELEN	EQU	24
CBD_TITLELEN	EQU	40
CBD_DESCRLEN	EQU	40

* CxBroker errors
CBERR_OK	EQU	0	 ; No error
CBERR_SYSERR	EQU	1	 ; System error , no memory, etc
CBERR_DUP	EQU	2	 ; uniqueness violation
CBERR_VERSION	EQU	3	 ; didn't understand nb_VERSION
NB_VERSION 	EQU	5        ; Version of NewBroker structure

	STRUCTURE NewBroker,0
	   BYTE     	nb_Version         ; set to NB_VERSION
	   BYTE		nb_Reserve1	; for alignment
	   APTR     	nb_Name
	   APTR     	nb_Title
	   APTR     	nb_Descr
	   WORD    	nb_Unique
	   WORD		nb_Flags
	   BYTE 	nb_Pri
	   BYTE		nb_Reserve2	; for alignment
	   APTR		nb_Port
	   WORD     	nb_ReservedChannel 	;plans for later port sharing

***********************
* Flags for nb_Unique
***********************

NBU_DUPLICATE 	EQU	   0
NBU_UNIQUE 	EQU	   1        ; will not allow duplicates
NBU_NOTIFY 	EQU	   2        ; sends CXM_UNIQUE to existing broker

* Flags for nb_Flags
COF_SHOW_HIDE 	EQU	   4

********
* cxusr
********

********************************
** Commodities Object Types   **
********************************
CX_INVALID 	EQU	0     ; not a valid object (probably null)
CX_FILTER 	EQU	1     ; input event messages only
CX_TYPEFILTER 	EQU	2     ; filter on message type
CX_SEND 	EQU	3     ; sends a message
CX_SIGNAL 	EQU	4     ; sends a signal
CX_TRANSLATE 	EQU	5     ; translates IE into chain
CX_BROKER 	EQU	6     ; application representative
CX_DEBUG 	EQU	7     ; dumps kprintf to serial port
CX_CUSTOM 	EQU	8     ; application provids function
CX_ZERO 	EQU	9     ; system terminator node

*****************
** CxMsg types **
*****************
CXM_UNIQUE 	EQU	   $10 ; (1 << 4) sent down broker by CxBroker()
; Obsolete: subsumed by CXM_COMMAND (below)

* Messages of this type rattle around the Commodities input network.
* They will be sent to you by a Sender object, and passed to you
* as a synchronous function call by a Custom object.
*
* The message port or function entry point is stored in the object,
* and the ID field of the message will be set to what you arrange
* issuing object.
*
* The Data field will point to the input event triggering the
* message.

CXM_IEVENT 	EQU	   $20 ;(1 << 5)

* These messages are sent to a port attached to your Broker.
* They are sent to you when the controller program wants your
* program to do something.  The ID field identifies the command.
*
* The Data field will be used later.
*

CXM_COMMAND 	EQU	   $40 ;(1 << 6)

* ID values

CXCMD_DISABLE 	EQU	15  ; please disable yourself
CXCMD_ENABLE 	EQU	17  ; please enable yourself
CXCMD_APPEAR 	EQU	19  ; open your window, if you can
CXCMD_DISAPPEAR EQU	21  ; go dormant
CXCMD_KILL 	EQU	23  ; go away for good
CXCMD_UNIQUE 	EQU	25  ; someone tried to create a brok
                            ; with your name.  Suggest you Appear.
CXCMD_LIST_CHG 	EQU	27  ; Used by Exchange program. Someone
                            ; has changed the broker list

* return values for BrokerCommand()
CMDE_OK 	EQU        0
CMDE_NOBROKER 	EQU	  -1
CMDE_NOPORT 	EQU	  -2
CMDE_NOMEM 	EQU	  -3

* IMPORTANT NOTE:
* Only CXM_IEVENT messages are passed through the input network.
*
* Other types of messages are sent to an optional port in your broker.
*
* This means that you must test the message type in your message handling,
* if input messages and command messages come to the same port.
*
* Older programs have no broker port, so processing loops which
* make assumptions about type won't encounter the new message types.
*
* The TypeFilter CxObject is hereby obsolete.
*
* It is less convenient for the application, but eliminates testing
* for type of input messages.

**********************************************************
** CxObj Error Flags (return values from CxObjError())	**
**********************************************************

COERR_ISNULL		EQU	1  ; you called CxError(NULL)
COERR_NULLATTACH	EQU	2  ; someone attached NULL to my list
COERR_BADFILTER	EQU	4  ; a bad filter description was given
COERR_BADTYPE		EQU	8  ; unmatched type-specific operation


******************************
* Input Expression structure *
******************************

IX_VERSION	EQU	   2

	STRUCTURE InputXpression,0

	   UBYTE   ix_Version	   ; must be set to IX_VERSION
	   UBYTE   ix_Class	   ; class must match exactly

	   UWORD   ix_Code	   ; Bits that we want

	   UWORD   ix_CodeMask	   ; Set bits here to indicate
				   ; which bits in ix_Code are
				   ; don't care bits.

	   UWORD   ix_Qualifier    ; Bits that we want

	   UWORD   ix_QualMask     ; Set bits here to indicate
        	                   ; which bits in ix_Qualifier
				   ; are don't care bits

	   UWORD   ix_QualSame	  ; synonyms in qualifier

	LABEL	ix_SIZEOF

* QualSame identifiers
IXSYM_SHIFT	EQU	  1	; left- and right- shift are equivalent
IXSYM_CAPS	EQU	  2	; either shift or caps lock are equivalent
IXSYM_ALT	EQU	  4	; left- and right- alt are equivalent

* corresponding QualSame masks
IXSYM_SHIFTMASK EQU	 IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT
IXSYM_CAPSMASK		EQU	 IXSYM_SHIFTMASK!IEQUALIFIER_CAPSLOCK
IXSYM_ALTMASK	EQU	 IEQUALIFIER_LALT!IEQUALIFIER_RALT

IX_NORMALQUALS		EQU	  $7FFF  ;for QualMask field: avoid RELATIVEMOUSE

	ENDC	; LIBRARIES_COMMODITIES_I

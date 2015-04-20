_LVOAddConfigDev	EQU	-30
_LVOAddBootNode	EQU	-36
_LVOAllocBoardMem	EQU	-42
_LVOAllocConfigDev	EQU	-48
_LVOAllocExpansionMem	EQU	-54
_LVOConfigBoard	EQU	-60
_LVOConfigChain	EQU	-66
_LVOFindConfigDev	EQU	-72
_LVOFreeBoardMem	EQU	-78
_LVOFreeConfigDev	EQU	-84
_LVOFreeExpansionMem	EQU	-90
_LVOReadExpansionByte	EQU	-96
_LVOReadExpansionRom	EQU	-102
_LVORemConfigDev	EQU	-108
_LVOWriteExpansionByte	EQU	-114
_LVOObtainConfigBinding	EQU	-120
_LVOReleaseConfigBinding	EQU	-126
_LVOSetCurrentBinding	EQU	-132
_LVOGetCurrentBinding	EQU	-138
_LVOMakeDosNode	EQU	-144
_LVOAddDosNode	EQU	-150

CALLEXP	MACRO
	move.l	_ExpansionBase,a6
	jsr	_LVO\1(a6)
	ENDM

STAR

;macro to signal debug states and errors with screencolors
 MACRO<OXYDEBUG>
.bl0\@:	
	btst	#$0e,$dff002
	bne.b	.bl0\@
	
	move.w	#$7fff,$dff09a
	move.w	#$7fff,$dff09c
	move.w	#$7fff,$dff096
	move.w	#$7fff,$dff09e
	move.w	#\1,$dff180
.xx\@:
	bra.b	.xx\@
 ENDM
 
;debug colors
DEBUGCOL_MOD_BROKEN	= $f00	;red: file is not a valid mod-file
DEBUGCOL_CANT_WRITE	= $0f0	;green: cant open/write the output file (write-protection, disk-full, ...)
DEBUGCOL_CANT_FINISH= $00f	;blue: cant open/write the finish signal file (write-protection, disk-full, ...)
DEBUGCOL_CONV_OK	= $fff	;white: conversion is finished, everything is fine


use = -1

	incdir	asm:include/

	include	Guru.i

	include	libraries/dos.i
	include	libraries/dosextens.i
	include	intuition/intuition.i
	include exec/memory.i

	include	libraries/reqtools.i
	include	libraries/xpk.i
	include	libraries/ppbase.i
	
	include	exec/exec_lib.i
	include	libraries/dos_lib.i
	include	graphics/graphics_lib.i
	include	intuition/intuition_lib.i
	include	libraries/reqtools_lib.i
	include	libraries/Powerpacker_lib.i
	include	workbench/startup.i

	include Player61.i

	jmp CreateProc
	
VERS	macro
	dc.b	'610.2 / 22.05.1995'
	endm

VER 	macro
	dc.b	'Version '
	VERS
	dc.b	10,10
	endm


	SECTION	detach,CODE
;ญญญญญญญญญญญญญญญญญญญญญญญญญญญญ
;ญ  Player 6.1A Converter   ญ
;ญ	 Version 610.2	    ญ
;ญ ฉ 1992-95 Jarno Paananen ญ
;ญญญญญญญญญญญญญญญญญญญญญญญญญญญญ

fromasmone = 0
decode	= 0
release = 0

	BaseReg	sa,a5
	;endb	a3

;; DETACH
CreateProc
	Push	All

	lea	sa,a5

	Push	d0/a0
	sub.l	a1,a1
	CLIB	Exec,FindTask
	move.l	d0,a4

	moveq	#0,d7
	ifeq	fromasmone
	tst.l   $ac(a4)
	bne.b	cli

	lea	$5c(a4),a0
	CALL	WaitPort

	lea	$5c(a4),a0
	CALL	GetMsg
	move.l	d0,d7

cli	endc

	lea	_DOSName(pc),a1
	moveq	#0,d0
	CALL	OpenLibrary
	move.l	d0,_DOSBase(a5)

	tst.l	d7
	bne.b	eipara

	ifeq	fromasmone
	move.l	pr_CurrentDir(a4),d1
	beq.b	.oji
	C5LIB	DOS,DupLock
	move.l	d0,Lock(a5)
	endc
.oji	Pull	d0/a0

	ifne	fromasmone
	bra	ohion
	endc

;; Commandline parser

	clr.b	-1(a0,d0.l)
	tst.b	(a0)
	beq	ohion

	st	para(a5)

	cmp.b	#'?',(a0)
	bne.b	eiinfoa
	lea	info(pc),a0
	move.l	a0,d2
	moveq	#_DOSName-info-1,d3
	bra	printa
eiinfoa
	move.l	a0,a1
locase	move.b	(a1)+,d0
	beq.b	ohigus
	cmp.b	#'A',d0
	blo.b	locase
	cmp.b	#'Z',d0
	bhi.b	locase
	add.b	#'a'-'A',-1(a1)
	bra.b	locase

ohigus	cmp.b	#'-',(a0)
	bne.b	eioptioita
	cmp.b	#'q',1(a0)
	bne.b	eioptioita
	st	quiet(a5)
	addq.l	#2,a0
eioptioita
	cmp.b	#' ',(a0)+
	beq.b	eioptioita
	subq.l	#1,a0
	bra.b	ohituska

eipara	addq.l	#8,sp
	move.l	d7,a2

	cmp	#1,sm_NumArgs+2(a2)
	ble.b	ohion
	move.l	sm_ArgList(a2),a2
	addq.l	#wa_SIZEOF,a2

	move.l	(a2),d1
	beq.b	ohion
	C5LIB	DOS,DupLock
	move.l	d0,Lock(a5)

	move.l	wa_Name(a2),a0
	st	para(a5)
ohituska
	lea	fname2,a1
.copy	move.b	(a0)+,(a1)+
	bne.b	.copy

	jmp AxisHackedConvert
	
ohion	lea	_RTName(pc),a2
	move.l	a2,a1
	moveq	#0,d0
	CLIB	Exec,OpenLibrary
	move.l	d0,_RTBase(a5)
	beq.b	print

	lea	_PPName(pc),a2
	move.l	a2,a1
	moveq	#0,d0
	CALL	OpenLibrary
	move.l	d0,_PPBase(a5)
	beq.b	print

	ifne	fromasmone
	Pull	All
	jmp	alkuu
	else

	move.l	#procname,d1
	moveq	#-1,d2
	lea	CreateProc-4(pc),a0
	move.l	(a0),d3
	move.l	d3,segment(a5)
	clr.l   (a0)
	move.l	#4096,d4
	C5LIB	DOS,CreateProc
	tst.l	d7
	beq.b	poiss
	CLIB	Exec,Forbid
	move.l	d7,a1
	CALL	ReplyMsg
	endc

poiss	Pull	All
	moveq	#0,d0
	rts

;; ERROR

print	lea	nolib(pc),a0
	move.l	a0,d2
	lea	nap-nolib(a0),a0
.l	move.b	(a2)+,(a0)+
	bne.b	.l
	move.b	#10,-1(a0)
	sub.l	d2,a0
	move.l	a0,d3
printa	C5LIB	DOS,Output
	move.l	d0,d1
	beq.b	poiss
	CALL	Write
	bra.b	poiss

ver	dc.b	'$VER: P61Con, The Player 6.1A Converter '
	VER
	dc.b	0

procname dc.b	'Player 6.1A Converter!',0
nolib	dc.b	'You need '
nap	dcb.b	21
info	dc.b	'Usage: P61con [-q][filename]',10,0
_DOSName DOSNAME
_RTName REQTOOLSNAME
_PPName	PPNAME

;ญญญญญญญญญญญญญญญญญญญญญญญญญญญญ
;ญ   Player 6.1A Converter  ญ
;ญ ฉ 1992-95 Jarno Paananen ญ
;ญญญญญญญญญญญญญญญญญญญญญญญญญญญญ

	section	Koodi,code
alkuu	
	Push	All
	lea	sa,a5

	sub.l	a1,a1
	CLIB	Exec,FindTask
	move.l	d0,task(a5)

	moveq	#-1,d0
	CALL	AllocSignal
	move.b	d0,portsignal
	bmi	exit

	lea	port(a5),a1
	CALL	AddPort

	lea	_XPKName(a5),a1
	moveq	#0,d0
	CALL	OpenLibrary
	move.l	d0,_XPKBase(a5)

	move.l	Lock(a5),d1
	beq.b	ohitaaa
	C5LIB	DOS,CurrentDir

ohitaaa	ifne	decode
	lea	alksu(pc),a0
	lea	lopsu(pc),a1
losp	eori	#$1976,(a0)+
	cmp.l	a0,a1
	bne.b	losp
	endc

	move.l	_RTBase(a5),a1
	move.l	rt_GfxBase(a1),_GFXBase(a5)
	move.l	rt_IntuitionBase(a1),_IntBase(a5)

	ifne	fromasmone
	lea	muuttujat,a0
	lea	bssend,a1
.cl	clr.l	(a0)+
	cmp.l	a0,a1
	bne.b	.cl
	endc

	bsr	loadprefs

	tst	para(a5)
	bne	soittele

;; Take Workbench screen infos

	C5LIB	Int,OpenWorkBench
	move.l	d0,a0

	moveq	#0,d0
	move.b	sc_BarHeight(a0),d0
	add.b	sc_WBorTop(a0),d0
	subq	#1,d0
	move	d0,topbor(a5)
	add	d0,winstr+6(a5)
	add	d0,prefwinstr+6(a5)

	move	sc_Width(a0),d0
	asr	#1,d0
	move	winstr+4(a5),d1
	asr	#1,d1
	move	d0,d2
	sub	d1,d2
	move	d2,winstr(a5)

	move	prefwinstr+4(a5),d1
	asr	#1,d1
	sub	d1,d0
	move	d0,prefwinstr(a5)

	move	sc_Height(a0),d0
	asr	#1,d0
	move	winstr+6(a5),d1
	asr	#1,d1
	move	d0,d2
	sub	d1,d2
	move	d2,winstr+2(a5)

	move	prefwinstr+6(a5),d1
	asr	#1,d1
	sub	d1,d0
	move	d0,prefwinstr+2(a5)


;; Open main menu

conttaa	lea	winstr(a5),a0
	C5LIB	Int,OpenWindow
	move.l	d0,winpoin(a5)
	beq	exit

	move.l	d0,a0
	move.l	wd_RPort(a0),RPort(a5)

	lea	texture(a5),a0
	move.l	RPort(a5),a1
	move.l	a0,rp_AreaPtrn(a1)
	move.b	#1,rp_AreaPtSz(a1)

	moveq	#2,d0
	C5LIB	GFX,SetAPen

	move.l	RPort(a5),a1
	move.l	a1,a2
	moveq	#3,d0
	moveq	#0,d1
	move	#296,d2
	move	#167,d3
	add	topbor(a5),d1
	add	topbor(a5),d3
	CALL	RectFill

	lea	otextu(a5),a0
	move.l	RPort(a5),a1
	move.l	a0,rp_AreaPtrn(a1)
	clr.b	rp_AreaPtSz(a1)

	lea	gadgets(a5),a4
gadloop	
	move	4(a4),d0
	move	winstr+6(a5),d1
	add	6(a4),d1
	subq	#1,d1

	move	d0,d2
	move	d1,d3
	add	8(a4),d2
	add	10(a4),d3
	subq	#1,d2
	subq	#1,d3
	move.l	a2,a1
	C5LIB	GFX,RectFill

	move.l	(a4),d6
	move.l	a4,a1
	move.l	winpoin(a5),a0
	moveq	#-1,d0
	C5LIB	Int,AddGadget
	tst.l	d6
	beq.b	pesa		
	move.l	d6,a4
	bra.b	gadloop

pesa
	lea	gadgets(a5),a0
	move.l	winpoin(a5),a1
	sub.l	a2,a2
	CALL	RefreshGadgets

	moveq	#9,d7
	add	topbor(a5),d7
	lea	tekstus(a5),a2
ulosta	move.l	a2,kelo(a5)
	move.l	a2,kala(a5)
kod	cmp.b	#10,(a2)+
	bne.b	kod
	clr.b	-(a2)

	lea	texa(a5),a0
	CALL	IntuiTextLength

	move	#150,d1
	asr	#1,d0
	sub	d0,d1

	move	d1,d0
	move.l	RPort(a5),a0
	lea	texa(a5),a1
	move.l	d7,d1
	CALL	PrintIText

	move.b	#10,(a2)+
uusk	addq	#8,d7
	cmp.b	#10,(a2)
	bne.b	kalsari
	addq	#1,a2
	bra.b	uusk
kalsari	tst.b	(a2)
	bne.b	ulosta


;; Mainmenu eventloop

event	move.l	winpoin(a5),a0
	move.l	wd_UserPort(a0),a2
	move.b	15(a2),d1
	moveq	#0,d0
	bset	d1,d0
	move.l	d0,d2
	move.b	portsignal(a5),d1
	bset	d1,d0
	
	CLIB	Exec,Wait

	and.l	d0,d2
	bne.w	winport

;; Request from port
evena	lea	port(a5),a0
	CALL	GetMsg
	move.l	d0,a2
	cmp.l	#'CONV',MN_SIZE(a2)
	bne.b	event

	move.l	winpoin(a5),a0
	move.l	wd_LeftEdge(a0),winstr(a5)
	C5LIB	Int,CloseWindow
	clr.l	winpoin(a5)

	st	fromport(a5)
	clr	stopfl(a5)
	clr.l	filelength(a5)
	clr.l	conlength(a5)
	clr	err(a5)
	move.l	a2,-(sp)
	lea	MN_SIZE+4(a2),a2
	move.l	(a2)+,memory(a5)
	move.l	(a2)+,filelength(a5)
	move.l	(a2),a0
	move.l	a0,dirdd(a5)
	addq.l	#4,dirdd(a5)
	lea	fname3,a1
.cop	move.b	(a0)+,(a1)+
	bne.b	.cop
	bra	modcorrect

takasi	move.l	(sp)+,a1
	tst	err(a5)
	beq.b	.kje
	move.l	#'ERR!',MN_SIZE(a1)
	bra.b	.kip
.kje	tst	stopfl(a5)
	beq.b	.jep
	move.l	#'BRK!',MN_SIZE(a1)
	bra.b	.kip
.jep	move.l	#'DONE',MN_SIZE(a1)
.kip	CLIB	Exec,ReplyMsg
	bra	conttaa

;; Window IDCMP

winport	move.l	a2,a0
	CALL	GetMsg
	tst.l	d0
	beq.b	eventdone

	move.l	d0,a1
	move.l	im_Class(a1),d2
	move.l	im_IAddress(a1),a4
	CALL	ReplyMsg
	bra.b	winport

eventdone
	cmp.l	#GADGETUP,d2
	beq.b	Painettu
	cmp.l	#CLOSEWINDOW,d2
	bne	event

	move.l	winpoin(a5),a0
	C5LIB	Int,CloseWindow
	clr.l	winpoin(a5)
	bra	exit

Painettu
	move.l	winpoin(a5),a0
	move.l	wd_LeftEdge(a0),winstr(a5)
	C5LIB	Int,CloseWindow
	move	gg_GadgetID(a4),d0
	beq.w	converter

	subq	#1,d0
	beq	Ripper

	subq	#1,d0
	beq	modplayer

	subq	#1,d0
	beq	prefs
	bra	aboutti


axissourcefilename:
	dc.b	"hd0:tune.mod",0
axisdstfilename:
	dc.b	"hd0:tune.p61",0
axisfinishedfilename:
	dc.b	"hd0:finished",0
	
	cnop	0,2
AxisHackedConvert:
	lea	_PPName(pc),a2
	move.l	a2,a1
	moveq	#0,d0
	CALL	OpenLibrary
	move.l	d0,_PPBase(a5)

	lea		axissourcefilename,a0
	moveq	#2,d0
	moveq	#MEMF_PUBLIC,d1
	lea		memory(a5),a1
	lea		filelength(a5),a2
	clr.l	(a1)
	clr.l	(a2)
	sub.l	a3,a3
	bsr		LoadData
	
	tst.l	d0
	bpl	.decrunchok

;; PP errors
.pperror	C5LIB	PP,ppErrorMessage
	move.l	d0,a1

	lea	tags(a5),a0
	sub.l	a3,a3
	move.l	a3,a4
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	bra	urgh

.decrunchok
	move.l	memory(a5),a0
	cmpi.l	#'M.K.',1080(a0)
	beq.b	.modcorrect
	cmpi.l	#'M!K!',1080(a0)
	beq.b	.modcorrect
	cmpi.l	#'FLT4',1080(a0)
	beq.b	.modcorrect
	
	OXYDEBUG	DEBUGCOL_MOD_BROKEN
	
.modcorrect
	move.l	memory(a5),a0
	moveq	#127,d0
	moveq	#0,d1
	lea	952(a0),a0
.oppo3	cmp.b	(a0)+,d1
	bhs.b	.nothighest2
	move.b	-1(a0),d1
.nothighest2
	dbf	d0,.oppo3

	and	#$7f,d1
	addq	#1,d1
	asl	#2,d1
	asl.l	#8,d1
	add.l	#1084,d1
	move.l	d1,buffer(a5)

	move.l	d1,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	CLIB	Exec,AllocMem
	move.l	d0,converted(a5)
	bne.b	.nuxt

.kidlo	lea	tags(a5),a0
	sub.l	a3,a3
	lea	muuttujat,a4
	move.l	buffer(a5),(a4)
	lea	memerr2(a5),a1
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	st	err(a5)

.nuxt	move.l	buffer(a5),d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	CALL	AllocMem
	move.l	d0,temporary(a5)
	beq.b	.kidlo

	move.l	filelength(a5),orglength(a5)
	
	move.l	#axisdstfilename,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,file(a5)
	bne.b	.openok2

	OXYDEBUG DEBUGCOL_CANT_WRITE
	
.openok2:
	bsr.w	convert

	move.l	file(a5),d1
	C5LIB	DOS,Close
	
	;signal that we have finished conversion with creation of the finished file
	move.l	#axisfinishedfilename,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,file(a5)
	bne.b	.openok3

	OXYDEBUG DEBUGCOL_CANT_FINISH

.openok3:
	move.l	file(a5),d1
	C5LIB	DOS,Close
	
	OXYDEBUG DEBUGCOL_CONV_OK
	
;; Convert module(s)
converter
	clr.l	filelength(a5)
	clr.l	conlength(a5)
	clr	stopfl(a5)
	clr	fromport(a5)
	
	tst.l	reqptr(a5)
	bne.b	.kej

	sub.l	a0,a0
	moveq	#RT_FILEREQ,d0
	C5LIB	RT,rtAllocRequestA
	move.l	d0,reqptr(a5)
	beq	exit

	lea	loadprefix(a5),a0
	lea	prefix(a5),a2
	tst.b	(a0)
	beq.b	.ok4
.lops	move.b	(a0)+,(a2)+
	bne.b	.lops
	subq.l	#1,a2
.ok4	move.b	#'#',(a2)+
	move.b	#'?',(a2)+
	clr.b	(a2)

	move.l	reqptr(a5),a1
	lea	diretags(a5),a0
	CALL	rtChangeReqAttrA

.kej	move.l	reqptr(a5),a1
	lea	loadtags(a5),a0
	lea	fname,a2
	lea	title(a5),a3
	C5LIB	RT,rtFileRequestA
	move.l	d0,filelist(a5)
	beq	conttaa

	move.l	d0,a0
	tst.l	(a0)
	bne	Batchmode

	CALL	rtFreeFileList
	clr.l	filelist(a5)

	clr	batch(a5)
	move.l	reqptr(a5),a0
	move.l	rtfi_Dir(a0),a0
	lea	fname2,a1
	move.l	a1,a2
	tst.b	(a0)
	beq.b	.ok2
.lopa	move.b	(a0)+,(a1)+
	bne.b	.lopa

	move.b	#'/',-1(a1)
	cmp.b	#':',-2(a1)
	bne.b	.ok2
	subq.l	#1,a1
.ok2	lea	fname,a0
.lops2	move.b	(a0)+,(a1)+
	bne.b	.lops2

	move.l	a2,a0
	moveq	#2,d0
	moveq	#MEMF_PUBLIC,d1
	lea	memory(a5),a1
	lea	filelength(a5),a2
	sub.l	a3,a3
	bsr	LoadData

	tst.l	d0
	bpl	decrunchok

;; PP errors
pperror	C5LIB	PP,ppErrorMessage
	move.l	d0,a1

	lea	tags(a5),a0
	sub.l	a3,a3
	move.l	a3,a4
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	bra	urgh

decrunchok
	move.l	memory(a5),a0
	cmpi.l	#'M.K.',1080(a0)
	beq.b	modcorrect
	cmpi.l	#'M!K!',1080(a0)
	beq.b	modcorrect
	cmpi.l	#'FLT4',1080(a0)
	beq.b	modcorrect

	lea	tags(a5),a0
	sub.l	a3,a3
	move.l	a3,a4
	lea	bodytext(a5),a1
	lea	yep(a5),a2
	C5LIB	RT,rtEZRequestA

	tst.l	d0
	beq	urgh

modcorrect
	move.l	memory(a5),a0
	moveq	#127,d0
	moveq	#0,d1
	lea	952(a0),a0
oppo3	cmp.b	(a0)+,d1
	bhs.b	.nothighest2
	move.b	-1(a0),d1
.nothighest2
	dbf	d0,oppo3

	and	#$7f,d1
	addq	#1,d1
	asl	#2,d1
	asl.l	#8,d1
	add.l	#1084,d1
	move.l	d1,buffer(a5)

	move.l	d1,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	CLIB	Exec,AllocMem
	move.l	d0,converted(a5)
	bne.b	nuxt

kidlo	lea	tags(a5),a0
	sub.l	a3,a3
	lea	muuttujat,a4
	move.l	buffer(a5),(a4)
	lea	memerr2(a5),a1
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	st	err(a5)
	bra	urgh

nuxt	move.l	buffer(a5),d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	CALL	AllocMem
	move.l	d0,temporary(a5)
	beq.b	kidlo

	move.l	filelength(a5),orglength(a5)

	tst	fromport(a5)
	bne	new

	tst.l	reqptr2(a5)
	bne.b	.kej
	moveq	#0,d0
	move.l	d0,a0
	moveq	#RT_FILEREQ,d0
	C5LIB	RT,rtAllocRequestA
	move.l	d0,reqptr2(a5)
	beq	exit

	lea	saveprefix(a5),a0
	lea	prefix(a5),a2
	tst	(a0)
	beq.b	.ok3
.lops	move.b	(a0)+,(a2)+
	bne.b	.lops
	subq.l	#1,a2
.ok3	move.b	#'#',(a2)+
	move.b	#'?',(a2)+
	clr.b	(a2)

	move.l	reqptr2(a5),a1
	lea	dir2tags(a5),a0
	CALL	rtChangeReqAttrA

.kej	lea	fname2,a1
	lea	saveprefix,a0
	tst.b	(a0)
	beq.b	.skip
.leps	move.b	(a0)+,(a1)+
	bne.b	.leps
	subq.l	#1,a1

.skip	lea	fname,a0
	move.l	a0,dirdd(a5)
	moveq	#7,d0
	moveq	#'.',d1
.lops2	cmp.b	(a0)+,d1
	beq.b	.plop
	dbf	d0,.lops2
	lea	fname,a0
.plop	move.b	(a0)+,(a1)+
	bne.b	.plop

	lea	savetags(a5),a0
	move.l	reqptr2(a5),a1
	lea	fname2,a2
	lea	title2(a5),a3
	C5LIB	RT,rtFileRequestA
	tst.l	d0
	beq	urgh

	move.l	reqptr2(a5),a0
	move.l	rtfi_Dir(a0),a0
	lea	fname3,a1
	tst.b	(a0)
	beq.b	.okd2
.loaps	move.b	(a0)+,(a1)+
	bne.b	.loaps

	move.b	#'/',-1(a1)
	cmp.b	#':',-2(a1)
	bne.b	.okd2
	subq.l	#1,a1
.okd2	lea	fname2,a0
.lops3	move.b	(a0)+,(a1)+
	bne.b	.lops3

	move.l	#fname3,d1
	move.l	#MODE_OLDFILE,d2
	C5LIB	DOS,Open
	move.l	d0,d1
	beq.b	new
	CALL	Close

	lea	tags(a5),a0
	sub.l	a3,a3
	move.l	a3,a4
	lea	exists(a5),a1
	lea	yep(a5),a2
	C5LIB	RT,rtEZRequestA
	tst.l	d0
	beq	urgh

new	move.l	#fname3,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,file(a5)
	bne.b	openok2

	lea	tags(a5),a0
	sub.l	a3,a3
	move.l	a3,a4
	lea	openerr(a5),a1
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	st	err(a5)
	bra	urgh

openok2	clr.l	file2(a5)
	tst	fromport(a5)
	bne.b	go_on2

	btst	#0,flags+3(a5)
	beq.b	go_on2
	btst	#2,flags+3(a5)
	bne.b	go_on2

	move.l	reqptr2(a5),a0
	lea	fname4,a1
	move.l	rtfi_Dir(a0),a0
	tst.b	(a0)
	beq.b	.okd6
.lops	move.b	(a0)+,(a1)+
	bne.b	.lops

	move.b	#'/',-1(a1)
	cmp.b	#':',-2(a1)
	bne.b	.okd6
	subq.l	#1,a1
.okd6	lea	sampprefix(a5),a0
	tst.b	(a0)
	beq.b	.skip2
.lops4	move.b	(a0)+,(a1)+
	bne.b	.lops4
	subq.l	#1,a1

.skip2	lea	fname2,a0
	moveq	#7,d0
	moveq	#'.',d1
.lops2	cmp.b	(a0)+,d1
	beq.b	poistu2
	dbf	d0,.lops2
	lea	fname2,a0
poistu2	move.b	(a0)+,(a1)+
	bne.b	poistu2

	move.l	#fname4,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,file2(a5)

go_on2	move.l	a5,-(sp)
	bsr	akkuna
	bsr	convert
	move.l	(sp)+,a5

	move.l	converted(a5),a1
	move.l	buffer(a5),d0
	CLIB	Exec,FreeMem
	clr.l	converted(a5)

	move.l	temporary(a5),d0
	beq.b	noon
	move.l	d0,a1
	move.l	buffer(a5),d0
	CALL	FreeMem
	clr.l	temporary(a5)

noon	tst	stopfl(a5)
	bne.b	.nope
	move.l	reqhandler(a5),a1
	lea	handtags(a5),a0
	moveq	#0,d0
	C5LIB	RT,rtReqHandlerA

.nope	move.l	file(a5),d1
	C5LIB	DOS,Close
	clr.l	file(a5)
	tst	stopfl(a5)
	beq.b	.nope3
	move.l	#fname3,d1
	CALL	DeleteFile

.nope3	move.l	file2(a5),d1
	beq.b	.nope2
	CALL	Close

	clr.l	file2(a5)
	tst	stopfl(a5)
	beq.b	.nope2
	move.l	#fname4,d1
	CALL	DeleteFile

*** Final results
.nope2	tst	stopfl(a5)
	bne	urgh

	tst	fromport(a5)
	bne	urgh

	btst	#4,flags+3(a5)
	beq.b	ohitse
	lea	fname3,a0
	move.l	a0,d1
.etsiloppu
	tst.b	(a0)+
	bne.b	.etsiloppu
	move.b	#'.',-1(a0)
	move.b	#'i',(a0)+
	move.b	#'n',(a0)+
	move.b	#'f',(a0)+
	move.b	#'o',(a0)+
	clr.b	(a0)+

	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,d7
	beq.b	ohitse
	move.l	d0,d1
	move.l	#ikoni,d2
	move.l	#iend-ikoni,d3
	CALL	Write
	move.l	d7,d1
	CALL	Close

ohitse	lea	fname3,a0
	bsr	makefilenote

	lea	tags(a5),a0
	sub.l	a3,a3
	lea	muuttujat,a4
	move.l	orglength(a5),d0
	move.l	conlength(a5),d1
	move.l	d0,d2
	sub.l	d1,d2
	move.l	a4,a1
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	move.l	d1,(a1)+
	move.l	d1,(a1)+
	move.l	d2,(a1)+
	move.l	d2,(a1)+
	move.l	usec(a5),(a1)+
	move.l	sbuflen(a5),(a1)+
	lea	org(a5),a1
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	bra	urgh


;; ***** The Ripper! *****

Ripper
	ifne	release

	rts

	else

	tst.l	reqptr2(a5)
	bne.b	.kej

	sub.l	a0,a0
	moveq	#RT_FILEREQ,d0
	C5LIB	RT,rtAllocRequestA
	move.l	d0,reqptr2(a5)
	beq	exit

	lea	saveprefix(a5),a0
	lea	prefix(a5),a2
	tst.b	(a0)
	beq.b	.skip
.lops	move.b	(a0)+,(a2)+
	bne.b	.lops
	subq.l	#1,a2
.skip	move.b	#'#',(a2)+
	move.b	#'?',(a2)+
	clr.b	(a2)

	move.l	reqptr2(a5),a1
	lea	dir2tags(a5),a0
	CALL	rtChangeReqAttrA
	
.kej	move.l	reqptr2(a5),a1
	lea	convtags(a5),a0
	lea	fname,a2
	lea	title9(a5),a3
	C5LIB	RT,rtFileRequestA
	tst.l	d0
	beq	urgh

	move.l	reqptr2(a5),a0
	move.l	rtfi_Dir(a0),a0
	lea	fname3,a1
	tst.b	(a0)
	beq.b	.koo
.lopa	move.b	(a0)+,(a1)+
	bne.b	.lopa

	move.b	#'/',-1(a1)
	cmp.b	#':',-2(a1)
	bne.b	.koo
	subq.l	#1,a1
.koo	lea	fname,a0
.lops2	move.b	(a0)+,(a1)+
	bne.b	.lops2

	lea	fname3,a0
	moveq	#2,d0
	moveq	#MEMF_PUBLIC,d1
	lea	memory(a5),a1
	lea	filelength(a5),a2
	sub.l	a3,a3
	bsr	LoadData
	tst.l	d0
	bmi	pperror

	move.l	memory(a5),a0
	cmp.l	#'P61A',(a0)
	bne.b	.kos
	addq.l	#4,a0
.kos	moveq	#$7f,d0
	and.b	2(a0),d0
	mulu	#1024,d0
	add.l	#1084,d0
	move.l	d0,buffer(a5)

	move.l	a0,a2
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	CLIB	Exec,AllocMem
	move.l	d0,converted(a5)
	beq	urgh

	moveq	#$40,d0
	and.b	3(a2),d0
	beq.b	.fdf

	move.l	4(a2),d0
	move.l	d0,templen(a5)
	moveq	#MEMF_PUBLIC,d1
	CLIB	Exec,AllocMem
	move.l	d0,temporary(a5)
	beq	urgh

.fdf	move.l	converted(a5),a0
	lea	textys(a5),a1
	move.l	a0,a2
djk	move.b	(a1)+,(a2)+
	bne.b	djk

	lea	textys2(a5),a1
	lea	20+(30*30)(a0),a2
djk2	move.b	(a1)+,(a2)+
	bne.b	djk2

	lea	textys(a5),a1
	lea	20+(30*29)(a0),a2
djk3	move.b	(a1)+,(a2)+
	bne.b	djk3

	move.l	#'M.K.',1080(a0)

	move.l	memory(a5),a0
	cmp.l	#'P61A',(a0)
	bne.b	.kos
	addq.l	#4,a0
.kos
	move.l	temporary(a5),a2
	endb	a5

	moveq	#0,d0
	move	(a0),d0
	lea	(a0,d0.l),a1
	move.l	a2,a6
	lea	8(a0),a2
	moveq	#$40,d0
	and.b	3(a0),d0
	bne.b	.buffer
	move.l	a1,a6
	subq.l	#4,a2
.buffer
	moveq	#$1f,d1
	and.b	3(a0),d1
	lea	P_Samples(pc),a4
	subq	#1,d1
	moveq	#0,d4
P61_lopos
	move.l	a6,(a4)+
	move	(a2)+,d4
	bpl.b	P61_kook
	neg	d4
	lea	P_Samples-16(pc),a5
	asl	#4,d4
	move.l	(a5,d4),d6
	move.l	d6,-4(a4)
	move	4(a5,d4),d4
	sub.l	d4,a6
	sub.l	d4,a6
	bra.b	P61_jatk

P61_kook
	move.l	a6,d6
	tst.b	3(a0)
	bpl.b	P61_jatk

	tst.b	(a2)
	bmi.b	P61_jatk

	move	d4,d0
	subq	#2,d0
	bmi.b	P61_jatk

	move.l	a1,a5
	move.b	(a5)+,d2
	sub.b	(a5),d2
	move.b	d2,(a5)+
.loop	sub.b	(a5),d2
	move.b	d2,(a5)+
	sub.b	(a5),d2
	move.b	d2,(a5)+
	dbf	d0,.loop

P61_jatk
	move	d4,(a4)+
	moveq	#0,d2
	move.b	(a2)+,d2
	moveq	#0,d3
	move.b	(a2)+,d3

	moveq	#0,d0
	move	(a2)+,d0
	bmi.b	.norepeat

	move	d4,d5
	sub	d0,d5
	move.l	d6,a5

	add.l	d0,a5
	add.l	d0,a5

	move.l	a5,(a4)+
	move	d5,(a4)+
	bra.b	P61_gene
.norepeat
	move.l	d6,(a4)+
	move	#1,(a4)+
P61_gene
	move	d3,(a4)+
	moveq	#$f,d0
	and	d2,d0
	mulu	#74,d0
	move	d0,(a4)+

	tst	-6(a2)
	bmi.b	.nobuffer

	moveq	#$40,d0
	and.b	3(a0),d0
	beq.b	.nobuffer

	move	d4,d7
	tst.b	d2
	bpl.b	.copy

	subq	#1,d7
	moveq	#0,d5
	moveq	#0,d4
.lo	move.b	(a1)+,d4
	moveq	#$f,d3
	and	d4,d3
	lsr	#4,d4

	sub.b	.table(pc,d4),d5
	move.b	d5,(a6)+
	sub.b	.table(pc,d3),d5
	move.b	d5,(a6)+
	dbf	d7,.lo
	bra.b	.kop

.copy	add	d7,d7
	subq	#1,d7
.cob	move.b	(a1)+,(a6)+
	dbf	d7,.cob
	bra.b	.kop

.table dc.b	0,1,2,4,8,16,32,64,128,-64,-32,-16,-8,-4,-2,-1

.nobuffer
	move.l	d4,d6
	add.l	d6,d6
	add.l	d6,a6
	add.l	d6,a1
.kop	dbf	d1,P61_lopos

	and.b	#$7f,3(a0)
	move.l	a2,positionbase

	moveq	#$7f,d1
	and.b	2(a0),d1
	lsl	#3,d1
	lea	(a2,d1.l),a4
	move.l	a4,possibase

	move.l	a4,a1
	moveq	#-1,d0
	moveq	#0,d1
.search	cmp.b	(a1)+,d0
	beq.b	.loe
	addq.l	#1,d1
	bra.b	.search
.loe	move.l	a1,patternbase

	move.l	converted,a1
	move.b	d1,950(a1)
	move.b	#$7f,951(a1)

	lea	P_Samples(pc),a2
	lea	42(a1),a3
	moveq	#$1f,d7
	and.b	3(a0),d7
	moveq	#$1f,d5
	sub	d7,d5

	subq	#1,d7
	moveq	#0,d6
sloop	move.l	(a2)+,d0
	moveq	#0,d3
	move	(a2)+,(a3)
	move.l	(a2)+,d1
	sub.l	d0,d1
	asr.l	#1,d1
	move	d1,4(a3)
	move	(a2)+,6(a3)
	move	(a2)+,2(a3)
	moveq	#0,d0
	move	(a2)+,d0
	divu	#74,d0
	move.b	d0,2(a3)
	lea	30(a3),a3
	dbf	d7,sloop

	subq	#1,d5
	bmi.b	.hii
	moveq	#1,d0
.sl	move	d0,6(a3)
	lea	30(a3),a3
	dbf	d5,.sl

.hii	lea	952(a1),a2
	move.l	possibase(pc),a4

	moveq	#0,d6
	move.b	950(a1),d6
	subq	#1,d6
sch	move.b	(a4)+,(a2)+
	dbf	d6,sch

	move.l	patternbase(pc),a2

	moveq	#$7f,d7
	and.b	2(a0),d7
	subq	#1,d7

	move.l	positionbase(pc),a5
	moveq	#0,d5
patconv
	moveq	#$7f,d6
	and.b	2(a0),d6
	subq	#1,d6

	move.l	d5,d0
	lsl	#8,d0
	asl.l	#2,d0
	lea	(a1,d0.l),a3
	add.l	#1084,a3	
	addq.l	#1,d5

	move.l	a2,d0
	moveq	#0,d4
	move	(a5)+,d4
	add.l	d4,d0

	move.l	a2,d1
	move	(a5)+,d4
	add.l	d4,d1

	move.l	a2,d2
	move	(a5)+,d4
	add.l	d4,d2

	move.l	a2,d3
	move	(a5)+,d4
	add.l	d4,d3

	move	#64,count2
pat	move.l	d0,a4
	lea	cha00(pc),a6
	bsr	convdata
	move.l	a4,d0
	move.l	d4,(a3)+

	move.l	d1,a4
	lea	cha1(pc),a6
	bsr	convdata
	move.l	a4,d1
	move.l	d4,(a3)+

	move.l	d2,a4
	lea	cha2(pc),a6
	bsr	convdata
	move.l	a4,d2
	move.l	d4,(a3)+

	move.l	d3,a4
	lea	cha3(pc),a6
	bsr	convdata
	move.l	a4,d3
	move.l	d4,(a3)+

	tst	brake
	bne.b	net

	subq	#1,count2
	bne.b	pat

net	clr	brake
	dbf	d7,patconv

	basereg	sa,a5
	lea	sa,a5

	tst.l	reqptr(a5)
	bne.b	.kej
	moveq	#0,d0
	move.l	d0,a0
	moveq	#RT_FILEREQ,d0
	C5LIB	RT,rtAllocRequestA
	move.l	d0,reqptr(a5)
	beq	exit

	lea	loadprefix(a5),a0
	lea	prefix(a5),a2
	tst.b	(a0)
	beq.b	.skip
.lops	move.b	(a0)+,(a2)+
	bne.b	.lops
	subq.l	#1,a2
.skip	move.b	#'#',(a2)+
	move.b	#'?',(a2)+
	clr.b	(a2)

	move.l	reqptr(a5),a1
	lea	diretags(a5),a0
	CALL	rtChangeReqAttrA

.kej	lea	savetags(a5),a0
	move.l	reqptr(a5),a1
	lea	fname2,a2
	lea	title2(a5),a3
	C5LIB	RT,rtFileRequestA
	tst.l	d0
	beq	urgh

	move.l	reqptr(a5),a0
	move.l	rtfi_Dir(a0),a0
	lea	fname3,a1
	tst.b	(a0)
	beq.b	.okd2
.loaps	move.b	(a0)+,(a1)+
	bne.b	.loaps

	move.b	#'/',-1(a1)
	cmp.b	#':',-2(a1)
	bne.b	.okd2
	subq.l	#1,a1
.okd2	lea	fname2,a0
.lops2	move.b	(a0)+,(a1)+
	bne.b	.lops2

	move.l	#fname3,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,file(a5)
	beq.b	poisas

	move.l	d0,d1
	move.l	converted(a5),d2
	move.l	buffer(a5),d3
	CALL	Write

	move.l	converted(a5),a1
	lea	1084(a1),a3
	move.l	memory(a5),a0
	cmp.l	#'P61A',(a0)
	bne.b	.kos
	addq.l	#4,a0
.kos	lea	P_Samples(pc),a2
	moveq	#$1f,d7
	and.b	3(a0),d7
	subq	#1,d7
sloop2	move.l	(a2)+,d2
	moveq	#0,d3
	move	(a2)+,d3
	add.l	d3,d3
	move.l	file(a5),d1
	CALL	Write
	lea	10(a2),a2
	dbf	d7,sloop2

	move.l	file(a5),d1
	CALL	Close
	clr.l	file(a5)

poisas	move.l	converted(a5),a1
	move.l	buffer(a5),d0
	CLIB	Exec,FreeMem
	clr.l	converted(a5)

	move.l	temporary(a5),d0
	beq	urgh
	move.l	d0,a1
	move.l	templen(a5),d0
	CLIB	Exec,FreeMem
	clr.l	temporary(a5)
	bra	urgh

convdata
	movem.l	d0-d3,-(sp)
	move.b	3(a6),d0
	and.b	#$3f,d0
	beq.b	P61_takeone

	tst.b	3(a6)
	bmi.b	.keepsame

	subq.b	#1,3(a6)
	moveq	#0,d4
	movem.l	(sp)+,d0-d3
	rts

.keepsame
	move.l	12(a6),d4
	subq.b	#1,3(a6)
	movem.l	(sp)+,d0-d3
	rts

P61_takeone
	move.l	a2,-(sp)

	tst.b	9(a6)
	beq.b	P61_takenorm

	subq.b	#1,9(a6)
	move.l	4(a6),a2

P61_jedi
	move.b	(a2)+,d0
	moveq	#%01100000,d1
	and.b	d0,d1
	cmp.b	#%01100000,d1
	bne.b	.all

	moveq	#%01110000,d1
	and.b	d0,d1
	cmp.b	#%01110000,d1
	bne.b	.cmd

	moveq	#%01111000,d1
	and.b	d0,d1
	cmp.b	#%01111000,d1
	bne.b	.note

.empty	clr	(a6)+
	clr.b	(a6)+
	tst.b	d0
	bpl.b	.ex
	move.b	(a2)+,(a6)			; Compression info
	bra.b	.ex

.all	move.b	d0,(a6)+
	move.b	(a2)+,(a6)+
	move.b	(a2)+,(a6)+
	tst.b	d0
	bpl.b	.ex
	move.b	(a2)+,(a6)			; Compression info
	bra.b	.ex

.cmd	moveq	#$f,d1
	and	d0,d1
	move	d1,(a6)+			; cmd
	move.b	(a2)+,(a6)+			; info
	tst.b	d0
	bpl.b	.ex
	move.b	(a2)+,(a6)			; Compression info
	bra.b	.ex

.note	moveq	#7,d1
	and	d0,d1
	lsl	#8,d1
	move.b	(a2)+,d1
	lsl	#4,d1
	move	d1,(a6)+
	clr.b	(a6)+
	tst.b	d0
	bpl.b	.ex
	move.b	(a2)+,(a6)			; Compression info
.ex	subq.l	#3,a6
	move.l	a2,4(a6)
	bra	P61_dko


P61_takenorm
	move.b	(a4)+,d0
	moveq	#%01100000,d1
	and.b	d0,d1
	cmp.b	#%01100000,d1
	bne.b	.all

	moveq	#%01110000,d1
	and.b	d0,d1
	cmp.b	#%01110000,d1
	bne.b	.cmd

	moveq	#%01111000,d1
	and.b	d0,d1
	cmp.b	#%01111000,d1
	bne.b	.note

.empty	clr	(a6)+
	clr.b	(a6)+
	tst.b	d0
	bpl.b	.proccomp
	move.b	(a4)+,(a6)			; Compression info
	bra.b	.proccomp

.all	move.b	d0,(a6)+
	move.b	(a4)+,(a6)+
	move.b	(a4)+,(a6)+
	tst.b	d0
	bpl.b	.proccomp
	move.b	(a4)+,(a6)			; Compression info
	bra.b	.proccomp

.cmd	moveq	#$f,d1
	and	d0,d1
	move	d1,(a6)+			; cmd
	move.b	(a4)+,(a6)+			; info
	tst.b	d0
	bpl.b	.proccomp
	move.b	(a4)+,(a6)			; Compression info
	bra.b	.proccomp

.note	moveq	#7,d1
	and	d0,d1
	lsl	#8,d1
	move.b	(a4)+,d1
	lsl	#4,d1
	move	d1,(a6)+
	clr.b	(a6)+
	tst.b	d0
	bpl.b	.proccomp
	move.b	(a4)+,(a6)			; Compression info

.proccomp
	subq.l	#3,a6

	tst.b	d0
	bpl.b	P61_dko

	move.b	3(a6),d0
	move.b	d0,d1
	and	#%11000000,d1
	beq.b	P61_dko				; Empty datas
	cmp.b	#%10000000,d1
	beq.b	P61_dko				; Same datas

	clr.b	3(a6)
	and	#$3f,d0
	move.b	d0,9(a6)

	cmp.b	#%11000000,d1
	beq.b	.bit16				; 16-bit

	moveq	#0,d0				; 8-bit
	move.b	(a4)+,d0
	move.l	a4,a2
	sub.l	d0,a2
	bra	P61_jedi

.bit16	moveq	#0,d0
	move.b	(a4)+,d0
	lsl	#8,d0
	move.b	(a4)+,d0

	move.l	a4,a2
	sub.l	d0,a2
	bra	P61_jedi
P61_dko
	move.l	(sp)+,a2

	moveq	#$7e,d4
	and.b	(a6),d4
	move	periodtable(pc,d4),d4
	swap	d4

	moveq	#0,d1
	move	(a6),d1
	and	#$1f0,d1
	lsr	#4,d1

	moveq	#$f,d2
	and	d1,d2

	and	#$10,d1

	lsl	#8,d1
	swap	d1
	or.l	d1,d4

	ror	#4,d2
	or	d2,d4

	bsr.b	checkcomms

	move.l	d4,12(a6)
	
	movem.l	(sp)+,d0-d3
	rts
	endc

periodtable
	dc	0
	dc	856,808,762,720,678,640,604,570,538,508,480,453
	dc	428,404,381,360,339,320,302,285,269,254,240,226
	dc	214,202,190,180,170,160,151,143,135,127,120,113
	dc	113

	ifeq	release
checkcomms
	moveq	#0,d1
	move.b	2(a6),d1

	moveq	#$f,d0
	and	(a6),d0

	cmp	#$b,d0
	bne.b	nobreak
	st	brake
	bra.b	kud

nobreak	cmp	#$d,d0
	bne.b	nojump
	st	brake
	bra.b	kud

nojump	cmp	#$e,d0
	bne.b	noe
	move	d1,d2
	and	#$f0,d2
	bne.b	kud
	moveq	#$f,d2
	and	d1,d2
	lsr	#1,d2
	and	#$f0,d1
	or	d2,d1
	bra.b	kud

noe	cmp.b	#$a,d0
	beq.b	takas

	cmp.b	#5,d0
	beq.b	takas

	cmp.b	#6,d0
	bne.b	eislide
takas	tst.b	d1
	bpl.b	kud
	neg.b	d1
	lsl	#4,d1
	bra.b	kud

eislide	cmp	#8,d0
	bne.b	kud
	moveq	#0,d0

kud	lsl	#8,d0
	or	d0,d4
	move.b	d1,d4
	rts

cha00	dc.l	0,0,0,0
cha1	dc.l	0,0,0,0
cha2	dc.l	0,0,0,0
cha3	dc.l	0,0,0,0

brake	dc	0
count2	dc	0
P_Samples
	ds.b	16*31
positionbase
	dc.l	0
possibase dc.l	0
patternbase
	dc.l	0

	endc

;; ****  playmodule ****

modplayer
	move.l	memory(a5),d0
	beq.b	.dnid
	move.l	d0,a1
	move.l	filelength(a5),d0
	CLIB	Exec,FreeMem
	clr.l	memory(a5)

.dnid	tst.l	reqptr4(a5)
	bne.b	.kej
	sub.l	a0,a0
	moveq	#RT_FILEREQ,d0
	C5LIB	RT,rtAllocRequestA
	move.l	d0,reqptr4(a5)
	beq	exit

	lea	saveprefix(a5),a0
	lea	prefix(a5),a2
	tst.b	(a0)
	beq.b	.skip
.lops	move.b	(a0)+,(a2)+
	bne.b	.lops
	subq.l	#1,a2
.skip	move.b	#'#',(a2)+
	move.b	#'?',(a2)+
	clr.b	(a2)

	move.l	reqptr4(a5),a1
	lea	dir2tags(a5),a0
	CALL	rtChangeReqAttrA

.kej	move.l	reqptr4(a5),a1
	lea	playtags(a5),a0
	lea	fname,a2
	lea	title7(a5),a3
	C5LIB	RT,rtFileRequestA
	tst	d0
	beq	conttaa

	move.l	reqptr4(a5),a0
	move.l	rtfi_Dir(a0),a0
	lea	fname2,a1
	tst.b	(a0)
	beq.b	.okd
.lopa	move.b	(a0)+,(a1)+
	bne.b	.lopa

	move.b	#'/',-1(a1)
	cmp.b	#':',-2(a1)
	bne.b	.okd
	subq.l	#1,a1
.okd	lea	fname,a0
.lops2	move.b	(a0)+,(a1)+
	bne.b	.lops2

soittele
	CLIB	Exec,Forbid
	lea	port2name(a5),a1
	CALL	FindPort
	tst.l	d0
	bne.b	hupsis
	CALL	Permit
	bra.b	ladaa
	
hupsis	move.l	d0,a0
	lea	message(a5),a1
	move.l	#fname2,filename(a5)
	move.l	#'PLAY',command(a5)
	CALL	PutMsg
	CALL	Permit

oota3	lea	port(a5),a0
	CALL	WaitPort
	cmp.l	#'DONE',command(a5)
	bne.b	oota3

	clr.l	memory(a5)
	clr.l	filelength(a5)
	bra.b	urgh

ladaa	lea	fname2,a0
	moveq	#2,d0
	moveq	#MEMF_PUBLIC,d1
	lea	memory(a5),a1
	lea	filelength(a5),a2
	sub.l	a3,a3
	bsr	LoadData

	tst.l	d0
	bmi	pperror
	bsr	playmod

urgh	move.l	memory(a5),d0
	beq.b	.nomem
	move.l	d0,a1
	move.l	filelength(a5),d0
	CLIB	Exec,FreeMem
	clr.l	memory(a5)
.nomem	tst	fromport(a5)
	bne	takasi
	tst	para(a5)
	beq	conttaa
	bra	exit

;; ****** BATCH-MODE ******

Batchmode
	st	batch(a5)

	tst.l	reqptr3(a5)
	bne.b	.jatk
	sub.l	a0,a0
	moveq	#RT_FILEREQ,d0
	C5LIB	RT,rtAllocRequestA
	move.l	d0,reqptr3(a5)
	beq	exit

	move.l	reqptr3(a5),a1
	lea	dir3tags(a5),a0
	CALL	rtChangeReqAttrA

.jatk	lea	dirtags(a5),a0
	move.l	reqptr3(a5),a1
	lea	bname,a2
	lea	title3(a5),a3
	C5LIB	RT,rtFileRequestA
	tst.l	d0
	beq.b	urgh

	move.l	filelist(a5),filelistpos(a5)	
	clr.l	totalorg(a5)
	clr.l	totalcon(a5)
	clr.l	totalwon(a5)

	move.l	reqptr3(a5),a0
	move.l	rtfi_Dir(a0),a0
	lea	fname3,a1
	lea	fname4,a2
	tst.b	(a0)
	beq.b	.okd
.lops	move.b	(a0),(a1)+
	move.b	(a0)+,(a2)+
	bne.b	.lops

	move.b	#'/',-1(a1)
	move.b	#'/',-1(a2)
	cmp.b	#':',-2(a1)
	bne.b	.okd
	subq.l	#1,a1
	subq.l	#1,a2

.okd	lea	saveprefix(a5),a0
	tst.b	(a0)
	beq.b	.skipp
.lop	move.b	(a0)+,(a1)+
	bne.b	.lop
	subq.l	#1,a1

.skipp	lea	sampprefix(a5),a0
	tst.b	(a0)
	beq.b	.skipi
.lop2	move.b	(a0)+,(a2)+
	bne.b	.lop2
	subq.l	#1,a2

.skipi	move.l	a1,dirdd2(a5)
	move.l	a2,dirdd3(a5)

	move.l	reqptr(a5),a0
	move.l	rtfi_Dir(a0),a0
	lea	fname2,a1
	tst.b	(a0)
	beq.b	.oka
.lopss	move.b	(a0)+,(a1)+
	bne.b	.lopss

	move.b	#'/',-1(a1)
	cmp.b	#':',-2(a1)
	bne.b	.oka
	subq.l	#1,a1
.oka	move.l	a1,dirdd(a5)

load	move.l	filelistpos(a5),a1
	move.l	8(a1),a0
	move.l	dirdd(a5),a1
.lops	move.b	(a0)+,(a1)+
	bne.b	.lops

	lea	fname2,a0
	moveq	#2,d0
	moveq	#MEMF_PUBLIC,d1
	lea	memory(a5),a1
	lea	filelength(a5),a2
	sub.l	a3,a3
	bsr	LoadData

	tst.l	d0
	bmi	urgh2

	move.l	memory(a5),a0
	moveq	#127,d0
	moveq	#0,d1
	lea	952(a0),a0
oppo4	cmp.b	(a0)+,d1
	bhs.b	.nothighest2
	move.b	-1(a0),d1
.nothighest2
	dbf	d0,oppo4

	and	#$7f,d1
	addq	#1,d1
	asl	#2,d1
	asl.l	#8,d1
	add.l	#1084,d1
	move.l	d1,buffer(a5)

	move.l	d1,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	CLIB	Exec,AllocMem
	move.l	d0,converted(a5)
	bne.b	nuxt2

kadlo	lea	tags(a5),a0
	sub.l	a3,a3
	lea	muuttujat,a4
	move.l	buffer(a5),(a4)
	lea	memerr2(a5),a1
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	bra	urgh2

nuxt2	move.l	buffer(a5),d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	CALL	AllocMem
	move.l	d0,temporary(a5)
	beq.b	kadlo

	move.l	filelength(a5),orglength(a5)

	move.l	filelistpos(a5),a1
	move.l	8(a1),a0
	moveq	#7,d0
	moveq	#'.',d1
.lopa	cmp.b	(a0)+,d1
	beq.b	posa
	dbf	d0,.lopa
	move.l	8(a1),a0
posa	move.l	dirdd2(a5),a1
	move.l	dirdd3(a5),a2
.lop	move.b	(a0),(a1)+
	move.b	(a0)+,(a2)+
	bne.b	.lop

	move.l	#fname3,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,file(a5)
	bne.b	.openok2

	lea	tags(a5),a0
	sub.l	a3,a3
	move.l	a3,a4
	lea	openerr(a5),a1
	lea	contta(a5),a2
	C5LIB	RT,rtEZRequestA
	bra	urgh2

.openok2
	clr.l	file2(a5)
	btst	#0,flags+3(a5)
	beq.b	go_on
	btst	#2,flags+3(a5)
	bne.b	go_on

	move.l	#fname4,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,file2(a5)

go_on	bsr	akkuna
	bsr	convert

	move.l	converted(a5),a1
	move.l	buffer(a5),d0
	CLIB	Exec,FreeMem
	clr.l	converted(a5)

	move.l	temporary(a5),d0
	beq.b	noon2
	move.l	d0,a1
	move.l	buffer(a5),d0
	CALL	FreeMem
	clr.l	temporary(a5)

noon2	tst	stopfl(a5)
	bne.b	.nope
	move.l	reqhandler(a5),a1
	lea	handtags(a5),a0
	moveq	#0,d0
	C5LIB	RT,rtReqHandlerA

.nope	move.l	file(a5),d1
	C5LIB	DOS,Close
	clr.l	file(a5)
	tst	stopfl(a5)
	beq.b	.nope3
	move.l	#fname3,d1
	CALL	DeleteFile

.nope3	move.l	file2(a5),d1
	beq.b	.nope2
	CALL	Close

	clr.l	file2(a5)
	tst	stopfl(a5)
	beq.b	.nope2
	move.l	#fname4,d1
	CALL	DeleteFile

.nope2	tst	stopfl(a5)
	beq.b	.nostop

	lea	tags(a5),a0
	sub.l	a3,a3
	move.l	a3,a4
	lea	terminate(a5),a1
	lea	yep(a5),a2
	C5LIB	RT,rtEZRequestA
	tst.l	d0
	bne	batchend
	clr	stopfl(a5)
	bra.b	urgh2

.nostop	btst	#4,flags+3(a5)
	beq.b	.ohi2
	lea	fname3,a0
	move.l	a0,d1
.etsiloppu
	tst.b	(a0)+
	bne.b	.etsiloppu
	move.b	#'.',-1(a0)
	move.b	#'i',(a0)+
	move.b	#'n',(a0)+
	move.b	#'f',(a0)+
	move.b	#'o',(a0)+
	clr.b	(a0)+

	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,d4
	beq.b	.ohi2
	move.l	d4,d1
	move.l	#ikoni,d2
	move.l	#iend-ikoni,d3
	CALL	Write
	move.l	d4,d1
	CALL	Close

.ohi2	lea	fname3,a0
	bsr	makefilenote

	move.l	orglength(a5),d0
	add.l	d0,totalorg(a5)
	move.l	conlength(a5),d1
	add.l	d1,totalcon(a5)
	sub.l	d1,d0
	add.l	d0,totalwon(a5)

urgh2	move.l	memory(a5),d0
	beq.b	.nomem
	move.l	d0,a1
	move.l	filelength(a5),d0
	CLIB	Exec,FreeMem
	clr.l	memory(a5)

.nomem	move.l	filelistpos(a5),a0
	move.l	(a0),filelistpos(a5)
	bne	load

batchend
	move.l	filelist(a5),a0
	C5LIB	RT,rtFreeFileList
	clr.l	filelist(a5)

	lea	tags(a5),a0
	sub.l	a3,a3
	lea	muuttujat,a4
	move.l	totalorg(a5),d0
	move.l	totalcon(a5),d1
	move.l	totalwon(a5),d2
	move.l	a4,a1
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	move.l	d1,(a1)+
	move.l	d1,(a1)+
	move.l	d2,(a1)+
	move.l	d2,(a1)+
	lea	torg(a5),a1
	lea	contta(a5),a2
	CALL	rtEZRequestA
	bra	conttaa


;; Do filenote for the module

makefilenote
	move.l	a0,-(sp)

	lea	muuttujat,a1
	move.l	#vstr,(a1)+
	move.l	orglength(a5),(a1)+
	move.l	usec(a5),(a1)+
	move.l	sbuflen(a5),(a1)+

	lea	fnotestr(a5),a0
	lea	muuttujat,a1
	lea	putc(pc),a2
	lea	fname4,a3			;Temporary room for filenote
	CLIB	Exec,RawDoFmt

	move.l	(sp)+,d1
	move.l	#fname4,d2
	C5LIB	DOS,SetComment	
	rts

putc	move.b	d0,(a3)+
	rts

;; Do Reqtools-window for drawing

akkuna	CLIB	Exec,Forbid
	lea	winstr2(a5),a0
	C5LIB	Int,OpenWindow
	move.l	d0,winpoin(a5)

	lea	reqtags(a5),a0
	lea	reqhandler(a5),a1
	move.l	a1,4(a0)
	move.l	winpoin(a5),12(a0)
	sub.l	a3,a3
	lea	muuttujat,a4
	move.l	dirdd(a5),(a4)
	lea	packing(a5),a1
	lea	nothing(a5),a2
	C5LIB	RT,rtEZRequestA
	cmp.l	#$80000000,d0
	bne	nomemforwindow

	move.l	winpoin(a5),a0
	move.l	wd_WScreen(a0),a0
	move.l	sc_FirstWindow(a0),a0
	move.l	wd_RPort(a0),rast(a5)
	CLIB	Exec,Permit

	move.l	winpoin(a5),a0
	C5LIB	Int,CloseWindow

	move.l	rast(a5),a2
	move.l	a2,a1
	moveq	#1,d0
	C5LIB	GFX,SetDrMd

	lea	textattr(a5),a0
	CALL	OpenFont
	move.l	a2,a1
	move.l	d0,a0
	CALL	SetFont

	moveq	#120,d0
	moveq	#27,d1
	add	topbor(a5),d1
	move.l	a2,a0
	lea	bordel(a5),a1
	C5LIB	Int,DrawBorder

	moveq	#120,d0
	moveq	#27+9,d1
	add	topbor(a5),d1
	move.l	a2,a0
	lea	bordel(a5),a1
	CALL	DrawBorder

	moveq	#120,d0
	moveq	#27+36,d1
	add	topbor(a5),d1
	move.l	a2,a0
	lea	bordel(a5),a1
	CALL	DrawBorder

	move.l	a2,a1
	moveq	#3,d0
	C5LIB	GFX,SetAPen

	move.l	a2,a1
	moveq	#121,d0
	moveq	#28+36,d1
	add	topbor(a5),d1
	move	#119+258,d2
	moveq	#34+36,d3
	add	topbor(a5),d3
	CALL	RectFill
	rts

nomemforwindow
	CLIB	Exec,Permit
	addq.l	#4,sp
	bra	urgh
	
;;********* PREFS ***********

prefs	bsr	parse

	lea	prefwinstr(a5),a0
	C5LIB	Int,OpenWindow
	move.l	d0,winpoin(a5)
	beq	exit

event2	move.l	winpoin(a5),a0
	move.l	wd_UserPort(a0),a2
	move.b	15(a2),d1
	moveq	#0,d0
	bset	d1,d0
	CLIB	Exec,Wait
eventl	move.l	a2,a0
	CALL	GetMsg
	tst.l	d0
	beq.b	eventd

	move.l	d0,a1
	move.l	im_Class(a1),d2
	move.l	im_IAddress(a1),a4
	CALL	ReplyMsg
	bra.b	eventl

eventd	cmp.l	#GADGETUP,d2
	beq.b	Painettu2

	cmp.l	#GADGETDOWN,d2
	beq.b	Alas
	
	cmp.l	#CLOSEWINDOW,d2
	bne.b	event2

	move.l	winpoin(a5),a0
	move.l	wd_LeftEdge(a0),prefwinstr(a5)
	C5LIB	Int,CloseWindow
	bra	conttaa

Painettu2
	cmp.l	#sprefs,a4
	beq.b	saveprefs
	cmp.l	#lprefs,a4
	beq	loadda

	cmp.l	#one,a4
	blt.b	event2
	move	gg_GadgetID(a4),d0
	bchg	d0,flags+3(a5)
	bra	event2

Alas	tst.l	reqptr3(a5)
	bne.b	jatkuu3
	sub.l	a0,a0
	moveq	#RT_FILEREQ,d0
	C5LIB	RT,rtAllocRequestA
	move.l	d0,reqptr3(a5)
	beq	exit

jatkuu3	cmp.l	#rdl,a4
	beq	loaddir
	cmp.l	#rds,a4
	beq	savedir
	cmp.l	#rdb,a4
	beq	destdir
	bra	event2

saveprefs
	lea	prefsfile(a5),a0
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	C5LIB	DOS,Open
	move.l	d0,d4
	beq	event2

	move.l	d4,d1
	move.l	#prefsarea,d2
	move.l	#prefsend-prefsarea,d3
	CALL	Write

	move.l	d4,d1
	CALL	Close
	bra	event2


loadda	bsr.b	loadprefs
	pea	koala2(pc)
	bra	parse

loadprefs
	lea	prefsfile(a5),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	C5LIB	DOS,Open
	move.l	d0,d4
	beq.b	defaultprefs

	move.l	d4,d1
	move.l	#prefsarea,d2
	move.l	#prefsend-prefsarea,d3
	CALL	Read

	move.l	d4,d1
	CALL	Close

defaultprefs
	rts
	
loaddir	lea	dirtags(a5),a0
	move.l	reqptr3(a5),a1
	lea	defload(a5),a2
	lea	title4(a5),a3
	C5LIB	RT,rtFileRequestA
	tst.l	d0
	beq	event2

	lea	defload(a5),a2

koala	move.l	reqptr3(a5),a0
	move.l	16(a0),a0
.lops	move.b	(a0)+,(a2)+
	bne.b	.lops

koala2	lea	dl,a0
	move.l	winpoin(a5),a1
	sub.l	a2,a2
	C5LIB	Int,RefreshGadgets
	bra	event2

savedir	lea	dirtags(a5),a0
	move.l	reqptr3(a5),a1
	lea	defsave(a5),a2
	lea	title5(a5),a3
	C5LIB	RT,rtFileRequestA
	tst.l	d0
	beq	event2

	lea	defsave(a5),a2
	bra.b	koala

destdir	lea	dirtags(a5),a0
	move.l	reqptr3(a5),a1
	lea	defdest(a5),a2
	lea	title6(a5),a3
	C5LIB	RT,rtFileRequestA
	tst.l	d0
	beq	event2

	lea	defdest(a5),a2
	bra.b	koala

parse	lea	one(a5),a4
	move.l	flags(a5),d0
.loop	ror.l	d0
	bpl.b	.clear
	bset	#7,13(a4)
	bra.b	.nex
.clear	bclr	#7,13(a4)
.nex	move.l	(a4),d1
	beq.b	.poes
	move.l	d1,a4
	bra.b	.loop
.poes	rts

;;***** Da About Engine :-) *****

aboutti	lea	aboutlist(a5),a1
	move.l	a1,aboutpos(a5)
aboutloop
	CLIB	Exec,Forbid
	lea	winstr2(a5),a0
	C5LIB	Int,OpenWindow
	move.l	d0,winpoin(a5)

	lea	ntags(a5),a0
	lea	reqhandler(a5),a1
	move.l	a1,4(a0)
	move.l	winpoin(a5),12(a0)
	sub.l	a3,a3
	move.l	a3,a4
	move.l	aboutpos(a5),a1
	movem.l	(a1),a1/a2
	C5LIB	RT,rtEZRequestA
	cmp.l	#$80000000,d0
	beq.b	ukki

	CLIB	Exec,Permit
	bra	urgh

ukki	move.l	winpoin(a5),a0
	move.l	wd_WScreen(a0),a0
	move.l	sc_FirstWindow(a0),a0
	move.l	wd_RPort(a0),rast(a5)

	moveq	#5,d1
	add.b	wd_BorderTop(a0),d1

	lea	image(a5),a1
	move.l	rast(a5),a0
	moveq	#30,d0
	C5LIB	Int,DrawImage
	CLIB	Exec,Permit
	move.l	winpoin(a5),a0
	CALL	CloseWindow


kalina	move.l	reqhandler(a5),a0
	tst.l	rthi_DoNotWait(a0)
	beq.b	jatkumo
	move.l	rthi_WaitMask(a0),d0
	CLIB	Exec,Wait

jatkumo	move.l	reqhandler(a5),a1
	lea	Tagend(a5),a0
	move.l	rthi_WaitMask(a1),d0
	C5LIB	RT,rtReqHandlerA
	cmp.l	#$80000000,d0
	beq.b	kalina

	cmp	#2,d0
	beq	conttaa
	tst	d0
	bne.b	oikealle

	move.l	aboutpos(a5),a0
	tst.l	8(a0)
	beq	aboutloop
	addq.l	#8,aboutpos(a5)
	bra	aboutloop

oikealle
	move.l	aboutpos(a5),d0
	cmp.l	#aboutlist,d0
	beq	aboutloop
	subq.l	#8,aboutpos(a5)
	bra	aboutloop

****************************************
;; Cleanup

exit	lea	port(a5),a1
	tst.b	MP_SIGBIT(a1)
	bmi.b	noport
	CLIB	Exec,RemPort

noport	move.l	memory(a5),d0
	beq.b	nomem2
	move.l	d0,a1
	move.l	filelength(a5),d0
	CLIB	Exec,FreeMem

nomem2	move.l	reqptr(a5),d0
	beq.b	nodh
	move.l	d0,a1
	C5LIB	RT,rtFreeRequest

nodh	move.l	reqptr2(a5),d0
	beq.b	nodh2
	move.l	d0,a1
	C5LIB	RT,rtFreeRequest

nodh2	move.l	reqptr3(a5),d0
	beq.b	nodh3
	move.l	d0,a1
	C5LIB	RT,rtFreeRequest

nodh3	move.l	reqptr4(a5),d0
	beq.b	nodh4
	move.l	d0,a1
	C5LIB	RT,rtFreeRequest

nodh4	move.l	Lock(a5),d1
	beq.b	nolock
	C5LIB	DOS,UnLock

nolock	move.l	_RTBase(a5),a1
	CLIB	Exec,CloseLibrary

	move.l	_PPBase(a5),a1
	CALL	CloseLibrary

	move.l	_XPKBase(a5),d0
	beq.b	.d
	move.l	d0,a1
	CALL	CloseLibrary

.d	move.l	segment(a5),d1
	C5LIB	DOS,UnLoadSeg

	move.l	_DOSBase(a5),a1
	CLIB	Exec,CloseLibrary

	Pull	All
	moveq	#0,d0
	rts

*******************************

;; THE CONVERTER!

convert	move.l	memory(a5),a0
	move.l	converted(a5),a1
	clr.l	usec(a5)

	btst	#1,flags+3(a5)
	beq.b	nosign
	move.l	#'P61A',(a1)+

; Find highest used pattern

nosign	moveq	#0,d0
	move.b	950(a0),d0
	move	d0,poss(a5)
	subq	#1,d0
	moveq	#0,d1
	lea	952(a0),a2
opo	cmp.b	(a2)+,d1
	bhs.b	nothighest
	move.b	-1(a2),d1
nothighest
	dbf	d0,opo

	addq	#1,d1
	move	d1,patts(a5)
	move.l	d1,d6
	asl	#2,d6
	asl.l	#8,d6
	add.l	#1084,d6
	add.l	a0,d6

; Find real highest pattern

	moveq	#127,d0
	moveq	#0,d1
	lea	952(a0),a2
oppo	cmp.b	(a2)+,d1
	bhs.b	nothighest2
	move.b	-1(a2),d1
nothighest2
	dbf	d0,oppo

	addq	#1,d1
	asl	#2,d1
	asl.l	#8,d1
	add.l	#1084,d1
	move.l	d1,orgpatts(a5)
	add.l	a0,d1
	move.l	d1,samples(a5)

;;Useless-patterns-remover

	Push	a0/a1
	lea	1084(a0),a3

	moveq	#0,d4
.loop
	move	poss(a5),d7
	subq	#1,d7
	lea	952(a0),a2
.onko	cmp.b	(a2)+,d4		; Used?
	beq.b	.on
	dbf	d7,.onko

	lea	1024(a3),a4		;poiss...
	move.l	a3,a2
	cmp.l	a4,d6			; Original patterns' end
	beq.b	.on
.copy	move.l	(a4)+,(a2)+		; Move higher patterns
	cmp.l	a4,d6			; = remove unused pattern
	bne.b	.copy

	lea	952(a0),a2
	move	poss(a5),d7
	subq	#1,d7
.paiv	cmp.b	(a2)+,d4
	bhs.b	.uus
	subq.b	#1,-1(a2)		; Update higher pattern numbers
.uus	dbf	d7,.paiv

	subq	#1,patts(a5)
	sub.l	#1024,d6
	cmp	patts(a5),d4
	blo.b	.loop
	bra.b	paes

.on	lea	1024(a3),a3
	addq	#1,d4
	cmp	patts(a5),d4
	blo.b	.loop

paes	move.l	d6,pattend(a5)
	move.b	patts+1(a5),2(a1)

;;Print original patterns

	move.l	orgpatts(a5),d0
	lea	tbuff+6(a5),a0
	moveq	#5,d1
.con	divu	#10,d0
	swap	d0
	move.b	d0,-(a0)
	add.b	#'0',(a0)
	clr	d0
	swap	d0
	dbf	d1,.con

 ifd USER_INTERFACE	
	move.l	rast(a5),a1
	moveq	#1,d0

	C5LIB	GFX,SetAPen

	move.l	rast(a5),a1
	move	#121+256+34,d0
	moveq	#34+27,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	rast(a5),a1
	lea	tbuff(a5),a0
	moveq	#6,d0
	CALL	Text
 endc

	Pull	a0/a1

;; Search used samples

	lea	samplenum(a5),a4
	move.l	a4,a6
	moveq	#7,d1
.lop	clr.l	(a6)+
	dbf	d1,.lop

	lea	42(a0),a2

	lea	1084(a0),a0
	moveq	#0,d2
etsitaan
	moveq	#$10,d3
	and.b	(a0),d3
	move.b	2(a0),d2
	lsr	#4,d2
	or	d2,d3
	st	(a4,d3)
	addq.l	#4,a0
	cmp.l	pattend(a5),a0
	blt.b	etsitaan

	move.l	#sampleoffsetit,posu

	clr.l	consamples(a5)

;;Make sampleinfos

	lea	4(a1),a3
	btst	#6,flags+3(a5)			; Buffer size?
	beq.b	.kep
	addq.l	#4,a3
.kep	moveq	#0,d0

	move.l	a3,smpstr(a5)

	moveq	#1,d4
	moveq	#1,d5
	moveq	#30,d7
	move.l	samples(a5),d6
calcsamples
	tst.b	(a4,d4)				; Sample used?
	beq	samplezero

	addq	#1,d0

	cmp	#1,(a2)
	bhi.b	norm
	move	#1,6(a2)			; Do empty sample
	move	#1,(a3)
	move	#-1,4(a3)
	bra.b	rapa

norm	cmp	#1,6(a2)
	bhi.b	looping
	move.l	d6,a0
	moveq	#0,d3
	move	(a2),d3
	add.l	d3,a0
	add.l	d3,a0
.etsii	tst	-(a0)				; Remove empty data from end
	bne.b	poison
	subq	#1,d3
	bne.b	.etsii
	moveq	#1,d3
poison	move	d3,(a3)				; Sample length
	move	#-1,4(a3)			; Mark not looped
	bra.b	rapa

looping	moveq	#0,d3
	move	4(a2),d3
	moveq	#0,d2
	move	6(a2),d2
	add.l	d2,d3
	move	d3,(a3)				; Length = Loop start + end
	move	4(a2),4(a3)			; Copy loop start
rapa	move	2(a2),2(a3)
	and.b	#$f,2(a3)			; Finetune only lower nybble

	cmp.b	#64,3(a3)			; Check volume range
	bls.b	.ok
	move.b	#64,3(a3)
.ok
	tst.b	2(a3)
	beq.b	eifinee
	move	#1,usec+2			; Mark finetunes used

eifinee	moveq	#0,d2
	move.b	d5,(a4,d4)
	addq	#1,d5

	Push	d0/d7/a2/a4

	move.l	smpstr(a5),a2

	move	(a3),d0				; Length < 2 bytes?
	cmp	#1,d0
	bls.b	eipaloytynyt

;; Search same sampledata

	moveq	#0,d7
onkosamoja
	cmp.l	a2,a3
	beq.b	eipaloytynyt
	cmp	(a2),d0				; Same length?
	beq.b	samalength
uus	addq.l	#6,a2
	addq	#1,d7
	bra.b	onkosamoja

samalength
	lea	sampleoffsetit(a5),a0
	move.l	d6,a4

	move	d7,d2
	asl	#2,d2
	move.l	(a0,d2),a0
	move	d0,d2
	subq	#1,d2				; Length in words
comppaa	move	(a0)+,d3
	cmp	(a4)+,d3			; Same data?
	bne.b	uus
	dbf	d2,comppaa			; Until the end

	addq	#1,d7
	neg	d7
	move	d7,(a3)
	Pull	d0/d7/a2/a4
	bra.b	nextu

eipaloytynyt
	Pull	d0/d7/a2/a4
	moveq	#0,d3
	move	(a3),d3
	add.l	d3,d3
	add.l	d3,consamples(a5)

nextu	move.l	posu(a5),a0
	move.l	d6,(a0)+
	move.l	a0,posu(a5)

	addq.l	#6,a3				; Next P61-inst

samplezero
	moveq	#0,d3
	move	(a2),d3				; Advance pointer
	add.l	d3,d6
	add.l	d3,d6
	lea	30(a2),a2			; Next PT-inst
	addq	#1,d4
	dbf	d7,calcsamples
	move.b	d0,3(a1)			; Number of insts

	btst	#6,flags+3(a5)
	beq.b	.kep
	move.l	consamples(a5),4(a1)		; Sample buffer length
.kep	sub.l	samples(a5),d6
	move.l	d6,orgsamples(a5)		; Original samples' length

;;Print samplelengths

 ifd USER_INTERFACE	
	move.l	a1,a2
	move.l	d6,d0
	lea	tbuff+6(a5),a0
	moveq	#5,d1
.con	divu	#10,d0
	swap	d0
	move.b	d0,-(a0)
	add.b	#'0',(a0)
	clr	d0
	swap	d0
	dbf	d1,.con

	move.l	rast(a5),a1
	moveq	#1,d0
	C5LIB	GFX,SetAPen

	move.l	rast(a5),a1
	move	#121+256+34,d0
	moveq	#34+63,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	rast(a5),a1
	lea	tbuff(a5),a0
	moveq	#6,d0
	CALL	Text
 
	move.l	consamples(a5),d0
	lea	tbuff+6(a5),a0
	moveq	#5,d1
.con2	divu	#10,d0
	swap	d0
	move.b	d0,-(a0)
	add.b	#'0',(a0)
	clr	d0
	swap	d0
	dbf	d1,.con2

	move.l	rast(a5),a1
	move	#121+256+34,d0
	moveq	#34+72,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	rast(a5),a1
	lea	tbuff(a5),a0
	moveq	#6,d0
	CALL	Text
 endc	
	move.l	a2,a1
	
;; Prepare part 1
part1
	move.l	memory(a5),a0
	moveq	#0,d6
	move.l	filelength(a5),d0
	sub.l	orgsamples(a5),d0
	sub.l	#1084,d0
	add.l	consamples(a5),d0
	move.l	d0,conlength(a5)

	move.l	a3,posibase(a5)
	moveq	#0,d0
	move	poss(a5),d0
	addq	#1,d0
	add.l	d0,a3
	add.l	d0,conlength(a5)
	moveq	#0,d0
	move	patts(a5),d0
	lsl	#3,d0
	add.l	d0,a3
	add.l	d0,conlength(a5)
	move.l	a3,prepacked(a5)		; Pointer to final packed data

	move.l	a3,d0
	sub.l	a1,d0
	move.l	d0,conpatts(a5)
	move.l	orgpatts(a5),d0
	sub.l	#1084,d0
	add.l	d0,conpatts(a5)

	move.l	temporary(a5),a2		; Temporary buffer for part 1
	move.l	a2,pattebase(a5)
	move	patts(a5),d0
	move	d0,counter(a5)

	lsl	#2,d0
	move	d0,fullpatt(a5)
	clr	nowpatt(a5)
	clr	dataend(a5)

;; Pack channels part 1

	clr	break(a5)

	lea	1084(a0),a3
	move	patts(a5),counter(a5)
	lea	patterns,a4			; Track offsets
	moveq	#4,d1				; Offsets to other channels
	moveq	#8,d2				; on same row inside pattern
	moveq	#12,d3
	bsr	packchannel

	move.l	memory(a5),a0
	lea	1088(a0),a3
	move	patts(a5),counter(a5)
	lea	patterns+2,a4
	moveq	#-4,d1
	moveq	#4,d2
	moveq	#8,d3
	bsr	packchannel

	move.l	memory(a5),a0
	lea	1092(a0),a3
	move	patts(a5),counter(a5)
	lea	patterns+4,a4
	moveq	#-8,d1
	moveq	#-4,d2
	moveq	#4,d3
	bsr	packchannel

	move.l	memory(a5),a0
	lea	1096(a0),a3
	move	patts(a5),counter(a5)
	lea	patterns+6,a4
	moveq	#-12,d1
	moveq	#-8,d2
	moveq	#-4,d3
	bsr	packchannel

	move	d6,dataend(a5)			; Packed data end after
						; part 1
	
;; *** PART 2 ! = search same data
* Includes striping unused data (ie. no note / command etc.)

* P61 Pattern Format:

* o = If set compression info follows
* n = Note (6 bits)
* i = Instrument (5 bits)
* c = Command (4 bits)
* b = Info byte (8 bits)

* onnnnnni iiiicccc bbbbbbbb	Note, instrument and command
* o110cccc bbbbbbbb		Only command
* o1110nnn nnniiiii		Note and instrument
* o1111111			Empty note

* Compression info:

* 00nnnnnn		 	n empty rows follow
* 10nnnnnn		 	n same rows follow (for faster testing)
* 01nnnnnn oooooooo		Jump o (8 bit offset) bytes back for n rows
* 11nnnnnn oooooooo oooooooo	Jump o (16 bit offset) bytes back for n rows


part2	moveq	#0,d7
	move	patts(a5),d7
	lsl	#2,d7
	move	d7,fullpatt(a5)
	clr	nowpatt(a5)

	move.l	prepacked(a5),a1	;mihin
	move.l	#patterns,d6		;patternilista
	move	#4,chans(a5)
	move.l	temporary(a5),a3	;alku mista

; First data can't be packed

	bsr	putdata
	
chanloop
	move.l	d6,a2
	addq.l	#2,d6
	move	patts(a5),d7
	subq	#1,d7
patternloop
	addq.l	#8,a2			; Next track on same channel
	moveq	#0,d0
	move	(a2),d0
	move.l	temporary(a5),a6
	add.l	d0,a6			; Start of next track =
					; End of this track
dataloop
	cmp.l	a6,a3
	bge	seuraavapattern

	move.l	(a3),d0			; Data to compare
	bsr	convpdata		; "Denormalize"
	
	move.l	prepacked(a5),a0
uusiks	moveq	#0,d5
etsi
	move.l	a0,d2			; Pointer to data saved

	bsr	fetchdata		; Fetches one packed P61 data
					; from a0 to d1 and advances pointer
	
	cmp.l	d1,d0
	beq.b	loyty
		
	cmp.l	a1,a0
	blt.b	etsi

	bra	fuk_loppu

loyty	lea	4(a3),a4
	move.l	a0,d3

	cmp.l	a6,a4
	bge.b	fuk_loppu
	cmp.l	a1,a0
	bge.b	fuk_loppu

	move.l	(a4)+,d0		; Data to compare
	bsr	convpdata		; "Denormalize"
	bsr	fetchdata
	cmp.l	d0,d1
	beq.b	toinensama

	move.l	(a3),d0			; Data to compare
	bsr	convpdata
	move.l	d3,a0
	bra.b	uusiks			; To next data

toinensama
	moveq	#1,d5			;voitto nuotteina-1
	cmp.l	a1,a0
	bge.b	eienaa
	cmp.l	a6,a4
	bge.b	eienaa
montako
	move.l	(a4),d0
	bsr	convpdata
	bsr	fetchdata
	cmp.l	d1,d0
	bne.b	eienaa

	addq.l	#4,a4
	addq	#1,d5
	cmp.l	a1,a0
	bge.b	eienaa
	cmp.l	a6,a4
	blt.b	montako

eienaa	move.l	a0,d1
	sub.l	d2,d1

	subq.l	#3,d1				; Taken up by dummy note,
						; length and 8-bit offset
	move.l	a1,d0
	sub.l	d2,d0
	cmp.l	#256,d0
	blt.b	.bit8
	subq.l	#1,d1				; 16-bit offset

.bit8	cmp	bestreallength(a5),d1
	ble.b	.seuraava
	move.l	d2,bestoffset(a5)
	move	d5,bestlength(a5)
	move	d1,bestreallength(a5)
.seuraava
	move.l	(a3),d0
	bsr	convpdata
	move.l	d3,a0
	bra	uusiks				; To next data
	
fuk_loppu

	move.l	bestoffset(a5),d0
	beq.b	pistadata

	move.b	#$ff,(a1)+			; Dummy row + comp.info
	moveq	#0,d1
	move	bestlength(a5),d1
	move.b	d1,(a1)
	lsl.l	#2,d1
	addq.l	#4,d1
	add.l	d1,a3	
	subq.l	#3,d1
	sub.l	d1,conpatts(a5)

	move.l	a1,d1
	addq.l	#2,d1
	sub.l	d0,d1
	cmp.l	#256,d1
	bge.b	.bit16

	or.b	#%01000000,(a1)+
	move.b	d1,(a1)+			; 8-bit offset
	bra.b	.juuh
.bit16	
	addq.l	#1,conpatts(a5)
	addq.l	#1,d1
	or.b	#%11000000,(a1)+
	rol	#8,d1
	move.b	d1,(a1)+
	rol	#8,d1
	move.b	d1,(a1)+

.juuh	clr.l	bestoffset(a5)
	clr	bestlength(a5)
	clr	bestreallength(a5)
	bra	dataloop

pistadata
	pea	dataloop(pc)
	bra	putdata

seuraavapattern
	move.l	a1,d4
	sub.l	prepacked(a5),d4
	move	d4,(a2)				; Final pattern offset

	addq	#1,nowpatt(a5)
	bsr	do_bars2
	dbf	d7,patternloop

	subq	#1,chans(a5)
	beq.b	lappu

	move.l	d6,a2
	move	d4,(a2)
	bra	chanloop

lappu	
	sub.l	prepacked(a5),a1
	move	a1,dataend(a5)
	bra	kiles



; Puts one data from original P61 data in a3 to packed stream in a1
; Both pointers are advanced accordingly

putdata	move.b	(a3),d0
	move.b	d0,d1
	and.b	#$80,d1			; comp.info?
	move.b	d0,d2
	and	#$7e,d2			; Only note
	bne.b	.note

	move	(a3),d0
	and	#$1f0,d0
	bne.b	.note

	moveq	#$f,d0
	and.b	1(a3),d0
	beq.b	.empty

.cmd					; only command
	or.b	#%01100000,d0		; Mark Only command
	or.b	d1,d0
	move.b	d0,(a1)+
	bmi.b	.comp			; Comp.info?
	move.b	2(a3),(a1)+		; Info byte
	subq.l	#2,conpatts(a5)
	bra.b	.ex

.comp	move.b	2(a3),(a1)+		; Info byte
	move.b	3(a3),(a1)+		; Comp.info
	subq.l	#1,conpatts(a5)
	bra.b	.ex


.empty	subq.l	#3,conpatts(a5)
	move.b	#$7f,d0
	or.b	d1,d0
	move.b	d0,(a1)+
	bpl.b	.ex			; No comp.info
	move.b	3(a3),(a1)+		; Comp.info
	addq.l	#1,conpatts(a5)
	bra.b	.ex

.note	moveq	#$f,d0
	and.b	1(a3),d0
	beq.b	.onlynote

.all	move.b	(a3)+,(a1)+		; Copy note + inst
	move.b	(a3)+,(a1)+		; inst + cmd
	move.b	(a3)+,(a1)+		; info byte
	tst.b	d1
	bmi.b	.comp2			; Comp.info?
	addq.l	#1,a3
	subq.l	#1,conpatts(a5)
	bra.b	.ex2
.comp2	move.b	(a3)+,(a1)+
	bra.b	.ex2


.onlynote				; Only note and/or inst
	move	(a3),d0
	and	#$7ff0,d0		; Comp info and cmd off
	lsr	#4,d0			; Command off
	move.b	d0,d2
	lsr	#8,d0
	or.b	#%01110000,d0		; Only note
	or.b	d1,d0			; Comp.info
	move.b	d0,(a1)+
	move.b	d2,(a1)+
	subq.l	#2,conpatts(a5)

	tst.b	d1
	bpl.b	.ex			; No comp.info
	move.b	3(a3),(a1)+
	addq.l	#1,conpatts(a5)

.ex	addq.l	#4,a3
.ex2	rts



putdata2
	move.b	(a3),d0
	move.b	d0,d1
	and.b	#$80,d1			; comp.info?
	move.b	d0,d2
	and	#$7e,d2			; Only note
	bne.b	.note

	move	(a3),d0
	and	#$1f0,d0
	bne.b	.note

	moveq	#$f,d0
	and.b	1(a3),d0
	beq.b	.empty

.cmd					; only command
	or.b	#%01100000,d0		; Mark Only command
	or.b	d1,d0
	move.b	d0,(a1)+
	bmi.b	.comp			; Comp.info?
	move.b	2(a3),(a1)+		; Info byte
	bra.b	.ex

.comp	move.b	2(a3),(a1)+		; Info byte
	move.b	3(a3),(a1)+		; Comp.info
	bra.b	.ex


.empty	move.b	#$7f,d0
	or.b	d1,d0
	move.b	d0,(a1)+
	bpl.b	.ex			; No comp.info
	move.b	3(a3),(a1)+		; Comp.info
	bra.b	.ex

.note	moveq	#$f,d0
	and.b	1(a3),d0
	beq.b	.onlynote

.all	move.b	(a3)+,(a1)+		; Copy note + inst
	move.b	(a3)+,(a1)+		; inst + cmd
	move.b	(a3)+,(a1)+		; info byte
	tst.b	d1
	bmi.b	.comp2			; Comp.info?
	addq.l	#1,a3
	bra.b	.ex2
.comp2	move.b	(a3)+,(a1)+
	bra.b	.ex2


.onlynote				; Only note and/or inst
	move	(a3),d0
	and	#$7ff0,d0		; Comp info and cmd off
	lsr	#4,d0			; Command off
	move.b	d0,d2
	lsr	#8,d0
	or.b	#%01110000,d0		; Only note
	or.b	d1,d0			; Comp.info
	move.b	d0,(a1)+
	move.b	d2,(a1)+

	tst.b	d1
	bpl.b	.ex			; No comp.info
	move.b	3(a3),(a1)+
.ex	addq.l	#4,a3
.ex2	rts


; Fetches one data from packed P61 data stream in a0 to d1 "normalized"
; Pointer is advanced accordingly

fetchdata
	move.l	d2,-(sp)
	moveq	#0,d1
	move.b	(a0)+,d1

	move.b	d1,d2
	and	#%01100000,d2
	cmp	#%01100000,d2
	bne.b	.all

	move.b	d1,d2
	and	#%01110000,d2
	cmp	#%01100000,d2
	beq.b	.onlycmd

	move.b	d1,d2
	and	#%01111000,d2
	cmp	#%01110000,d2
	beq.b	.onlynote

.empty	tst.b	d1
	bpl.b	.ex
	lsl	#8,d1

	move.b	(a0)+,d1
	move.b	d1,d2
	and	#%11000000,d2
	beq.b	.ex
	cmp.b	#$80,d2
	beq.b	.ex
	addq.l	#1,a0				; Skip 8-bit offset
	cmp.b	#$c0,d2
	bne.b	.ex				; No 16-bit
	addq.l	#1,a0
	bra.b	.ex

.onlycmd
.onlynote
; Same as we have to fetch 2 bytes (+ possible comp.info)
	lsl	#8,d1
	move.b	(a0)+,d1
	tst	d1
	bpl.b	.ex
	lsl.l	#8,d1
	move.b	(a0)+,d1
	bra.b	.ex


.all	lsl	#8,d1
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1

	btst	#23,d1				; comp.info?
	beq.b	.ex
	lsl.l	#8,d1
	move.b	(a0)+,d1

.ex	move.l	(sp)+,d2
	rts



; Converts one P61 data in D0 to packed P61 data

convpdata
	Push	a0/a1/a3/d1/d2
	lea	t_src(a5),a3
	lea	t_dest(a5),a1
	move.l	d0,(a3)
	bsr	putdata2
	lea	t_dest(a5),a0
	bsr	fetchdata
	move.l	d1,d0
	Pull	a0/a1/a3/d1/d2
	rts


;; Do bars for part 2
do_bars2
 ifd USER_INTERFACE	
	Push	a0-a2/a6
	move.l	reqhandler(a5),a1
	sub.l	a0,a0
	C5LIB	RT,rtReqHandlerA
	cmp.l	#$80000000,d0
	bne	stopp

	move	fullpatt(a5),d0
	moveq	#0,d3
	move	nowpatt(a5),d3
	lsl.l	#8,d3
	divu	d0,d3

	move.l	rast(a5),a2
	move.l	a2,a1
	moveq	#1,d0
	C5LIB	GFX,SetAPen

	move.l	a2,a1
	moveq	#122,d0
	add	d3,d0
	moveq	#28+9,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	moveq	#122,d0
	add	d3,d0
	moveq	#34+9,d1
	add	topbor(a5),d1
	CALL	Draw

	move.l	a2,a1
	moveq	#3,d0
	CALL	SetAPen

	move.l	a2,a1
	moveq	#121,d0
	moveq	#28+9,d1
	add	topbor(a5),d1
	moveq	#121,d2
	add	d3,d2
	moveq	#34+9,d3
	add	topbor(a5),d3
	CALL	RectFill

	move.l	orgpatts(a5),d0
	lsr.l	#4,d0
	move.l	conpatts(a5),d3
	lsr.l	#4,d3
	lsl.l	#8,d3
	divu	d0,d3

	move.l	a2,a1
	moveq	#1,d0
	CALL	SetAPen

	move.l	a2,a1
	moveq	#120,d0
	add	d3,d0
	moveq	#28+36,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	moveq	#120,d0
	add	d3,d0
	moveq	#34+36,d1
	add	topbor(a5),d1
	CALL	Draw

	move.l	a2,a1
	moveq	#0,d0
	CALL	SetAPen

	move.l	a2,a1
	moveq	#121,d0
	add	d3,d0
	moveq	#28+36,d1
	add	topbor(a5),d1
	move	#121+256,d2
	moveq	#34+36,d3
	add	topbor(a5),d3
	CALL	RectFill

	move.l	a2,a1
	moveq	#1,d0
	CALL	SetAPen

	move.l	conpatts(a5),d0
	lea	tbuff+6(a5),a0
	moveq	#5,d1
.con2	divu	#10,d0
	swap	d0
	move.b	d0,-(a0)
	add.b	#'0',(a0)
	clr	d0
	swap	d0
	dbf	d1,.con2

	move.l	a2,a1
	move	#121+256+34,d0
	moveq	#34+36,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	lea	tbuff(a5),a0
	moveq	#6,d0
	CALL	Text

	move.l	orgpatts(a5),d0
	sub.l	conpatts(a5),d0
	move.l	d0,d2
	lea	tbuff+6(a5),a0
	moveq	#5,d1
.con	divu	#10,d0
	swap	d0
	move.b	d0,-(a0)
	add.b	#'0',(a0)
	clr	d0
	swap	d0
	dbf	d1,.con

	move.l	a2,a1
	move	#121+256+34,d0
	moveq	#34+45,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	lea	tbuff(a5),a0
	moveq	#6,d0
	CALL	Text

	mulu	#50,d2
	move.l	orgpatts(a5),d0
	asr.l	#1,d0
	divu	d0,d2
	moveq	#0,d0
	move	d2,d0
	lea	tbuff(a5),a0
	divu	#10,d0
	add.b	#'0',d0
	move.b	d0,(a0)+
	swap	d0
	add.b	#'0',d0
	move.b	d0,(a0)

	move.l	a2,a1
	move	#121+256+2,d0
	moveq	#34+45,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	lea	tbuff(a5),a0
	moveq	#2,d0
	CALL	Text

	Pull	a0-a2/a6
 endc
	rts

;; Position and pattern pointers
kiles
	moveq	#0,d0
	move	dataend(a5),d0
	add.l	prepacked(a5),d0
	moveq	#1,d1
	and.l	d0,d1
	add.l	d1,d0
	move.l	d0,samplebase(a5)

	move.l	memory(a5),a0
	move.l	posibase(a5),a2
	lea	952(a0),a3
	move.l	converted(a5),a1
	btst	#1,flags+3(a5)
	beq.b	nosign2
	addq.l	#4,a1

nosign2	move	patts(a5),d7
	subq	#1,d7
	lea	patterns,a4
lipo	move.l	(a4)+,(a2)+			; Copy track pointers
	move.l	(a4)+,(a2)+
	dbf	d7,lipo

	btst	#6,flags+3(a5)
	beq.b	.kep
	or.b	#$40,3(a1)			; 4-bit delta samples
.kep	btst	#5,flags+3(a5)
	beq.b	eideltaa
	or.b	#$80,3(a1)			; 8-bit delta samples
eideltaa
	move	poss(a5),d7
	subq	#1,d7
.copy	move.b	(a3)+,(a2)+			; Copy positions
	dbf	d7,.copy
	st	(a2)+				; End mark $ff

;; Final savings
	
	move.l	samplebase(a5),d1
	move.l	d1,d3
	sub.l	a1,d1
	move	d1,(a1)				; Offset to samples
	sub.l	converted(a5),d3
	move.l	d3,conlength(a5)

	move.l	a1,-(sp)
	move.l	temporary(a5),a1
	move.l	buffer(a5),d0
	CLIB	Exec,FreeMem
	clr.l	temporary(a5)
	move.l	(sp)+,a1
	
	btst	#6,flags+3(a5)			; 4-bit deltas?
	beq	seivaa
	
;;pack or not
	
	bset	#1,$bfe001
	
	moveq	#$1f,d7
	and.b	3(a1),d7
	subq	#1,d7

	moveq	#1,d6				; sample number

	lea	8(a1),a1
	clr	break(a5)
	lea	sampleoffsetit(a5),a2

	clr	pakattuja(a5)
	clr.l	sbuflen(a5)
	
	tst	fromport(a5)
	bne	puisto
	
	tst	batch(a5)
	bne.b	packrest

samplesss
	tst	(a1)
	bmi	dont2
	beq	dont
	cmp	#1,(a1)
	beq	dont

	tst	break(a5)
	bne.b	joopack

kepukka	movem.l	a1/a2,-(sp)
	lea	muuttujat,a4
	move.l	a4,a0
	move.l	d6,(a0)+
	lea	samplenum(a5),a1
	move.l	d6,d0
.l	cmp.b	(a1,d0.l),d6
	beq.b	.found
	addq.l	#1,d0
	bra.b	.l

.found	move.l	d0,(a0)+
	move.l	memory(a5),a1
	lea	20(a1),a1
	subq	#1,d0
	mulu	#30,d0
	add	d0,a1
	move.l	a1,(a0)

	lea	tags(a5),a0
	sub.l	a3,a3
	lea	pack(a5),a1
	lea	packg(a5),a2
	C5LIB	RT,rtEZRequestA
	movem.l	(sp)+,a1/a2

	subq	#1,d0
	bmi.w	puisto
	beq.b	playorg
	subq	#1,d0
	beq.b	playpack
	subq	#1,d0
	beq.b	joopack
	subq	#1,d0
	bne.w	dont

packrest
	st	break(a5)
joopack	or.b	#$80,2(a1)
	st	pakattuja(a5)
	bra.w	dont

playorg	bsr	varaa
	tst.l	d0
	beq	samplesss
	move.l	d0,-(sp)

	move.l	d0,a3
	move.l	(a2),a4
	move	(a1),d4
	subq	#1,d4
.cop	move	(a4)+,(a3)+
	dbf	d4,.cop
	bra	plei

playpack
	moveq	#0,d0
	move	(a1),d0
	add.l	d0,d0
	moveq	#MEMF_PUBLIC,d1
	move.l	a1,a3
	CLIB	Exec,AllocMem
	move.l	a3,a1

	tst.l	d0
	beq	samplesss

	move.l	d0,a3
	move.l	(a2),a4
	move	(a1),d4
	subq	#1,d4
.cop	move	(a4)+,(a3)+
	dbf	d4,.cop

	move.l	d0,a4
	move	(a1),d3
	bsr	spacker				; Pack sample

	move.l	d0,d2

	bsr	varaa
	tst.l	d0
	bne.b	kepd

	move.l	a1,a3
	moveq	#0,d0
	move	(a1),d0
	add.l	d0,d0
	move.l	d2,a1
	CLIB	Exec,FreeMem
	move.l	a3,a1
	bra	samplesss

kepd	move.l	d0,-(sp)
	move.l	d0,a6
	move	(a1),d0
	subq	#1,d0

	moveq	#0,d5
	moveq	#0,d4
.lo	move.b	(a4)+,d4			; Depack
	moveq	#$f,d3
	and	d4,d3
	lsr	#4,d4

	sub.b	.table(pc,d4),d5
	move.b	d5,(a6)+
	sub.b	.table(pc,d3),d5
	move.b	d5,(a6)+
	dbf	d0,.lo

	moveq	#0,d0
	move	(a1),d0
	add.l	d0,d0
	move.l	a1,a3
	move.l	d2,a1
	CLIB	Exec,FreeMem
	move.l	(sp),d0
	move.l	a3,a1
	bra.b	plei

.table dc.b	0,1,2,4,8,16,32,64,128,-64,-32,-16,-8,-4,-2,-1

varaa	moveq	#0,d0
	move	(a1),d0
	add.l	d0,d0
	moveq	#MEMF_CHIP,d1
	move.l	a1,a3
	CLIB	Exec,AllocMem
	move.l	a3,a1
	rts

plei	move.l	d0,d1
	moveq	#0,d2
	move	4(a1),d2
	bpl.b	.kep
	move.l	d0,d1
	moveq	#1,d4
	move	(a1),d3
	bra.b	.kop
.kep	add.l	d2,d1
	add.l	d2,d1
	move	(a1),d3
	move	d3,d4
	sub	d2,d4

.kop	lea	$dff0a0,a4
	move	#$f,$96-$a0(a4)
	move.l	d0,(a4)
	move	d3,4(a4)
	move	#214,6(a4)
	move	#64,8(a4)
	move.l	d0,$10(a4)
	move	d3,$14(a4)
	move	#214,$16(a4)
	move	#64,$18(a4)
	bsr	wenaa
	move	#$8003,$96-$a0(a4)
	bsr	wenaa
	move.l	d1,(a4)
	move	d4,4(a4)
	move.l	d1,$10(a4)
	move	d4,$14(a4)
.wen	btst	#10,$16-$a0(a4)
	bne.b	.wen
	move	#$f,$96-$a0(a4)

	moveq	#0,d0
	move	(a1),d0
	add.l	d0,d0
	move.l	a1,a3
	move.l	(sp)+,a1
	CALL	FreeMem
	move.l	a3,a1
	bra	kepukka

wenaa	move.b	6-$a0(a4),d0
	addq.b	#7,d0
.wen	cmp.b	6-$a0(a4),d0
	bgt.b	.wen
	rts

dont	addq.l	#4,a2
dont2	lea	6(a1),a1
	addq.l	#1,d6
	dbf	d7,samplesss

puisto	tst	pakattuja(a5)
	beq.b	.over

	move.l	converted(a5),a0
	btst	#1,flags+3(a5)
	beq.b	.nq
	addq.l	#4,a0
.nq	move.l	4(a0),sbuflen(a5)
	bra	seivaa

.over	move.l	converted(a5),a2	;Packing option on, no packed samples
	move.l	a2,d2
	move.l	file(a5),d1
	moveq	#4,d3
	btst	#1,flags+3(a5)
	beq.b	.na
	addq.l	#4,d3
	addq.l	#4,a2
.na	subq	#4,(a2)
	moveq	#0,d4
	move	(a2),d4
	subq	#4,d4
	and.b	#~$40,3(a2)
	addq.l	#8,a2
	C5LIB	DOS,Write

	move.l	a2,d2
	move.l	file(a5),d1
	move.l	d4,d3
	CALL	Write

	subq.l	#4,conlength(a5)
	bra.b	heppa

seivaa	move.l	file(a5),d1
	move.l	converted(a5),d2
	move.l	conlength(a5),d3
		
	C5LIB	DOS,Write

;; Save samples

heppa	tst	fromport(a5)
	bne.b	onefile
	
	btst	#2,flags+3(a5)			; No samples option on?
	bne	pike

	btst	#0,flags+3(a5)			; Two files?
	beq.b	onefile

	move.l	file2(a5),d6
	bne.b	cnoc

onefile	
		move.l	file(a5),d6
cnoc	move.l	memory(a5),a0
	lea	42(a0),a0
	move.l	converted(a5),a1
	btst	#1,flags+3(a5)
	beq.b	na
	addq.l	#4,a1				; Sign
na	addq.l	#4,a1
	btst	#6,flags+3(a5)
	beq.b	.kep
	addq.l	#4,a1				; Buffer length
.kep	move.l	samples(a5),a4
	moveq	#30,d7
	lea	samplenum(a5),a3
	moveq	#1,d4
samplewriteloop
	move.l	d6,d1
	tst.b	(a3,d4)				; Sample used?
	beq.w	nowrite

	cmp	#1,(a1)
	bne.b	normisample

	move.l	#tyhjasample,d2			; Do empty sample
	moveq	#2,d3
	Push	a0/a1
	add.l	d3,conlength(a5)
	CALL	Write
	Pull	a0/a1
	bra.b	wrote

normisample
	moveq	#0,d3
	move	(a1),d3
	bmi.b	wrote				; Uses same data?

	tst.b	2(a1)
	bmi	spacker2			; To be packed?

	add.l	d3,d3
	btst	#5,flags+3(a5)
	bne	deltaa				; Do 8-bit delta

tokas	move.l	a4,d2
	Push	a0/a1
	add.l	d3,conlength(a5)
	CALL	Write
	Pull	a0/a1

wrote	lea	6(a1),a1			; Next P61-sample
nowrite	moveq	#0,d5
	move	(a0),d5				; Advance pointer
	add.l	d5,d5
	add.l	d5,a4
	lea	30(a0),a0			; Next PT-sample
	addq	#1,d4
	Push	d1/a0/a1/a6
	move.l	reqhandler(a5),a1
	sub.l	a0,a0

 ifd USER_INTERFACE	
	C5LIB	RT,rtReqHandlerA
	cmp.l	#$80000000,d0
	bne.b	stopp2
 endc
	Pull	d1/a0/a1/a6
	dbf	d7,samplewriteloop
pike	rts

;; Stop routines
stopp	Pull	a0-a2/a6
	addq.l	#4,sp
	st	stopfl(a5)
	rts

stopp2	Pull	d1/a0/a1/a6
	st	stopfl(a5)
	rts

stopp3	Pull	d1-d3/a0-a2/a6
	addq.l	#8,sp
	st	stopfl(a5)
	rts

;; SamplePacker

spacker2
	pea	tokas(pc)

spacker	movem.l	d0-a6,-(sp)
	move.l	d3,d7
	subq.l	#1,d7
	move.l	a4,a1

	lea	table(pc),a2
	moveq	#0,d5				;delta start
loop	move.b	(a4)+,d0
	ext	d0
	move.l	a2,a0
	moveq	#temp-table-1,d6
	moveq	#127,d4
.l	move.b	d5,d1
	sub.b	(a0)+,d1
	ext	d1
	sub	d0,d1
	bpl.b	.d
	neg	d1
.d	cmp	d1,d4
	bgt.b	.qde
	dbf	d6,.l
	bra.b	.t

.qde	move.l	a0,a5
	move	d1,d4
	dbf	d6,.l

.t	subq.l	#1,a5
	sub.b	(a5),d5
	sub.l	a2,a5
	move	a5,d3
	lsl.b	#4,d3

data2	move.b	(a4)+,d0
	ext	d0
	move.l	a2,a0
	moveq	#temp-table-1,d6
	moveq	#127,d4
.l	move.b	d5,d1
	sub.b	(a0)+,d1
	ext	d1
	sub	d0,d1
	bpl.b	.d
	neg	d1
.d	cmp	d1,d4
	bgt.b	.qde
	dbf	d6,.l
	bra.b	.t

.qde	move.l	a0,a5
	move	d1,d4
	dbf	d6,.l

.t	subq.l	#1,a5
	sub.b	(a5),d5
	sub.l	a2,a5
	add	a5,d3
	move.b	d3,(a1)+

	subq.l	#1,d7
	bne.b	loop
	movem.l	(sp)+,d0-a6
	rts

table	dc.b	0,1,2,4,8,16,32,64,128,-64,-32,-16,-8,-4,-2,-1
temp


;; 8-bit delta-converter
deltaa	movem.l	d0/d1/a0,-(sp)
	move.l	d3,d0
	subq.l	#1,d0
	move.l	a4,a0
	move.b	(a0)+,d1
.loop	move.b	(a0),d2
	sub.b	d2,d1
	move.b	d1,(a0)+
	move.b	d2,d1
	subq.l	#1,d0
	bne.b	.loop
	movem.l	(sp)+,d0/d1/a0
	bra	tokas


;; Part 1 Packer 
packchannel
packloop
	move	d6,(a4)
	addq.l	#8,a4

	move.l	(a3),d4
	bsr	conv
	move.l	a2,cha0(a5)			; Save pointer
	move.l	d5,cha0+4(a5)			; Save data
	move.l	d5,(a2)+			; Put data

	move	2(a3,d1),d4
	and	#$f00,d4
	cmp	#$b00,d4
	beq.b	ddjjd
	cmp	#$d00,d4
	bne.b	djjd
ddjjd	tst	break(a5)
	beq.b	.kalle
	and	#$f000,2(a3,d1)			; Remove B and D commands
.kalle	st	break(a5)
djjd
	move	2(a3,d2),d4
	and	#$f00,d4
	cmp	#$b00,d4
	beq.b	ddjjd2
	cmp	#$d00,d4
	bne.b	djjd2
ddjjd2	tst	break(a5)
	beq.b	.kalle
	and	#$f000,2(a3,d2)			; Remove B and D commands
.kalle	st	break(a5)
djjd2
	move	2(a3,d3),d4
	and	#$f00,d4
	cmp	#$b00,d4
	beq.b	ddjjd3
	cmp	#$d00,d4
	bne.b	djjd3
ddjjd3	tst	break(a5)
	beq.b	.kalle
	and	#$f000,2(a3,d3)			; Remove B and D commands
.kalle	st	break(a5)
djjd3
	lea	16(a3),a3			; Next row

	addq.l	#4,d6				; Length always 4 bytes

	tst	break(a5)
	beq.b	goon2
	moveq	#63,d7
	bra	enda
goon2
	moveq	#62,d7		;number of rows
luup
	move.l	(a3),d4
	bsr	conv
	move.l	cha0(a5),a0
	tst.b	(a0)
	bpl.b	kodda				; No compression info
	tst.b	3(a0)
	bmi.b	moresame			; Previous data same
	bne.b	morezero			; Previous data zero

kodda	tst.l	d5				; No packing on previous row
	beq.b	zeroo				; Current data zero?

	cmp.l	cha0+4(a5),d5
	bne.b	oksa				; Same as last row?
	or.b	#$80,(a0)			; Mark compression info
	move.b	#%10000001,3(a0)		; 1 same data
	lea	conpatts(a5),a0
	subq.l	#4,(a0)				; 4 bytes saved
	bra.b	nexa

zeroo	or.b	#$80,(a0)			; Mark compression info
	move.b	#1,3(a0)			; 1 empty row
	lea	conpatts(a5),a0
	subq.l	#4,(a0)				; 4 bytes saved
	bra.b	nexa

morezero
	tst.l	d5				; Previous data was empty
	bne.b	oksa				; This data too?
	addq.b	#1,3(a0)			; Add one more
	lea	conpatts(a5),a0
	subq.l	#4,(a0)				; 4 bytes saved
	bra.b	nexa

oksa	move.l	a2,cha0(a5)			; No compression, save datas
	move.l	d5,cha0+4(a5)
	move.l	d5,(a2)+
	addq.l	#4,d6
	bra.b	nexa

moresame
	cmp.l	cha0+4(a5),d5			; Same as previous data?
	bne.b	oksa
	addq.b	#1,3(a0)			; One more same
	lea	conpatts(a5),a0
	subq.l	#4,(a0)				; 4 bytes saved

nexa	move	2(a3,d1),d4
	and	#$f00,d4
	cmp	#$b00,d4
	beq.b	tdjjd
	cmp	#$d00,d4
	bne.b	tjjd
tdjjd	tst	break(a5)
	beq.b	.kille
	and	#$f000,2(a3,d1)			; Remove D and B - commands
.kille	st	break(a5)
tjjd

	move	2(a3,d2),d4
	and	#$f00,d4
	cmp	#$b00,d4
	beq.b	tdjjd2
	cmp	#$d00,d4
	bne.b	tjjd2
tdjjd2	tst	break(a5)
	beq.b	.kille
	and	#$f000,2(a3,d2)			; Remove D and B - commands
.kille	st	break(a5)
tjjd2
	move	2(a3,d3),d4
	and	#$f00,d4
	cmp	#$b00,d4
	beq.b	tdjjd3
	cmp	#$d00,d4
	bne.b	tjjd3
tdjjd3	tst	break(a5)
	beq.b	.kille
	and	#$f000,2(a3,d3)			; Remove D and B - commands
.kille	st	break(a5)
tjjd3
	lea	16(a3),a3			; Next row

	tst	break(a5)
	bne.b	enda				; Break!
goon	dbf	d7,luup				; Do all rows
	bra.b	nexy
enda	tst	d7
	beq.b	nexy
	asl	#4,d7
	lea	(a3,d7),a3			; To pattern end
nexy	clr	break(a5)
	addq	#1,nowpatt(a5)
	bsr.b	do_bars
	subq	#1,counter(a5)			; Do all patterns
	bne	packloop
	move	d6,(a4)
	rts

;; Do bars for part 1

do_bars	
 ifd USER_INTERFACE	
	Push	d1-d3/a0-a2/a6
	move.l	reqhandler(a5),a1
	sub.l	a0,a0
	C5LIB	RT,rtReqHandlerA
	cmp.l	#$80000000,d0
	bne	stopp3

	move	fullpatt(a5),d0
	moveq	#0,d3
	move	nowpatt(a5),d3
	lsl.l	#8,d3
	divu	d0,d3

	move.l	rast(a5),a2
	move.l	a2,a1
	moveq	#1,d0
	C5LIB	GFX,SetAPen

	move.l	a2,a1
	moveq	#122,d0
	add	d3,d0
	moveq	#28,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	moveq	#122,d0
	add	d3,d0
	moveq	#34,d1
	add	topbor(a5),d1
	CALL	Draw

	move.l	a2,a1
	moveq	#3,d0
	CALL	SetAPen

	move.l	a2,a1
	moveq	#121,d0
	moveq	#28,d1
	add	topbor(a5),d1
	moveq	#121,d2
	add	d3,d2
	moveq	#34,d3
	add	topbor(a5),d3
	CALL	RectFill

	move.l	orgpatts(a5),d0
	lsr.l	#4,d0
	move.l	conpatts(a5),d3
	lsr.l	#4,d3
	lsl.l	#8,d3
	divu	d0,d3

	move.l	a2,a1
	moveq	#1,d0
	CALL	SetAPen

	move.l	a2,a1
	moveq	#120,d0
	add	d3,d0
	moveq	#28+36,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	moveq	#120,d0
	add	d3,d0
	moveq	#34+36,d1
	add	topbor(a5),d1
	CALL	Draw

	move.l	a2,a1
	moveq	#0,d0
	CALL	SetAPen

	move.l	a2,a1
	moveq	#121,d0
	add	d3,d0
	moveq	#28+36,d1
	add	topbor(a5),d1
	move	#121+256,d2
	moveq	#34+36,d3
	add	topbor(a5),d3
	CALL	RectFill

	move.l	a2,a1
	moveq	#1,d0
	CALL	SetAPen

	move.l	conpatts(a5),d0
	lea	tbuff+6(a5),a0
	moveq	#5,d1
.con2	divu	#10,d0
	swap	d0
	move.b	d0,-(a0)
	add.b	#'0',(a0)
	clr	d0
	swap	d0
	dbf	d1,.con2

	move.l	a2,a1
	move	#121+256+34,d0
	moveq	#34+36,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	lea	tbuff(a5),a0
	moveq	#6,d0
	CALL	Text

	move.l	orgpatts(a5),d0
	sub.l	conpatts(a5),d0
	move.l	d0,d2
	lea	tbuff+6(a5),a0
	moveq	#5,d1
.con	divu	#10,d0
	swap	d0
	move.b	d0,-(a0)
	add.b	#'0',(a0)
	clr	d0
	swap	d0
	dbf	d1,.con

	move.l	a2,a1
	move	#121+256+34,d0
	moveq	#34+45,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	lea	tbuff(a5),a0
	moveq	#6,d0
	CALL	Text

	mulu	#50,d2
	move.l	orgpatts(a5),d0
	asr.l	#1,d0
	divu	d0,d2
	moveq	#0,d0
	move	d2,d0
	lea	tbuff(a5),a0
	divu	#10,d0
	add.b	#'0',d0
	move.b	d0,(a0)+
	swap	d0
	add.b	#'0',d0
	move.b	d0,(a0)

	move.l	a2,a1
	move	#121+256+2,d0
	moveq	#34+45,d1
	add	topbor(a5),d1
	CALL	Move

	move.l	a2,a1
	lea	tbuff(a5),a0
	moveq	#2,d0
	CALL	Text

	Pull	d1-d3/a0-a2/a6
 endc
	rts


;; Convert one PT-data to P61

conv	Push	d1/d2/a0/a6
	moveq	#0,d5
	move.l	d4,d0
	swap	d4
	and.l	#$fff,d4
	beq.b	notnote
	moveq	#36,d1
	lea	periodtable(pc),a6
lop	cmp	(a6,d5),d4			; Find note
	beq.b	found
	addq	#2,d5
	dbf	d1,lop
	moveq	#0,d5
	bra.b	notnote
found	ror.l	#8,d5

notnote	move.l	d0,d4
	move.l	d0,d1
	and	#$ff,d1				; Info byte

	lsr.l	#8,d4
	and.l	#$f,d4				; Command

	move	d4,d2
	add	d2,d2
	move	jt(pc,d2),d2
	jmp	jt(pc,d2)

kudi	lsl	#8,d1
	or	d1,d5
	swap	d4
	beq.b	poes				; No command
	or.l	d4,d5

	swap	d4
	move.l	usec(a5),d2
	cmp	#$e,d4
	bne.b	eie
	move	#$f,d4
	rol	#4,d1
	and	d1,d4	
	add	#16,d4				; E-command -> Add 16
eie	bset	d4,d2
	move.l	d2,usec(a5)			; Mark command used
poes	move.l	d0,d4
	and.l	#$f0000000,d4
	and.l	#$f000,d0
	rol.l	#8,d4
	rol	#4,d0
	or.l	d0,d4				; Inst num
	beq.b	kiue
	lea	samplenum(a5),a0
	move.b	(a0,d4),d4			; From sample reloc-table
	swap	d4
	lsl.l	#4,d4
	or.l	d4,d5	
kiue	Pull	d1/d2/a0/a6
	rts

jt	dc	arp-jt		;0
	dc	sld-jt		;1
	dc	sld-jt		;2
	dc	kudi-jt		;3
	dc	kudi-jt		;4
	dc	tpvsld-jt	;5
	dc	vibvsld-jt	;6
	dc	kudi-jt		;7
	dc	toe8-jt		;8
	dc	kudi-jt		;9
	dc	vsld-jt		;A
	dc	bjmp-jt		;B
	dc	vol-jt		;C
	dc	bbrk-jt		;D
	dc	ecmd-jt		;E
	dc	kudi-jt		;F

arp	tst	d1
	beq.b	kudi
	moveq	#8,d4				; Real arpeggio
	bra.b	kudi

sld	tst	d1
	bne.b	kudi				; Info zero?
	moveq	#0,d4				; No command
	bra	kudi

tpvsld	tst	d1
	bne.b	vsld				; Vslide used?
	moveq	#3,d4				; Normal toneporta
	bra	kudi

vibvsld	tst	d1
	bne.b	vsld				; Vslide used?
	moveq	#4,d4				; Normal vibrato
	bra	kudi

vsld	move	d1,d2
	and	#$f0,d2
	beq.b	kein
	lsr	#4,d1
	neg	d1				; Slide up
	bra	kudi
kein	and	#$f,d1				; Slide down
	bne	kudi				; Slide?
	moveq	#0,d4				; Rem. command
	bra	kudi

toe8	moveq	#$e,d4				; Convert command 8xy
	and	#$f,d1				; to E8y
	or	#$80,d1
	bra	kudi

bbrk	tst	d7
	beq.b	.pois
	tst	break(a5)
	beq.b	bjmp
.pois	moveq	#0,d4				; Already break
	moveq	#0,d1				; remove
	bra	kudi
bjmp	st	break(a5)
	bra	kudi

vol	cmp	#64,d1				; Volume limits
	bls	kudi
	moveq	#64,d1
	bra	kudi

ecmd	move	d1,d2
	asr	#4,d2
	add	d2,d2
	move	jt2(pc,d2),d2
	jmp	jt2(pc,d2)

filt	and	#1,d1
	add	d1,d1
	bra	kudi

cut	moveq	#$f,d2
	and	d1,d2
	bne	kudi				; Frame 0?
	moveq	#$c,d4				; Normal set vol 0
	moveq	#0,d1
	bra	kudi

rem	moveq	#$f,d2
	and	d1,d2
	bne	kudi				; Info zero?
	moveq	#0,d1				; Remove command
	moveq	#0,d4
	bra	kudi

jt2	dc	filt-jt2	;0
	dc	rem-jt2		;1
	dc	rem-jt2		;2
	dc	kudi-jt2	;3
	dc	kudi-jt2	;4
	dc	kudi-jt2	;5
	dc	kudi-jt2	;6
	dc	kudi-jt2	;7
	dc	kudi-jt2	;8
	dc	rem-jt2		;9
	dc	rem-jt2		;A
	dc	rem-jt2		;B
	dc	cut-jt2		;C
	dc	rem-jt2		;D
	dc	rem-jt2		;E
	dc	kudi-jt2	;F



;;moduleplayer!

playmod	Push	All
	lea	Player(pc),a0
	btst	#3,flags+3(a5)
	bne.b	usetempo
	clr	P61_UseTempo(a0)
	bra.b	ohituskaista
usetempo
	st	P61_UseTempo(a0)
ohituskaista
	move.l	memory(a5),a0
	cmp.l	#'P61A',(a0)
	bne.b	.hep
	addq.l	#4,a0
.hep	move.b	3(a0),d0
	and	#$40,d0
	beq.b	siirra

	move.l	4(a0),d0
	moveq	#MEMF_CHIP,d1
	CLIB	Exec,AllocMem
	move.l	d0,temporary(a5)
	beq	errore
	move.l	d0,a2
	bra.b	hepoinen

siirra	
	move.l	memory(a5),a1
	CLIB	Exec,TypeOfMem
	subq.l	#MEMF_CHIP,d1
	beq.b	hepoinen

	move.l	filelength(a5),d0
	moveq	#MEMF_CHIP,d1
	CALL	AllocMem
	tst.l	d0
	beq.b	errore
	move.l	memory(a5),a0
	move.l	d0,a1
	move.l	filelength(a5),d1
	asr.l	d1
.cop	move	(a0)+,(a1)+
	subq.l	#1,d1
	bne.b	.cop
	move.l	memory(a5),a1
	move.l	d0,memory(a5)
	move.l	filelength(a5),d0
	CALL	FreeMem
hepoinen
	move.l	memory(a5),a0
	moveq	#0,d0
	sub.l	a1,a1
	lea	$dff000,a6

	bsr	Player+P61_InitOffset
	tst	d0
	bne.b	errore
	movem.l	(sp),d0-a6

	tst	quiet(a5)
	bne.b	hiljaa

	lea	tags(a5),a0
	sub.l	a3,a3
	lea	muuttujat,a4
	lea	fname,a1
	tst	para(a5)
	beq.b	normia
	lea	fname2,a1
normia	move.l	a1,(a4)
	lea	Playing(a5),a1
	lea	nothing(a5),a2
	C5LIB	RT,rtEZRequestA

takaas	lea	$dff000,a6
	bsr.b	Player+P61_EndOffset

errore	move.l	temporary(a5),d0
	beq.b	.hepo
	move.l	d0,a1
	move.l	memory(a5),a0
	cmp.l	#'P61A',(a0)
	bne.b	.hep
	addq.l	#4,a0
.hep	move.l	4(a0),d0
	CLIB	Exec,FreeMem
	clr.l	temporary(a5)
.hepo	Pull	All
	tst	para(a5)
	bne.b	poistukaamme
	rts

poistukaamme
	addq.l	#4,sp
	bra	exit

hiljaa	moveq	#0,d0
	bset	#12,d0
	CLIB	Exec,Wait
	bra.b	takaas

Player	incbin	610.2.bin
 
;; Xpk, FImp and PPdata loader
	cnop	0,2
bla:	dc.l	0
bla2:	dc.l	0

LoadData
	movem.l	d2-d7/a2-a6,-(sp)
	movem.l	d0-d2/a0/a1,-(sp)
	
	move.l	a0,d1
	move.l	#1005,d2
	C5LIB	DOS,Open
.d	tst.l	d0
	bmi.b	.err
	bne.b	.okei
.e	moveq	#-1,d0
.err	move.l	d0,errorcode(a5)
	movem.l	(sp)+,d0-d2/a0/a1
	bra	eifimp

.okei	move.l	d0,d7
	move.l	d0,d1
	move.l	#buhku,d2
	moveq	#8,d3
	CALL	Read

	move.l	d0,d2
	move.l	d7,d1
	CALL	Close

	move.l	d2,d0
	bmi.b	.err
	beq.b	.e

	movem.l	(sp)+,d0-d2/a0/a1

	cmp.l	#'XPKF',buhku(a5)
	bne.b	.x
	move.l	_XPKBase(a5),d3
	bne	XPK
.x	cmp.l	#'IMP!',buhku(a5)
	beq.b	.fimp

	movem.l	d0/d1/a0/a1,-(sp)

	C5LIB	PP,ppLoadData
	
	move.l	d0,errorcode(a5)
	move.l	d0,d2
	movem.l	(sp)+,d0/d1/a0/a1
	tst.l	d2
	beq	eifimp
	clr.l	(a1)
	bra	eifimp

.fimp	move.l	buhku+4(a5),d0
	move.l	d0,(a2)
	movem.l	a0/a1,-(sp)
	CLIB	Exec,AllocMem
	movem.l	(sp)+,a0/a1

	tst.l	d0
	bne.b	memokei

	moveq	#-3,d0
	move.l	d0,errorcode(a5)
	clr.l	(a1)
	bra.b	eifimp
	
memokei	move.l	d0,(a1)

	move.l	a1,-(sp)
	move.l	a0,d1
	move.l	#1005,d2
	C5LIB	DOS,Open
.d	tst.l	d0
	bmi.b	.err
	bne.b	.okei
.e	moveq	#-1,d0
.err	move.l	d0,errorcode(a5)
	move.l	(sp)+,a1

	move.l	(a1),d2
	move.l	(a2),d0
	clr.l	(a1)
	move.l	d2,a1
	CLIB	Exec,FreeMem
	bra	eifimp

.okei	move.l	d0,d7
	move.l	d0,d1
	move.l	(sp),a1
	move.l	(a1),d2
	move.l	(a2),d3
	CALL	Read

	move.l	d0,d2
	move.l	d7,d1
	CALL	Close

	move.l	d2,d0
	bmi.b	.err
	beq.b	.e

	move.l	(sp)+,a1
	move.l	(a1),a0
	clr.l	errorcode(a5)
	bsr.b	FImp_decrunch

eifimp	movem.l	(sp)+,d2-d7/a2-a6
	move.l	errorcode(a5),d0
	rts

XPK	move.l	a0,XPKFN(a5)
	move.l	a1,XPKTo(a5)
	move.l	a2,XPKFlen(a5)
	move.l	d1,XPKMem(a5)
	lea	XPKtags(a5),a0
	move.l	d3,a6
	;CALL	XpkUnpack
	move.l	d0,errorcode(a5)
	bra.b	eifimp


; Decrunch routine from FImp v2.34 by A.J. Brouwer
; A0 must be pointing at the start of the decrunched data

FImp_decrunch
	movem.l	d2-d5/a2-a4,-(a7)
	move.l	a0,a3
	move.l	a0,a4
	tst.l	(a0)+
	adda.l	(a0)+,a4
	adda.l	(a0)+,a3
	move.l	a3,a2
	move.l	(a2)+,-(a0)
	move.l	(a2)+,-(a0)
	move.l	(a2)+,-(a0)
	move.l	(a2)+,d2
	move	(a2)+,d3
	bmi.b	lb_180e
	subq.l	#1,a3
lb_180e	lea	-$1c(a7),a7
	move.l	a7,a1
	moveq	#6,d0
lb_1816	move.l	(a2)+,(a1)+
	dbf	d0,lb_1816
	move.l	a7,a1
	bra.b	lb_1e90
lb_1822	moveq	#0,d0
	rts
lb_1e90	tst.l	d2
	beq.b	lb_1e9a
lb_1e94	move.b	-(a3),-(a4)
	subq.l	#1,d2
	bne.b	lb_1e94
lb_1e9a	cmpa.l	a4,a0
	bcs.b	lb_1eb2
	lea	$1c(a7),a7
	moveq	#-1,d0
	cmpa.l	a3,a0
	beq.b	lb_1eaa
	moveq	#0,d0
lb_1eaa	movem.l	(a7)+,d2-d5/a2-a4
	tst.l	d0
	rts
lb_1eb2	add.b	d3,d3
	bne.b	lb_1eba
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1eba	bcc.b	lb_1f24
	add.b	d3,d3
	bne.b	lb_1ec4
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1ec4	bcc.b	lb_1f1e
	add.b	d3,d3
	bne.b	lb_1ece
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1ece	bcc.b	lb_1f18
	add.b	d3,d3
	bne.b	lb_1ed8
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1ed8	bcc.b	lb_1f12
	moveq	#0,d4
	add.b	d3,d3
	bne.b	lb_1ee4
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1ee4	bcc.b	lb_1eee
	move.b	-(a3),d4
	moveq	#3,d0
	subq.b	#1,d4
	bra.b	lb_1f28
lb_1eee	add.b	d3,d3
	bne.b	lb_1ef6
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1ef6	addx.b	d4,d4
	add.b	d3,d3
	bne.b	lb_1f00
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f00	addx.b	d4,d4
	add.b	d3,d3
	bne.b	lb_1f0a
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f0a	addx.b	d4,d4
	addq.b	#5,d4
	moveq	#3,d0
	bra.b	lb_1f28
lb_1f12	moveq	#4,d4
	moveq	#3,d0
	bra.b	lb_1f28
lb_1f18	moveq	#3,d4
	moveq	#2,d0
	bra.b	lb_1f28
lb_1f1e	moveq	#2,d4
	moveq	#1,d0
	bra.b	lb_1f28
lb_1f24	moveq	#1,d4
	moveq	#0,d0
lb_1f28	moveq	#0,d5
	move	d0,d1
	add.b	d3,d3
	bne.b	lb_1f34
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f34	bcc.b	lb_1f4c
	add.b	d3,d3
	bne.b	lb_1f3e
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f3e	bcc.b	lb_1f48
	move.b	lb_1fac(pc,d0),d5
	addq.b	#8,d0
	bra.b	lb_1f4c
lb_1f48	moveq	#2,d5
	addq.b	#4,d0
lb_1f4c	move.b	lb_1fb0(pc,d0),d0
lb_1f50	add.b	d3,d3
	bne.b	lb_1f58
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f58	addx	d2,d2
	subq.b	#1,d0
	bne.b	lb_1f50
	add	d5,d2
	moveq	#0,d5
	move.l	d5,a2
	move	d1,d0
	add.b	d3,d3
	bne.b	lb_1f6e
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f6e	bcc.b	lb_1f8a
	add	d1,d1
	add.b	d3,d3
	bne.b	lb_1f7a
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f7a	bcc.b	lb_1f84
	move	8(a1,d1),a2
	addq.b	#8,d0
	bra.b	lb_1f8a
lb_1f84	move	(a1,d1),a2
	addq.b	#4,d0
lb_1f8a	move.b	16(a1,d0),d0
lb_1f8e	add.b	d3,d3
	bne.b	lb_1f96
	move.b	-(a3),d3
	addx.b	d3,d3
lb_1f96	addx.l	d5,d5
	subq.b	#1,d0
	bne.b	lb_1f8e
	addq	#1,a2
	adda.l	d5,a2
	adda.l	a4,a2
lb_1fa2	move.b	-(a2),-(a4)
	dbf	d4,lb_1fa2
	bra	lb_1e90

lb_1fac	dc.b	6,10,10,18
lb_1fb0	dc.b	1,1,1,1,2,3,3,4
	dc.b	4,5,7,14


;; Datas
	section	dataa,data
sa				;data area base
cha0		dc.l	0,0
bestoffset	dc.l	0
bestlength	dc	0
bestreallength	dc	0
t_src		dc.l	0
t_dest		dc.l	0
break		dc	0
break2		dc	0
break3		dc	0
pakattuja	dc	0
counter		dc	0
dataend		dc	0
patts		dc	0
poss		dc	0
samples		dc.l	0
sbuflen		dc.l	0
pattend		dc.l	0
posibase	dc.l	0
samplebase	dc.l	0
pattebase	dc.l	0
samplenum	blk.b	32
posu		dc.l	0

sampleoffsetit	blk.l	31

alksu
title		dc.b	'Select module(s) to convert:',0
title2		dc.b	'Select filename for saving:',0
title3		dc.b	'Select destination dir:',0
title4		dc.b	'Select default load dir:',0
title5		dc.b	'Select default save dir:',0
title6		dc.b	'Select default batch dir:',0
title7		dc.b	'Select module to play:',0
title9		dc.b	'Select module to convert:',0

bodytext 	dc.b	'This is not an original Noise/Protracker module',10
		dc.b	'Wanna convert it anyway?',0

packing	dc.b	'Packing %s...',10,10
	dc.b	'Part 1:                                              ',10
	dc.b	'Part 2:                                              ',10,10
	dc.b	'Original:                                            ',10
	dc.b	'Packed:                                              ',10
	dc.b	'Won:                                         %%       ',10,10
	dc.b	'Original samples:                                    ',10
	dc.b	'Converted samples:                                   ',0

nothing 	dc.b	'STOP',0
Playing		dc.b	'Playing %s...',0
openerr		dc.b	'Open error!',0
textys		dc.b	'The Player 6.1',0
textys2		dc.b	'(C) 1992-95 Guru/S2',0
exists		dc.b	'File already exists!',10
		dc.b	'Overwrite?',0
tbuff		dcb.b	6,' '
terminate	dc.b	'Terminate batch?',0
yep		dc.b	'_Yes|_No',0

memerr3		dc.b	'Not enough memory to load file!',0
pack		dc.b	'Sample number %ld/%ld: "%s"',0

packg	
 dc.b	'_Original|_Packed|Pac_k|Pack _rest|_Don't pack|Do_n't pack rest',0

memerr2		dc.b	'Not enough memory for convert buffer!',10
		dc.b	'%6.6ld bytes needed!',0

org		dc.b	'Original length:  %8.8ld (=$%06.6lx)',10
		dc.b	'Converted length: %8.8ld (=$%06.6lx)',10
		dc.b	'Bytes won:        %8.8ld (=$%06.6lx)',10
		dc.b	'Usecode: $%0.8lx',10
		dc.b	'Sample buffer length: %ld',0

torg		dc.b	'Total original length:  %8.8ld (=$%06.6lx)',10
		dc.b	'Total converted length: %8.8ld (=$%06.6lx)',10
		dc.b	'Total bytes won:        %8.8ld (=$%06.6lx)',0

vstr		VERS
		dc.b	0

fnotestr 	dc.b	'%s, Original: %ld, Usecode: $%0.8lx, Buffer: %ld',0

contta		dc.b	'Continue...',0
agad1		dc.b	'  |Quit|>>',0
agad2		dc.b	'<<|Quit|>>',0
agad3		dc.b	'<<|Quit|  ',0

tekstus		dc.b	'The Player 6.1A',10
		dc.b	'ญญญญญญญญญญญญญญญ',10
		VER
		dc.b	'Copyright 1992-95 Jarno Paananen',10
		dc.b	'ญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญ',10
		dc.b	'A Sahara Surfers (tm) Production',10
		dc.b	'ญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญ',10,0

winname		dc.b	'The Player 6.1A',0
winname2	dc.b	'Preferences',0

loadtext	dc.b	'Load',0
savetext	dc.b	'Save',0
play		dc.b	'Play',0
prefsfile	dc.b	'S:P61A.prefs',0
		even
lopsu

loadtags	dc.l	$8000002a,loadtext
		dc.l	$80000028,%10001
		dc.l	$8000000f,textattr
		dc.l	0

playtags	dc.l	$8000002a,play
		dc.l	$80000028,%10000
		dc.l	$8000000f,textattr
		dc.l	0

convtags	dc.l	$8000002a,loadtext
		dc.l	$80000028,%10000
		dc.l	$8000000f,textattr
		dc.l	0

savetags	dc.l	$8000002a,savetext
		dc.l	$80000028,%10010
		dc.l	$8000000f,textattr
		dc.l	0

dirtags		dc.l	$80000028,%1000000001010
		dc.l	$8000000f,textattr
		dc.l	0

diretags	dc.l	$80000032,defload
		dc.l	$80000033,prefix
		dc.l	$8000000f,textattr
		dc.l	0

dir2tags	dc.l	$80000032,defsave
		dc.l	$80000033,prefix
		dc.l	$8000000f,textattr
		dc.l	0

dir3tags	dc.l	$80000032,defdest
		dc.l	$8000000f,textattr
		dc.l	0

ntags		dc.l	$80000008,0
		dc.l	$80000001,0
		dc.l	$80000003,2
		dc.l	$80000016,4
		dc.l	$80000014,winname
		dc.l	$8000000f,textattr
		dc.l	0

tags		dc.l	$80000003,2
		dc.l	$80000016,4
		dc.l	$80000017,0 
		dc.l	$8000000b,'_'
		dc.l	$80000014,winname
		dc.l	$8000000f,textattr
		dc.l	0

reqtags		dc.l	$80000008,0
		dc.l	$80000001,0
		dc.l	$8000000a,0
		dc.l	$80000003,2
		dc.l	$80000016,5
		dc.l	$80000014,winname
		dc.l	$8000000f,textattr
Tagend		dc.l	0

handtags	dc.l	$8000003c,0
		dc.l	0

XPKtags		dc.l	$80005851
XPKFN		dc.l	0
		dc.l	$80005863
XPKTo		dc.l	0
		dc.l	$80005873
XPKFlen		dc.l	0
		dc.l	$80005872
XPKFlen2	dc.l	0
		dc.l	$80005876
XPKMem		dc.l	2
		dc.l	$80005877
		dc.l	1
		dc.l	0	


textattr	dc.l	fontname
		dc	8,0

fontname	dc.b	'topaz.font',0

_XPKName	dc.b	'xpkmaster.library',0

portname	dc.b	'P61con.port',0
port2name	dc.b	'P61.port',0

message		dc.l	0,0
		dc.b	NT_MESSAGE,0
		dc.l	0
		dc.l	port			;replyport
		dc	prefix-message
command		dc.l	0
pointer		dc.l	0
length		dc.l	0
filename	dc.l	0
flagit		dc.l	0
prefix		dcb.b	12,0

port		dc.l	0,0
		dc.b	4,0
		dc.l	portname
		dc.b	0
portsignal	dc.b	0
task		dc.l	0
		dc.l	0,0,0

fromport	dc	0

aboutlist	dc.l	about,agad1,copy,agad2,distri,agad2,contact,agad2
		dc.l	hellos,agad3,0
para		dc	0
chans		dc	0
Lock		dc.l	0
quiet		dc	0
topbor		dc	0
RPort		dc.l	0
aboutpos	dc.l	0
windowptr	dc.l	0
reqhandler	dc.l	0
rast		dc.l	0
winpoin		dc.l	0
_IntBase	dc.l	0
_GFXBase	dc.l	0
_DOSBase	dc.l	0
_PPBase		dc.l	0
_RTBase 	dc.l	0
_XPKBase	dc.l	0
reqptr		dc.l	0
reqptr2		dc.l	0
reqptr3		dc.l	0
reqptr4		dc.l	0
memory		dc.l	0
buffer		dc.l	0
segment		dc.l	0
errorcode	dc.l	0
err		dc	0
batch		dc	0
file		dc.l	0
file2		dc.l	0
orglength	dc.l	0
conlength	dc.l	0
templen		dc.l	0
filelength	dc.l	0
filelist	dc.l	0
filelistpos	dc.l	0
dirdd		dc.l	0
dirdd2		dc.l	0
dirdd3		dc.l	0
stopfl		dc	0
totalorg 	dc.l	0
totalcon 	dc.l	0
totalwon 	dc.l	0
orgpatts 	dc.l	0
conpatts 	dc.l	0
converted	dc.l	0
prepacked 	dc.l	0
temporary 	dc.l	0
fullpatt	dc	0
nowpatt		dc	0
consamples	dc.l	0
orgsamples	dc.l	0
usec		dc.l	0
smpstr		dc.l	0
tyhjasample	dc.l	0
texture		dc	$5555,$aaaa
otextu		dc	0
buhku		dc.l	0,0

prefsarea
defload		dc.b	'ST-00:MODULES'
		dcb.b	128-13,0
defsave		dc.b	'SYS:'
		dcb.b	128-4,0
defdest		dc.b	'SYS:'
		dcb.b	128-4,0
flags		dc.l	%1000
		;0 = two files
		;1 = sign
		;2 = no samples
		;3 = tempo
		;4 = icon
		;5 = delta
		;6 = sample packing

loadprefix	dc.l	'mod.',0
saveprefix	dc.l	'P61.',0
sampprefix	dc.l	'SMP.',0
prefsend

winstr
 dc	0,0,300,170
 dc.b	0,1
 dc.l	CLOSEWINDOW!GADGETUP
 dc.l	WINDOWDEPTH!WINDOWCLOSE!WINDOWDRAG!ACTIVATE!NOCAREREFRESH!SMART_REFRESH
 dc.l	0,0,winname,0,0
 dc	300,170,300,170,WBENCHSCREEN

gadgets		dc.l	gadget5
		dc	35,-80,231,11,GADGHCOMP!GRELBOTTOM,RELVERIFY,1
		dc.l	sborder,0,text,0,0
		dc	0
		dc.l	0

gadget5		dc.l	gadget2
		ifeq	release
		dc	35,-65,231,11,GADGHCOMP!GRELBOTTOM,RELVERIFY,1
		else
		dc	35,-65,231,11,GADGHCOMP!GRELBOTTOM!GADGDISABLED
		dc	RELVERIFY,1
		endc
	
		dc.l	sborder,0,text5,0,0
		dc	1
		dc.l	0

gadget2		dc.l	gadget3
		dc	35,-50,231,11,GADGHCOMP!GRELBOTTOM,RELVERIFY,1
		dc.l	sborder,0,text2,0,0
		dc	2
		dc.l	0

gadget3		dc.l	gadget4
		dc	35,-35,231,11,GADGHCOMP!GRELBOTTOM,RELVERIFY,1
		dc.l	sborder,0,text3,0,0
		dc	3
		dc.l	0

gadget4		dc.l	dummy
		dc	35,-20,231,11,GADGHCOMP!GRELBOTTOM,RELVERIFY,1
		dc.l	sborder,0,text4,0,0
		dc	4
		dc.l	0

dummy		dc.l	0
		dc	12,-166,276,78,GADGHNONE!GRELBOTTOM,0,1
		dc.l	gborder,0,0,0,0
		dc	4
		dc.l	0

gborder		dc	0,0
		dc.b	1,0,0,3
		dc.l	glines,gbor2

glines		dc	0,78,0,0,276,0

gbor2		dc	0,0
		dc.b	2,0,0,3
		dc.l	glines2,0

glines2		dc	1,78,276,78,276,1

text		dc.b	1,0,1,0
		dc	3,2
		dc.l	textattr,teksti,0

text5		dc.b	1,0,1,0
		dc	31,2
		dc.l	textattr,teksti5,0

text2		dc.b	1,0,1,0
		dc	14,2
		dc.l	textattr,teksti2,0

text3		dc.b	1,0,1,0
		dc	71,2
		dc.l	textattr,teksti3,0

text4		dc.b	1,0,1,0
		dc	95,2
		dc.l	textattr,teksti4,0

sborder		dc	0,0
		dc.b	2,0,0,3
		dc.l	lines,bor2

lines		dc	0,10,0,0,230,0

bor2		dc	0,0
		dc.b	1,0,1,3
		dc.l	lines2,0

lines2		dc	1,10,230,10,230,0

texa		dc.b	1,0,0,0
		dc	1,1
		dc.l	textattr
kelo		dc.l	tekstus,texi

texi		dc.b	2,0,0,0
		dc	0,0
		dc.l	textattr
kala		dc.l	tekstus,0

prefwinstr
 dc	0,0,360,210
 dc.b	0,1
 dc.l	CLOSEWINDOW!GADGETUP!GADGETDOWN
 dc.l	WINDOWDEPTH!WINDOWCLOSE!WINDOWDRAG!ACTIVATE!NOCAREREFRESH!SMART_REFRESH
 dc.l	dl,0,winname2,0,0
 dc	360,210,360,210,WBENCHSCREEN

dl		dc.l ds
		dc 41,-190,299,9,8,1,4
		dc.l dlgr,0,dlt,0,dls
		dc 0
		dc.l 0
dlgr		dc 0,0
		dc.b 1,0,1,3
		dc.l dlxy,dlgr2
dlxy		dc -2,7,-2,-1,297,-1
dlgr2		dc 0,0
		dc.b 2,0,1,3
		dc.l dlxy2,dlgr3
dlxy2		dc 298,-1,298,8,-2,8
dlgr3		dc 0,0
		dc.b 1,0,1,2
		dc.l dlxy3,dlgr4
dlxy3		dc -1,7,-1,0
dlgr4		dc 0,0
		dc.b 2,0,1,2
		dc.l dlxy4,dlgr5
dlxy4		dc -4,8,-4,-2
dlgr5		dc 0,0
		dc.b 2,0,1,4
		dc.l dlxy5,dlgr6
dlxy5		dc -3,8,-3,-2,299,-2,299,8
dlgr6		dc 0,0
		dc.b 1,0,1,3
		dc.l dlxy6,dlgr7
dlxy6		dc 300,-2,300,9,-4,9
dlgr7		dc 0,0
		dc.b 1,0,1,2
		dc.l dlxy7,0
dlxy7		dc 301,-2,301,9
dlt		dc.b 1,0,1,0
		dc 86,-10
		dc.l textattr,dltx,0
dls		dc.l defload,0
		dc 0,128,0,0,0,0,0,0
		dc.l 0,0,0

ds		dc.l db
		dc 41,-168,299,9,8,1,4
		dc.l dlgr,0,dst,0,dss
		dc 0
		dc.l 0
dst		dc.b 1,0,1,0
		dc 86,-10
		dc.l textattr,dstx,0

dss		dc.l defsave,0
		dc 0,128,0,0,0,0,0,0
		dc.l 0,0,0

db		dc.l rdl
		dc 41,-146,299,9,8,1,4
		dc.l dlgr,0,dbt,0,dbs
		dc 0
		dc.l 0
dbt		dc.b 1,0,1,0
		dc 82,-10
		dc.l textattr,dbtx,0
dbs		dc.l defdest,0
		dc 0,128,0,0,0,0,0,0
		dc.l 0,0,0

rdl		dc.l rds
		dc 19,-192,20,12,12,2,1
		dc.l rdlgr,0,0,0,0
		dc 0
		dc.l 0

rds		dc.l rdb
		dc 19,-170,20,12,12,2,1
		dc.l rdlgr,0,0,0,0
		dc 0
		dc.l 0

rdb		dc.l sprefs
		dc 19,-148,20,12,12,2,1
		dc.l rdlgr,0,0,0,0
		dc 0
		dc.l 0

rdlgr		dc 0,0,20,12,2
		dc.l rdlim
		dc.b 3,0
		dc.l 0

sprefs		dc.l lprefs
		dc 280,-20,50,12,9,1,1
		dc.l sprefsgr,0,sprefst,0,0
		dc 0
		dc.l 0
sprefsgr	dc 0,0
		dc.b 2,0,1,3
		dc.l sprefsxy,sprefsgr2
sprefsxy	dc 0,11,0,0,49,0
sprefsgr2	dc 0,0
		dc.b 1,0,1,3
		dc.l sprefsxy2,0
sprefsxy2	dc 49,1,49,11,1,11
sprefst		dc.b 1,0,1,0
		dc 8,2
		dc.l textattr,sprefstx,0

lprefs		dc.l wl
		dc 30,-20,50,12,9,1,1
		dc.l sprefsgr,0,lprefst,0,0
		dc 0
		dc.l 0

lprefst		dc.b 1,0,1,0
		dc 8,2
		dc.l textattr,lprefstx,0

wl		dc.l ppre
		dc 30,-130,40,10,8,1,4
		dc.l wlgr,0,wlt,0,wls
		dc 0
		dc.l 0
wlgr		dc 0,0
		dc.b 1,0,1,3
		dc.l wlxy,wlgr2
wlxy		dc -2,7,-2,-1,38,-1
wlgr2		dc 0,0
		dc.b 2,0,1,3
		dc.l wlxy2,wlgr3
wlxy2		dc 39,-1,39,8,-2,8
wlgr3		dc 0,0
		dc.b 1,0,1,2
		dc.l wlxy3,wlgr4
wlxy3		dc -1,7,-1,0
wlgr4		dc 0,0
		dc.b 2,0,1,2
		dc.l wlxy4,wlgr5
wlxy4		dc -4,8,-4,-2
wlgr5		dc 0,0
		dc.b 2,0,1,4
		dc.l wlxy5,wlgr6
wlxy5		dc -3,8,-3,-2,40,-2,40,8
wlgr6		dc 0,0
		dc.b 1,0,1,3
		dc.l wlxy6,wlgr7
wlxy6		dc 41,-2,41,9,-4,9
wlgr7		dc 0,0
		dc.b 1,0,1,2
		dc.l wlxy7,0
wlxy7		dc 42,-2,42,9
wlt		dc.b 1,0,1,0
		dc 45,0
		dc.l textattr,wltx,0
wls		dc.l saveprefix,0
		dc.l 8,0,0,0,0,0,0

ppre		dc.l smp
		dc 30,-115,40,10,8,1,4
		dc.l wlgr,0,ppret,0,ppres
		dc 0
		dc.l 0
ppret		dc.b 1,0,1,0
		dc 45,0
		dc.l textattr,ppretx,0
ppres		dc.l loadprefix,0
		dc.l 8,0,0,0,0,0,0

smp		dc.l one
		dc 30,-100,40,10,8,1,4
		dc.l wlgr,0,smpt,0,smps
		dc 0
		dc.l 0
smpt		dc.b 1,0,1,0
		dc 45,0
		dc.l textattr,smptx,0
smps		dc.l sampprefix,0
		dc.l 8,0,0,0,0,0,0

one		dc.l signa
		dc 30,-85,26,11,14,257,1
		dc.l onegr,onesr,onet,0,0
		dc 0
		dc.l 0
onegr		dc 0,0,26,11,2
		dc.l oneim
		dc.b 3,0
		dc.l 0

onesr		dc 0,0,26,11,2
		dc.l oneimr
		dc.b 3,0
		dc.l 0

onet		dc.b 1,0,1,0
		dc 30,2
		dc.l textattr,onetx,0

signa		dc.l samp
		dc 160,-85,26,11,14,257,1
		dc.l onegr,onesr,signat,0,0
		dc 1
		dc.l 0

signat		dc.b 1,0,1,0
		dc 30,2
		dc.l textattr,signatx,0

samp		dc.l tempo
		dc 30,-70,26,11,14,257,1
		dc.l onegr,onesr,sampt,0,0
		dc 2
		dc.l 0

sampt		dc.b 1,0,1,0
		dc 30,2
		dc.l textattr,samptx,0

tempo		dc.l icon
		dc 160,-70,26,11,14,257,1
		dc.l onegr,onesr,tempot,0,0
		dc 3
		dc.l 0

tempot		dc.b 1,0,1,0
		dc 30,2
		dc.l textattr,tempotx,0

icon		dc.l delta
		dc 160,-55,26,11,14,257,1
		dc.l onegr,onesr,icont,0,0
		dc 4
		dc.l 0

icont		dc.b 1,0,1,0
		dc 30,2
		dc.l textattr,icontx,0

delta		dc.l packs
		dc 30,-55,26,11,14,257,1
		dc.l onegr,onesr,deltat,0,0
		dc 5
		dc.l 0

deltat		dc.b 1,0,1,0
		dc 30,2
		dc.l textattr,deltatx,0

packs		dc.l 0
		dc 30,-40,26,11,14,257,1
		dc.l onegr,onesr,packt,0,0
		dc 6
		dc.l 0

packt		dc.b 1,0,1,0
		dc 30,2
		dc.l textattr,packtx,0

image		dc 0,0,79,39,2
		dc.l elkoim
		dc.b 3,3
		dc.l 0

winstr2		dc	0,0,1,1
		dc.b	0,0
		dc.l	0,0,0,0
		dc.l	winname,0,0
		dc	1,1,1,1,WBENCHSCREEN

bordel		dc.l	0
		dc.b	2,0,1,3
		dc.l	li1,bordel2

bordel2		dc.l	0
		dc.b	1,0,1,3
		dc.l	li2,0

li1		dc	0,8,0,0,257,0
li2		dc	258,0,258,8,1,8

teksti		dc.b 'Convert Protracker module(s)',0
teksti5		dc.b 'Convert a P61A module',0
teksti2		dc.b 'Play a Player 6.1A module',0
teksti3		dc.b 'Preferences',0
teksti4		dc.b 'About',0
dltx		dc.b 'Default load dir',0
dstx		dc.b 'Default save dir',0
dbtx		dc.b 'Default batch dir',0
onetx		dc.b 'Two files',0
signatx		dc.b ''P61A' sign',0
sprefstx	dc.b "SAVE",0
lprefstx	dc.b 'LOAD',0
samptx		dc.b "No samples",0
tempotx		dc.b "Tempo",0
icontx		dc.b "Icon",0
deltatx		dc.b "Delta",0
packtx		dc.b "Pack samples",0
wltx		dc.b "Default Player prefix",0
ppretx		dc.b "Default ProTracker prefix",0
smptx		dc.b "Default sample prefix",0

about
 dc.b 10
 dc.b 'The Player 6.1A',10
 dc.b 'ญญญญญญญญญญญญญญญ',10,10
 VER
 dc.b 'Copyright ฉ 1992-95 Jarno Paananen',10
 dc.b 'ญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญ',10
 dc.b 'Dedicated to Kausti, the one I still love',10,10
 dc.b 'A Sahara Surfers (tm) Production!',10
 dc.b 'ญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญ'
 ifne	release
 dc.b	10,10,'Special version for The Party 1994!'
 endc
 dc.b 0

copy
 dc.b 10
 dc.b 'Copyrights:',10
 dc.b 'ญญญญญญญญญญญ',10,10
 dc.b 'This program and all other stuff coming in this package are FULLY',10
 dc.b 'copyrighted by',10,10
 dc.b 'Jarno Paananen / Guru of Sahara Surfers',10
 dc.b 'ญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญญ',10
 dc.b 'With the exception of Reqtools and Powerpacker libraries by Nico Fran็ois',10
 dc.b	10,10

 dc.b 'BUT!:',10
 dc.b 'ญญญญญ',10
 dc.b 'You are allowed to make additions or modifications or what so ever to',10
 dc.b 'the source to fit it to your own needs. That's why it is here. But,',10
 dc.b 'please: Credits for the author and maybe a copy to myself, if possible,',10
 dc.b 'so I can add your new features to the future releases!',0

distri
 dc.b 10
 dc.b 'Distribution:',10
 dc.b 'ญญญญญญญญญญญญญ',10,10
 dc.b 'This program is freeware. You can distribute this as long as _ALL_',10
 dc.b 'files are included and not more than a nominal fee for copying is',10
 dc.b 'asked. This program can _NOT_ be used for commercial purposes without',10
 dc.b 'written permission from the author and a contribution for development',10 
 dc.b 'costs (like Coca-Cola :-). If you have suggestions or remarks about this',10
 dc.b 'program, or if you find any bugs, please let me know.',10,10
 dc.b 'For commercial use, contact me for a licence!',0

hellos
 dc.b 'Special hellos to:',10
 dc.b 'Janne Oksanen!',10
 dc.b 'ญญญญญญญญญญญญญญ',10
 dc.b 'And in alphabetical order to:',10
 dc.b 'Timo Aila, Otto Chrons, Mikko Haapamไki, Tommi Hakala,',10
 dc.b 'S๘ren Hannibal, Jussi Hartzell, John Hinge, Kari Huttunen,',10
 dc.b 'Janne Juhola, Teemu Kalvas, Petteri Kangaslampi, Mikko Karvonen',10
 dc.b 'Jarno Kilpiไ, Kari-Pekka Koljonen, Juha Lainema, Jouni Mannonen,',10
 dc.b 'Antti Mikkonen, Timo Mไkelไ, Pauli Porkka, Markku Saarinen,',10
 dc.b 'Steffan Schumacher',10,10
 dc.b 'For moral support and more:',10
 dc.b 'The IB-class of the Tampereen lyseon lukio',0

contact
 dc.b 10
 dc.b 'Contact address:',10
 dc.b 'ญญญญญญญญญญญญญญญญ',10,10
 dc.b 'Im improving this utility for my own use, but send me some $$$',10
 dc.b '(Finnish marks, please) or two disks with return envelope WITH',10
 dc.b 'stamps (or International Responce Coupon) and I'll send you the',10
 dc.b 'newest version (Mention which version you have, so I won't send',10
 dc.b 'the same version!) IF THESE CONDITIONS ARE NOT MET, ABSOLUTELY',10
 dc.b 'NO REPLY IS GUARANTEED!',10,10
 dc.b 'Also for licences for commercial use!',10
 dc.b 'TO:',10
 dc.b 'J.Paananen',10
 dc.b 'Puskalantie 6',10
 dc.b '37120 Nokia',10
 dc.b 'Finland',10,10
 dc.b 'Or by phone: +358-31-3422147 / Jarno',10
 dc.b 'Or preferably via Internet:',10
 dc.b 'jpaana@kauhajoki.fi',10
 dc.b 'or jpaana@freenet.hut.fi',0

ikoni	incbin	P60mod.info
iend

*************** Chippi datat ****************

	section chip,data_c
oneim	dc.l $40,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$7FFFFFC0,$FFFFFF80
	dc.l $C0000000,$C0000000,$C0000000,$C0000000,$C0000000,$C0000000
	dc.l $C0000000,$C0000000,$C0000000,$80000000,$1B01FFFE

oneimr	dc.l $40,$C0,$70C0,$C0C0,$180C0,$1C300C0,$E600C0,$7C00C0,$3800C0,$C0
	dc.l $7FFFFFC0,$FFFFFF80,$C0000000,$C0000000,$C0000000,$C0000000
	dc.l $C0000000,$C0000000,$C0000000,$C0000000,$C0000000,$80000000,$40

rdlim	dc.l 0,$1FC0000,$3060000,$3060000,$31F8000,$30F0000,$3060000,$3000000,$3060000
	dc.l $1FC0000,0,$7FFFF000,$FFFFF000,$C0000000,$C0000000,$C0000000,$C0000000,$C0000000
	dc.l $C0000000,$C0000000,$C0000000,$C0000000,$C0000000,$80000000,$3AD80

elkoim	dc.l $1E80,0,0,$7FE00000,0,$1FF70,0,0,$FF980000
	dc.l 0,$80007F80,0,$3D00,$3F800000,0,$BCA1F80,0,$2CE
	dc.l $87940000,0,$FE07E,$68000000,$F,$F8FC3FA0,0,$7FFE0,$2FD8000
	dc.l 3,$FE85F400,0,$1E800,$7FA00000,1,$800017F8,$94,$10000
	dc.l $1A00000,$2FFC0000,0,$170,0,0,$BC00018,0,$F00
	dc.l $780000,$A00000,$C0001F8,$F40,0,$F80000,$F4000100,$7C,$38000
	dc.l $5000000,$3E0000,$5F00,$1A,5,$FF000000,$3000,$5FFE00,1
	dc.l $C00002FF,$F8000000,$E0000,$3FFE000,$78,$3FF,$80000000,$1C00000,$1FE0000
	dc.l $700,$B001E8,0,$1C000060,$1400000,$F000,0,0,$C0020000
	dc.l 0,$CF,0,0,$39FC000,0,$2E3F,$A0000000,0
	dc.l $3CE80000,0,$7800,0,0,$60000000,0,0,$1E800000
	dc.l 0,$7FE0,0,1,$FF700000,0,$FF98,0,$8000
	dc.l $7F800000,0,$3D003F80,0,$BCA,$1F800000,0,$2CE8794,0
	dc.l $F,$E07E6800,0,$FF8FC,$3FA00000,7,$FFE002FD,$80000000,$3FE85
	dc.l $F4000000,1,$E8007FA0,0,$185FD,$17F97FE8,$940001,$1F9FC1A7,$F1FE2FFC
	dc.l $7F07,$F01FE07F,$81700000,$FE03F01F,$F03FCBC0,$19FE00,$E01FF81F,$CF000079,$FE0000A7
	dc.l $F01FEC00,$1F9FF00,$F40001F,$E00000F8,$FF80F400,$11FE000,$7C7FE3,$8000053F,$C000003E
	dc.l $1FF80000,$5F3FC000,$1A07FE,$5FF7F,$80000000,$31FF805F,$FEFF0000,$1C07F,$E2FFF9FE
	dc.l $E,$1FF3FF,$E3F80000,$78000F,$F3FF8FE0,$1C0,$F807F9FE,$1F800000,$701FCB7
	dc.l $F9E87E00,$60001C01,$FE6FF141,$F802E000,$F001FE0F,$E007FFFF,$E000C002,$7F9F801F,$FFFFE000
	dc.l $CF17FA,$1FFFFF,$E000039F,$C0000000,0,$2E3FA000,0,$3CE8,0
	dc.l 0,$78000000,0,$6000,0,0,0


********* Nimipuskurit, eli BSS **************

	section	bsss,bss
patterns	ds	101*4
muuttujat	ds.b	32
fname		ds.b	128
fname2		ds.b	128
fname3		ds.b	128
fname4		ds.b	128
bname		ds.b	128
bssend

TREK
	END

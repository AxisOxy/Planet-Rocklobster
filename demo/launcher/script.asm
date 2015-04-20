		move.l	#211000,d0
		bsr.w	alloc_chip			; allocate 211kb chipmem for music
		bsr.w	pushmemstate		; secure, the music data is not freed on free all
		move.l	a0,-(sp)			; store music mem pointer
		
		bsr.w	executenextpartalt	; start bootscreen as alternative, so we can load the music now

		move.l	(sp)+,a0			; restore music mem pointer
		bsr.w	loadmusic			; load and start the music
		
		bsr.w	skipnextfile		; skip 1 file, this file is dummy.dat. a hack to keep loading times constant
			
		bsr.w	freealt				; free mem from bootscreen
		bsr.w	executenextpart		; start starfield
		bsr.w	freeall				; free starfield mem
		bsr.w	executenextpartalt	; start planet as alternative, so we can load voxel now
		bsr.w	executenextpart		; start voxel
		bsr.w	freealt				; free planet mem
		bsr.w	freeall				; free voxel mem
		bsr.w	executenextpartalt	; show sea picture as alternative, so we can load tunnel & satellite
		bsr.w	executenextpart		; start vectorizer tunnel & satellite
		bsr.w	freealt				; free sea picture mem
		bsr.w	freeall				; free tunnel & satellite mem
		bsr.w	executenextpartalt	; show rocklobster logo as alternative, so we can load wireframe morph
		bsr.w	freealt				; free rocklobster logo mem (why does this not crash?!!!)
		bsr.w	executenextpart		; start wireframe morph
		bsr.w	executenextpartalt	; start vecplots fadein as alternative, so we can load vecplots
		bsr.w	executenextpart		; start vecplots
		bsr.w	executenextpartalt	; start vecplots fadeout as alternative, so we can load rotzoom
		bsr.w	executenextpart		; start rotzoom 
		bsr.w	executenextpart		; start crack
		bsr.w	freealt				; free vecplots fadeout mem
		bsr.w	freeall				; free crack mem
		bsr.w	executenextpart		; start city
		bsr.w	executenextpartalt	; start city fade as alternative, so we can load blur
		bsr.w	executenextpart		; start blur
		bsr.w	freealt				; free city fade mem
		bsr.w	executenextpartalt	; start spacecut fadein as alternative, so we can load spacecut
		bsr.w	executenextpart		; start spacecut
		bsr.w	executenextpart		; start spacecut fadeout
		bsr.w	freeall				; free spacecut fadeout
		bsr.w	executenextpartalt	; start greets as alternative, so we can load fracflight
		bsr.w	executenextpart		; start fracflight (loads fractal pictures itself)
		bsr.w	freeall				; free fracflight
		bsr.w	executenextpartalt	; start logo as alternative, so we can load starwars
		bsr.w	executenextpart		; start starwars (frees logo mem and allocates chip itself)

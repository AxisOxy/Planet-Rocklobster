fademinxstart	= 57+8
fademaxxstart	= 312-8
fademinystart	=  18+1
fademaxystart	= 271-4
fademinxgoal	=  49+2
fademaxxgoal	= 319+2
fademinygoal	=  31+10
fademaxygoal	= 232+10

fadestiffness	= 2048
fadedamping1	= 7500
fadedamping2	= 31500

waitname		= TIME_VECFADE2_START

	include "../vecplots/vecfade.asm"

fadecols:
		dc.w	$0336,$0446,$0557,$0677,$0787,$0898,$09a8
fadecols2:
		dc.w	$0ccf,$0ccf,$0ddf,$0ddf,$0eef,$0eef,$0fff
		
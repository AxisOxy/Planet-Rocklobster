fademinxstart	= 104
fademaxxstart	= 284
fademinystart	=  58
fademaxystart	= 238
fademinxgoal	=  57+8
fademaxxgoal	= 312-8
fademinygoal	=  18+1
fademaxygoal	= 275-4

fadestiffness	= 2048
fadedamping1	= 7500
fadedamping2	= 31500

waitname		= TIME_VECFADE1_START

	include "../vecplots/vecfade.asm"

fadecols:
		dc.w	$0000,$0001,$0112,$0113,$0224,$0225,$0336
fadecols2:
		dc.w	$0fff,$0fff,$0eef,$0eef,$0ddf,$0ddf,$0ccf
		
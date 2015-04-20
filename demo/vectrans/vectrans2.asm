col1		= $0654
col2		= $0000
endcol		= $0000
xstart		= $000
ystart		= -600
zstart		= 100
xspeed		= $10
yspeed		= $02
zspeed		= 00
xscale		= 2200
yscale		= 6300
rotstart	= $200
rotspeed	= $0a
dowait		= 1
numframes	= 240

waitname	= TIME_VECTRANS2_START

	include "../vectrans/vectrans.asm"

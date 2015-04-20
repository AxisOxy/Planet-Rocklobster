col1		= $0000
col2		= $0654
endcol		= $0654
xstart		= 800
ystart		= -600
zstart		= 10000
xspeed		= $0e
yspeed		= $12
zspeed		= -40
xscale		= 800
yscale		= 600
rotstart	= $200
rotspeed	= $1a
dowait		= 0
numframes	= 245

waitname	= TIME_VECTRANS1_START

	include "../vectrans/vectrans.asm"

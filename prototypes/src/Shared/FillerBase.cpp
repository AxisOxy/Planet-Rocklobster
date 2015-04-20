#include "include.h"

FillerBase::FillerBase()
{

}

FillerBase::~FillerBase()
{

}


void FillerBase::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);

	FillRect(0,0,320,200,0);
}

void FillerBase::FillRect( int x1, int y1, int x2, int y2, unsigned char col )
{
	int x,y;

	for (y=y1 ; y<y2 ; y++)
	{
		for (x=x1 ; x<x2 ; x++)
		{
			pixelbuffer[y][x]=col;
		}
	}
}

void FillerBase::DoLine( int x1, int y1, int x2, int y2, unsigned char col, bool clip )
{
	int dx,dy,m,x,y;

	dx=x2-x1;
	if(dx==0)
		return;

	if(dx<0)
	{
		int dummy;

		dummy=x1;
		x1=x2;
		x2=dummy;
		dummy=y1;
		y1=y2;
		y2=dummy;
		dx=-dx;
	}

	dy=y2-y1;
	m=(dy<<8)/dx;
	
	y=y1<<8;

	if (dy>0)
	{
		for (x=x1 ; x<x2 ; x++)
		{
			DoPixel(x,y>>8,col,clip);
			y+=m;
		}
	}
	else
	{
		m=-(dy<<8)/dx;
		for (x=x1 ; x<x2 ; x++)
		{
			DoPixel(x,y>>8,col,clip);
			y-=m;
		}
	}
}

void FillerBase::DoLineSubPixel( int x1, int y1, int x2, int y2, unsigned char col, bool clip )
{
	int ix1=x1>>8;
	int ix2=x2>>8;

	int dx,dy,m,x,y;

	dx=ix2-ix1;
	if(dx==0)
		return;

	if(dx<0)
	{
		int dummy;

		dummy=x1;
		x1=x2;
		x2=dummy;
		dummy=y1;
		y1=y2;
		y2=dummy;
		dx=-dx;

		ix1=x1>>8;
		ix2=x2>>8;
	}

	dy=y2-y1;

	int frac=(x1 & 0xff)^0xff;
	m=((y2-y1)<<8)/(x2-x1);
	y=y1+(((m>>8)*frac));
	
	if (dy>0)
	{
		for (x=ix1 ; x<ix2 ; x++)
		{
			DoPixel(x,y>>8,col,clip);
			y+=m;
		}
	}
	else
	{
		for (x=ix1 ; x<ix2 ; x++)
		{
			DoPixel(x,y>>8,col,clip);
			y+=m;
		}
	}
}

void FillerBase::DoPixel( int x, int y, unsigned char col, bool clip )
{
	if (!clip)
	{
		pixelbuffer[y][x]^=col;
		return;
	}

	if (y<0)
		y=0;

	if (x>=0 && x<320 && y<256)
		pixelbuffer[y][x]^=col;
}

void FillerBase::Fill( int x1, int y1, int x2, int y2, unsigned char *pal, bool clipcolor, bool hires )
{
	int x,y;
	unsigned char co;

	for (x=x1 ; x<x2 ; x++)
	{
		co=0;
		for (y=y1 ; y<y2 ; y++)
		{
			co^=pixelbuffer[y][x];
			pixelbuffer[y][x]=co;
			if (!clipcolor || co)
			{
				if (hires)
				{
					gfx->Plot(x,y,GetColor(pal[co]));
				}
				else
				{
					gfx->Plot(x*2  ,y,GetColor(pal[co]));
					gfx->Plot(x*2+1,y,GetColor(pal[co]));
				}
			}
		}
	}
}

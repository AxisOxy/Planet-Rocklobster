#include "include.h"

Gfx::Gfx( Display2D *_display, int _xsize, int _ysize )
{
	buffer=NULL;

	display=_display;
	xsize=_xsize;
	ysize=_ysize;

	buffer=new unsigned int[xsize*ysize];
}

Gfx::~Gfx( void )
{
	if (buffer)	delete [] buffer;
	buffer=NULL;
}

int	Gfx::GetXSize( void )
{
	return xsize;
}

int	Gfx::GetYSize( void )
{
	return ysize;
}

unsigned int* Gfx::GetBuffer()
{
	return buffer;
}

void Gfx::Clear( unsigned int color )
{
	int				x,y;
	unsigned int	*buffer2=buffer;

	for (y=0 ; y<ysize ; y++)
	{
		for (x=0 ; x<xsize ; x++)
			*buffer2++=color;
	}
}

void Gfx::Plot( int x, int y, unsigned int color )
{
	if (x<0 || y<0 || x>=xsize || y>=ysize)
		return;

	buffer[x+y*xsize]=color;
}

unsigned int Gfx::GetPixel( int x, int y )
{
	if (x<0 || y<0 || x>=xsize || y>=ysize)
		return 0;

	return buffer[x+y*xsize];
}

void Gfx::Line( float x1, float y1, float x2, float y2, unsigned int color )
{
	unsigned int	*buffer2;
	int				intx1,intx2,inty1,inty2,x,y;
	float			x3,y3,dx,dy,dxstep,dystep,subpx,subpy;
	
	dx=x2-x1;
	dy=y2-y1;
	if (fabs(dy)>fabs(dx))
	{
		dxstep=dx/dy;
		if (y1>y2)
		{
			x3=x1;
			x1=x2;
			x2=x3;
			y3=y1;
			y1=y2;
			y2=y3;
		}
		
		if (y1<0)
		{
			subpy=1.0f-y1;
			y1=0.0f;
		}
		else
			subpy=1.0f-(float)(y1-int(y1));

		x1+=subpy*dxstep;
	
		inty1=(int)(y1);
		inty2=(int)(y2);
		if (inty2>=ysize)
			inty2=ysize-1;
		
		if (inty1==inty2)
			return;
		
		buffer2=buffer+inty1*xsize;
		for (y=inty1 ; y<inty2 ; y++)
		{
			intx1=(int)(x1);
			if (intx1>=0 && intx1<xsize)
				buffer2[intx1]=color;

			buffer2+=xsize;
			x1+=dxstep;
		}
	}
	else
	{
		dystep=dy/dx;
		if (x1>x2)
		{
			x3=x1;
			x1=x2;
			x2=x3;
			y3=y1;
			y1=y2;
			y2=y3;
		}
		
		if (x1<0)
		{
			subpx=1.0f-x1;
			x1=0.0f;
		}
		else
			subpx=1.0f-(float)(x1-int(x1));
	
		y1+=subpx*dystep;
	
		intx1=(int)(x1);
		intx2=(int)(x2);
		if (intx2>=xsize)
			intx2=xsize-1;
	
		if (intx1==intx2)
			return;

		buffer2=buffer+intx1;
		for (x=intx1 ; x<intx2 ; x++)
		{
			inty1=(int)(y1);
			if (inty1>=0 && inty1<ysize)
				buffer2[inty1*xsize]=color;

			buffer2++;
			y1+=dystep;
		}
	}
}

void Gfx::Box( int x1, int y1, int x2, int y2, unsigned int color, bool filled )
{
	if (x2<x1)
		Swap(x1,x2);

	if (y2<y1)
		Swap(y1,y2);

	if (x1<0)
		x1=0;
	if (x2>=xsize)
		x2=xsize-1;
	if (y1<0)
		y1=0;
	if (y2>=ysize)
		y2=ysize-1;

	if (x2<x1)
		return;

	if (y2<y1)
		return;

	if (filled)
	{
		for (int y=y1 ; y<=y2 ; y++)
		{
			for (int x=x1 ; x<=x2 ; x++)
				buffer[x+y*xsize]=color;
		}
	}
	else
	{
		for (int x=x1 ; x<=x2 ; x++)
		{
			buffer[x+y1*xsize]=color;
			buffer[x+y2*xsize]=color;
		}

		for (int y=y1 ; y<=y2 ; y++)
		{
			buffer[x1+y*xsize]=color;
			buffer[x2+y*xsize]=color;
		}
	}
}

void Gfx::Circle( float x, float y, float radius, unsigned int color, bool filled )
{
	if (filled)
	{
		float xx,yy,d,radius2;

		radius2=radius*radius;
		
		for (yy=-radius ; yy<radius ; yy+=1.0f)
		{
			for (xx=-radius ; xx<radius ; xx+=1.0f)
			{
				d=xx*xx+yy*yy;
				if (d<radius2)
				{
					Plot((int)(x+xx),(int)(y+yy),color);
				}
			}
		}
	}
	else
	{
		float rad,xx,yy,stp;

		stp=1.0f/radius;

		for (rad=0.0f ; rad<2.0f*pi ; rad+=stp)
		{
			xx=OxySin(rad)*radius;
			yy=OxyCos(rad)*radius;

			Plot((int)(x+xx),(int)(y+yy),color);
		}
	}
}		

void Gfx::End( void )
{
	display->Lock();
	display->Blit(buffer,0,0,xsize,ysize);
	display->Unlock();
}

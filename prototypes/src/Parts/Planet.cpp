#include "include.h"

DEFINE_CLASS(Planet,Effect);
		
Planet::Planet()
{
	
}

Planet::~Planet()
{
	BSwapShortArray((unsigned short*)(spheretab), 512);
		
	FileW* filew=new FileW("Data/Parts/Starfield/spheretab.dat");
	filew->Write(spheretab, 1, sizeof(spheretab));
	delete filew;	
}

void Planet::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);

	for (int x=0 ; x<512 ; x++)
	{
		int dx=x-256;

		int y=(int)(OxySqrt((float)(256*256-dx*dx))*128.0f);

		spheretab[x]=32768-y;
	}
}

void Planet::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(0);

	static int frame=0;

	int r1=0;
	int g1=0;
	int b1=0;
	int r2=255;
	int g2=255;
	int b2=255;
	int r3=6*16;
	int g3=10*16;
	int b3=14*16;

	int faktoffs[4] = { 0, 8, 12, 4 };

	unsigned int cols[4][2];

	for (int i=0 ; i<4 ; i++)
	{
		int fakt=frame+faktoffs[i];

		Clamp(fakt, 0, 256);

		int r4=r1+(r3-r1)*fakt/256;
		int g4=g1+(g3-g1)*fakt/256;
		int b4=b1+(b3-b1)*fakt/256;
		int r5=r2+(r3-r2)*fakt/256;
		int g5=g2+(g3-g2)*fakt/256;
		int b5=b2+(b3-b2)*fakt/256;

		Clamp(r4, 0, 255);
		Clamp(g4, 0, 255);
		Clamp(b4, 0, 255);
		Clamp(r5, 0, 255);
		Clamp(g5, 0, 255);
		Clamp(b5, 0, 255);

		r4/=16;
		g4/=16;
		b4/=16;
		r5/=16;
		g5/=16;
		b5/=16;
	
		unsigned int col1=(r4<<20) | (g4<<12) | (b4<<4);
		unsigned int col2=(r5<<20) | (g5<<12) | (b5<<4);

		cols[i][0]=col1;
		cols[i][1]=col2;
	}

	for (int y=0 ; y<256 ; y++)
	{
		for (int x=0 ; x<320 ; x++)
		{
			int i=(x & 1) | ((y & 1)<<1);

			gfx->Plot(x, y, cols[i][0]);
		}
	}

	int ra=(500+frame);

	int yoff=256-frame;

	int x1=(ra-256)/2;
	int x2=511-x1;
	
	int dx=x2-x1;
	int stepx=dx*256/320;
	x1*=256;
	
	for (int x=0 ; x<320 ; x++)
	{
		int y1=spheretab[x1>>8]*ra/32768+yoff;

		for (int y=y1 ; y<256 ; y++)
		{
			int i=(x & 1) | ((y & 1)<<1);

			gfx->Plot(x, y, cols[i][1]);
		}
		x1+=stepx;
	}

	frame++;

	Sleep(15);
}

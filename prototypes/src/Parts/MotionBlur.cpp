#include "include.h"

/*
	TODO:	- export data
*/

DEFINE_CLASS(MotionBlur,Effect);
		
MotionBlur::MotionBlur()
{
	memset(pal, 0, sizeof(pal));
	
	memset(buffer, 0, sizeof(buffer));
}

MotionBlur::~MotionBlur()
{
	unsigned short tmptex[128*128];
	
	for (int i=0 ; i<128*128 ; i++)
	{
		tmptex[i]=texture[i]*2;
	}

	BSwapShortArray(tmptex, 128*128);

	FileW* filew=new FileW("Data/Parts/MotionBlur/texture.dat");
	filew->Write(tmptex, 1, sizeof(tmptex));
	delete filew;

	filew=new FileW("Data/Parts/MotionBlur/texturecomp.dat");
	filew->Write(texture, 1, 128*128);
	delete filew;

	unsigned char amipal[16][2];

	for (int i=0 ; i<16 ; i++)
	{
		unsigned int col=pal[i];
		int r=(col>>20) & 0x0f;
		int g=(col>>12) & 0x0f;
		int b=(col>> 4) & 0x0f;

		unsigned char lo=(g<<4) | (b);
		unsigned char hi=r;

		amipal[i][0]=hi;
		amipal[i][1]=lo;
	}

	filew=new FileW("Data/Parts/MotionBlur/pal.dat");
	filew->Write(amipal, 1, sizeof(amipal));
	delete filew;

	BSwapShortArray((unsigned short*)(sintab), 2560);

	filew=new FileW("Data/Parts/MotionBlur/sintab.dat");
	filew->Write(sintab, 1, sizeof(sintab));
	delete filew;
}

void MotionBlur::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);

	for ( int i=0 ; i<2560 ; i++ )
	{
		sintab[i]=(short)(OxySin((float)(i)*2.0f*pi/2048.0f)*16383.5f);
	}	

	Image image;

	image.Load("Data/Parts/MotionBlur/asteroid2.png");

	int width=image.GetWidth();
	int height=image.GetHeight();
	
	if (width!=128 || height!=128)
	{
		char msg[256];

		sprintf(msg, "Texture has wrong size: %ix%i (instead of 128x128)", width, height);

		MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
		exit(0);
	}

	for (int y=0 ; y<128 ; y++)
	{
		for (int x=0 ; x<128 ; x++)
		{
			unsigned int col=image.GetPixel(x, y);

			unsigned char co=(col & 0xff)>>4;

			co=co*240/256;

			texture[y*128+x      ]=co;
			texture[y*128+x+16384]=co;
		}
	}

	image.Load("Data/Parts/MotionBlur/colors.png");

	width=image.GetWidth();
	height=image.GetHeight();
	
	if (width!=256 || height!=1)
	{
		char msg[256];

		sprintf(msg, "Color-spread has wrong size: %ix%i (instead of 256x1)", width, height);

		MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
		exit(0);
	}

	int palsize=0;
	memset(pal,0,sizeof(pal));

	for (int y=0 ; y<1 ; y++)
	{
		for (int x=0 ; x<256 ; x++)
		{
			unsigned int col=image.GetPixel(x, y);

			
			if (palsize>=256)
			{
				char msg[256];

				sprintf(msg, "Color-spread has too many colors (>256)", palsize);

				MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
				exit(0);
			}

			pal[palsize]=col;
			palsize++;
		}
	}

	for (int i=0 ; i<palsize ; i++)
	{
		unsigned int col=pal[i];

		int r=(col>>16) & 0xff;
		int g=(col>> 8) & 0xff;
		int b=(col    ) & 0xff;

		//r=(r-64)*255/191;
		//g=(g-64)*255/191;
		b=(b-64)*256/192;

		Clamp(r, 0, 255);
		Clamp(g, 0, 255);
		Clamp(b, 0, 255);

		col=(r<<16) | (g<<8) | (b);

		pal[i]=col;
	}
}

void MotionBlur::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(0);

	static int frame=0;

	int line=frame & 0x7f;

	static int xoffs[128][160];
	static int yoffs[128][100];
	static int xoffs2[128][160];
	static int yoffs2[128][100];

	if (frame==0)
	{
		memset(xoffs, 0, sizeof(xoffs));
		memset(xoffs2, 0, sizeof(xoffs2));
		memset(yoffs, 0, sizeof(yoffs));
		memset(yoffs2, 0, sizeof(yoffs2));
	}

	for (int i=0 ; i<2 ; i++)
	{
		int frame2=(frame+i*16)*1;

		int scale=(sintab[(frame2*6) & 0x7ff]+24000)>>4;
		int uoff=64*65536;
		int voff=64*65536;

		int rotframe=((sintab[(frame2+512) & 0x7ff]/12) & 0x7ff);

		int stepux=sintab[(rotframe     ) & 0x7ff];
		int stepvx=sintab[(rotframe+ 512) & 0x7ff];
		int stepuy=sintab[(rotframe+ 512) & 0x7ff];
		int stepvy=sintab[(rotframe+1024) & 0x7ff];
		
		stepux=stepux*scale/256;
		stepvx=stepvx*scale/256;
		stepuy=stepuy*scale/256;
		stepvy=stepvy*scale/256;
		
		int ux=uoff-stepux*80;
		int uy=    -stepuy*50;
		int vx=voff-stepvx*80;
		int vy=    -stepvy*50;

		for(int x=0 ; x<160 ; x++)
		{
			xoffs[line][x]=((ux>>16) & 0x7f) | (((vx>>16) & 0x7f)<<7);
			
			ux+=stepux;
			vx+=stepvx;	
		}

		for(int y=0 ; y<100 ; y++)
		{
			yoffs[line][y]=((uy>>16) & 0x7f) | (((vy>>16) & 0x7f)<<7);
			
			uy+=stepuy;
			vy+=stepvy;	
		}

		if (i==0)
		{
			memcpy(xoffs2[line], xoffs[line], sizeof(xoffs2[line]));
			memcpy(yoffs2[line], yoffs[line], sizeof(yoffs2[line]));
		}
	}

	unsigned char dithertab[4][2][2] = {	0x01, 0x00, 
											0x00, 0x00, 

											0x01, 0x00, 
											0x00, 0x01, 

											0x01, 0x00, 
											0x01, 0x01, 

											0x01, 0x01, 
											0x01, 0x01 };

	static bool colorcycle=false;
	if (input->WasKeyHit(KB_C))
		colorcycle=!colorcycle;

	if (frame>=128)
	{
		int offoff=frame;
		int cooff=frame & 0xff;
		if (!colorcycle)
			cooff=0;

		for(int y=0 ; y<100 ; y++)
		{
			int y2=(y/2+offoff+16) & 0x7f;

			//int yoff1=yoffs[y2][y];
			//int yoff2=yoffs2[y2][y];
			int yoff1=yoffs[line][y];
			int yoff2=yoffs2[line][y];
			
			for(int x=0 ; x<160 ; x++)
			{
				int off1=xoffs[y2][x]+yoff1;
				int off2=xoffs2[y2][x]+yoff2;
				
				int bufoff=y*160+x;

				buffer[bufoff]+=texture[off1];
				if (frame>=(128+16))
					buffer[bufoff]-=texture[off2];
		
				unsigned char co=buffer[bufoff]>>2;
				unsigned char coint=co>>2;
				
				coint+=dithertab[co & 0x03][y & 1][x & 1];

				unsigned int col=pal[(coint+cooff) & 0xff] & 0xf0f0f0;
			
				gfx->Plot(x*2  , y*2  , col);
				gfx->Plot(x*2+1, y*2+1, col);
			}
		}
	}

	frame++;
	
	if (frame>128)
		Sleep(45);
}

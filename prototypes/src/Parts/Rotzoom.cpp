#include "include.h"

/*
	TODO:	- make math in int and table based
*/

DEFINE_CLASS(Rotzoom,Effect);
		
Rotzoom::Rotzoom()
{
	memset(pal, 0, sizeof(pal));
	
}

Rotzoom::~Rotzoom()
{
	Image image;

	image.Load("Data/Parts/Rotzoom/hairdog128_hc.png");

	unsigned char buffer[128][128][2];

	for (int y=0 ; y<128 ; y++)
	{
		for (int x=0 ; x<128 ; x++)
		{
			unsigned int col=image.GetPixel(x, y);
			int r=(col>>20) & 0x0f;
			int g=(col>>12) & 0x0f;
			int b=(col>> 4) & 0x0f;

			unsigned char lo=(g<<4) | (b);
			unsigned char hi=r;

			buffer[y][x][0]=hi;
			buffer[y][x][1]=lo;
		}
	}

	FileW* filew=new FileW("Data/Parts/Rotzoom/hairdog128.chunky");
	filew->Write(buffer,1,sizeof(buffer));
	delete filew;


	unsigned char mask[5][2][40];

	memset(mask,0,sizeof(mask));

	unsigned char dithertab[2][2][2] = {	0x00, 0x00, 
											0x00, 0x00, 
											
											0x01, 0x00, 
											0x00, 0x01 };

	for (int x=0 ; x<128 ; x++)
	{
		for (int y=0 ; y<2 ; y++)
		{
			unsigned char co=x/2;
			unsigned char dither=co & 1;
			unsigned char id=co>>1;

			if (dithertab[dither][x&1][y&1])
			{
				id++;
			}

			Clamp(id, (unsigned char)(0), (unsigned char)(31));

			for (int bpl=0 ; bpl<5 ; bpl++)
			{
				unsigned char bit=(id>>bpl) & 1;
				
				int xoff=x/8+12;
				int shift=7-(x&7);

				mask[bpl][y][xoff]|=(bit<<shift);
			}
		}
	}

	filew=new FileW("Data/Parts/Rotzoom/mask.bpl");
	filew->Write(mask,1,sizeof(mask));
	delete filew;


	typedef std::set<unsigned int>	Histogram;
	typedef Histogram::iterator		HistoIter;

	Histogram histo;

	image.Load("Data/Parts/Rotzoom/hairdog320.png");

	for (int y=0 ; y<200 ; y++)
	{
		for (int x=0 ; x<320 ; x++)
		{
			unsigned int col=image.GetPixel(x, y);

			if (histo.find(col)==histo.end())
			{
				histo.insert(col);
			}
		}
	}

	int palsize2=0;
	unsigned int pal2[16];
	unsigned char pal4[16][2];

	HistoIter iter=histo.begin();
	while(iter!=histo.end())
	{
		pal2[palsize2]=*iter;
		palsize2++;
		++iter;
	}

	unsigned char planes[9*4*256*40];
	
	memset(planes,0,sizeof(planes));

	int baseoff=0;
						 
	int imagewidths[] = { 40, 40, 36, 36, 32, 32, 28, 28, 24, 24 };
	int imagexoffs[] = {   0,  0, 16, 16, 32, 32, 48, 48, 64, 64 };

	for (int scale=0 ; scale<9 ; scale++)
	{
		int x1=scale*8;
		int x2=319-scale*8;
		
		float ustep=320.0f/(float)(x2-x1);
	
		int imagexoff=imagexoffs[scale];
		int usedwidth=imagewidths[scale];
		int bplsize=usedwidth*256;
		int imagesize=bplsize*4;
		x1-=imagexoff;
		x2-=imagexoff;

		for (int y=0 ; y<256 ; y++)
		{
			float u=0.0f;
		
			for (int x=x1 ; x<=x2 ; x++)
			{
				int intu=(int)(u) % 320;

				unsigned int col=image.GetPixel(intu, y);
				int palid=0;
				for (int i=0 ; i<palsize2 ; i++)
				{
					if (pal2[i]==col)
					{
						palid=i;
						break;
					}
				}

				Clamp(palid, 0, 15);

				for (int bpl=0 ; bpl<4 ; bpl++)
				{
					unsigned char bit=(palid>>bpl) & 1;
					
					int xoff=x/8;
					int shift=7-(x&7);

					int off=baseoff+xoff+y*usedwidth+bpl*bplsize;

					planes[off]|=(bit<<shift);
				}
				u+=ustep;
			}
		}

		baseoff+=imagesize;
	}

	for (int i=0 ; i<16 ; i++)
	{
		unsigned int col=pal2[i];
		int r=(col>>20) & 0x0f;
		int g=(col>>12) & 0x0f;
		int b=(col>> 4) & 0x0f;

		unsigned char lo=(g<<4) | (b);
		unsigned char hi=r;

		pal4[i][0]=hi;
		pal4[i][1]=lo;
	}

	filew=new FileW("Data/Parts/Rotzoom/imagescaled.pal");
	filew->Write(pal4, 1, 32);
	delete filew;

	filew=new FileW("Data/Parts/Rotzoom/imagescaled.bpl");
	filew->Write(planes, 1, baseoff);
	delete filew;

	
	image.Load("Data/Parts/Rotzoom/hairdog128_2.png");

	int width=image.GetWidth();
	int height=image.GetHeight();

	palsize2=0;
	unsigned char pixels[128][128];

	memset(pal2, 0, sizeof(pal2));
	memset(pixels, 0, sizeof(pixels));

	for (int y=0 ; y<height ; y++)
	{
		for (int x=0 ; x<width ; x++)
		{
			unsigned int col=image.GetPixel(x, y);
			bool found=false;
			for (int i=0 ; i<palsize2 ; i++)
			{
				if (col==pal2[i])
				{
					found=true;
					break;
				}
			}

			if (!found)
			{
				pal2[palsize2]=col;
				palsize2++;
			}
		}
	}
	
	for (int y=0 ; y<height ; y++)
	{
		for (int x=0 ; x<width ; x++)
		{
			unsigned int col=image.GetPixel(x, y);
			unsigned char co=0;
			for (int i=0 ; i<palsize2 ; i++)
			{
				if (col==pal2[i])
				{
					co=i;
					break;
				}
			}

			pixels[y][x]=co;
		}
	}

	for (int i=0 ; i<16 ; i++)
	{
		unsigned int col=pal[i];
		int r=(col>>20) & 0x0f;
		int g=(col>>12) & 0x0f;
		int b=(col>> 4) & 0x0f;

		unsigned char lo=(g<<4) | (b);
		unsigned char hi=r;

		pal4[i][0]=hi;
		pal4[i][1]=lo;
	}

	filew=new FileW("Data/Parts/Rotzoom/hairdog128chunky4.pal");
	filew->Write(pal4, 1, sizeof(pal4));
	delete filew;
	
	filew=new FileW("Data/Parts/Rotzoom/hairdog128chunky4.dat");
	filew->Write(pixels, 1, sizeof(pixels));
	delete filew;

	filew=new FileW("Data/Parts/Rotzoom/texture.pal");
	filew->Write(pal4, 1, 32);
	delete filew;

	filew=new FileW("Data/Parts/Rotzoom/texture.dat");
	filew->Write(textures[0], 1, sizeof(textures[0]));
	delete filew;
}

void Rotzoom::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);

	for ( int i=0 ; i<2560 ; i++ )
	{
		sintab[i]=(short)(OxySin((float)(i)*2.0f*pi/2048.0f)*16383.5f);
	}	

	Image image;

	image.Load("Data/Parts/Rotzoom/spaceship1.png");

	int width=image.GetWidth();
	int height=image.GetHeight();
	
	if (width!=64 || height!=64)
	{
		char msg[256];

		sprintf(msg, "Texture has wrong size: %ix%i (instead of 64x64)", width, height);

		MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
		exit(0);
	}

	int palsize=1;
	memset(pal,0,sizeof(pal));

	for (int y=0 ; y<64 ; y++)
	{
		for (int x=0 ; x<64 ; x++)
		{
			unsigned int col=image.GetPixel(x, y);

			bool found=false;

			for (int i=0 ; i<palsize ; i++)
			{
				if (col==pal[i])
				{
					found=true;
					break;
				}
			}

			if (!found)
			{
				if (palsize>=16)
				{
					char msg[256];

					sprintf(msg, "Texture has too many colors (>15)", palsize);

					MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
					exit(0);
				}

				pal[palsize]=col;
				palsize++;
			}
		}
	}

	// sort pal by brightness
	for (int i=0 ; i<palsize ; i++)
	{
		unsigned int col1=pal[i];
		int r1=(col1>>16) & 0xff;
		int g1=(col1>> 8) & 0xff;
		int b1=(col1    ) & 0xff;
		int bright1=r1+g1+b1;
		for (int j=0 ; j<i ; j++)
		{
			unsigned int col2=pal[j];
			int r2=(col2>>16) & 0xff;
			int g2=(col2>> 8) & 0xff;
			int b2=(col2    ) & 0xff;
			int bright2=r2+g2+b2;
			if (bright2>bright1)
			{
				Swap(pal[i], pal[j]);			
			}
		}
	}

	for (int y=0 ; y<64 ; y++)
	{
		for (int x=0 ; x<64 ; x++)
		{
			unsigned int col=image.GetPixel(x, y);

			unsigned char co=0;

			for (int i=0 ; i<palsize ; i++)
			{
				if (col==pal[i])
				{
					co=i;
					break;
				}
			}

			textures[0][y][x]=co;
		}
	}

	PrepareTexture();
}

void Rotzoom::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(0);

	static int frame=0;

	int texid=(1-(frame>>9)) & 0x03;

	// here we need to calculate the scaling needed to compensate the shearing
	int scale=(sintab[(frame*1) & 0x7ff]+26200)>>5;
	int uoff=sintab[(frame/2+500) & 0x7ff]*1500;
	int voff=sintab[(frame/3+900) & 0x7ff]*1500;

	switch(texid)
	{
		case 0:
		break;

		case 1:
			Swap(uoff, voff);
			voff=-voff;
		break;

		case 2:
			uoff=-uoff;
			voff=-voff;
		break;

		case 3:
			Swap(uoff, voff);
			uoff=-uoff;
		break;
	}

	int rotframe=((frame*1) & 511)+1024+256;

	int stepux=sintab[(rotframe     ) & 0x7ff];
	int stepvx=sintab[(rotframe+ 512) & 0x7ff];
	int stepuy=sintab[(rotframe+ 512) & 0x7ff];
	int stepvy=sintab[(rotframe+1024) & 0x7ff];
	
	int corscale=16384*16384/stepux;
	
	stepux=stepux*scale/256;
	stepvx=stepvx*scale/256;
	stepuy=stepuy*corscale/4096;
	stepvy=scale*corscale/256;

	int ux=uoff-stepux*260;
	int uy=    -stepuy*100;
	int vx=voff-stepvx*260;
	int vy=    -stepvy*100;

	int uxs[520];
	int vxs[520];
	int uys[200];
	int vys[200];

	int numsplits=0;
	int xsplits[100];
	int splitvs[100];

	int lastu=ux>>16;
	int startv=vx>>16;

	for(int x=0 ; x<520 ; x++)
	{
		int u=(ux>>16);
		int v=(vx>>16);
		uxs[x]=u & 0x3f;
		vxs[x]=v & 0x3f;

		if ((u-lastu)<=-64)
		{
			xsplits[numsplits]=x;
			splitvs[numsplits]=v-startv;
			numsplits++;
			lastu-=64;
		}
		
		ux+=stepux;
		vx+=stepvx;	
	}

	int spanwidth=xsplits[0]+2;

	static int maxspanwidth=0;

	maxspanwidth=Max(spanwidth, maxspanwidth);
	
	for(int y=0 ; y<200 ; y++)
	{
		uys[y]=uy>>16;
		vys[y]=vy>>16;
		
		uy+=stepuy;
		vy+=stepvy;	
	}

	unsigned char tmpbuf[64][800];

	for(int y=0 ; y<64 ; y++)
	{
		for(int x=0 ; x<spanwidth ; x++)
		{
			int u=(uxs[x]+0) & 0x3f;
			int v=(vxs[x]+y) & 0x3f;

			tmpbuf[y][x]=textures[texid][v][u];
		}
	}

	for (int i=0 ; i<numsplits ; i++)
	{
		int x=xsplits[i];
		int v=splitvs[i];

		for (int x2=0 ; x2<spanwidth ; x2++)
		{
			int xx=x2+x;

			for (int y=0 ; y<64 ; y++)
			{
				tmpbuf[y][xx]=tmpbuf[(y+v) & 0x3f][x2];
			}
		}
	}

	for(int y=0 ; y<200 ; y++)
	{
		int xoff=uys[y]-100;
		int yoff=vys[y] & 0x3f;
		
		for(int x=0 ; x<520 ; x++)
		{
			unsigned int col=pal[tmpbuf[yoff][x]];
			int xx=x+xoff;
			if (xx<320)
				gfx->Plot(x+xoff, y, col);
		}
	}

	frame+=16;

	Sleep(30);
}

void Rotzoom::PrepareTexture( void )
{
	for (int i=0 ; i<3 ; i++)
	{
		for (int y=0 ; y<64 ; y++)
		{
			for (int x=0 ; x<64 ; x++)
			{
				textures[i+1][y][x]=textures[i][x][0x3f-y];
			}
		}
	}
}

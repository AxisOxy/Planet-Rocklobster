#include "include.h"

DEFINE_CLASS(Starfield,FillerBase);
		
Starfield::Starfield()
{
	
}

Starfield::~Starfield()
{
	unsigned short sprite1[34][2];
	unsigned short sprite2[34][2];

	int numletters=letters.size();

	FileW* filew=new FileW("Data/Parts/Starfield/font.dat");

	for (int i=0 ; i<numletters ; i++)
	{
		memset(sprite1, 0, sizeof(sprite1));
		memset(sprite2, 0, sizeof(sprite2));

		Letter &letter=letters[i];

		for (int y=0 ; y<32 ; y++)
		{
			for (int x=0 ; x<16 ; x++)
			{
				unsigned char co=letter.pixels[y][x];
				if (co & 1)
					sprite1[y][0]|=(0x8000>>x);

				if (co & 2)
					sprite1[y][1]|=(0x8000>>x);
					
				if (co & 4)
					sprite2[y][0]|=(0x8000>>x);
					
				if (co & 8)
					sprite2[y][1]|=(0x8000>>x);
			}
		}

		BSwapShortArray((unsigned short*)(sprite1), 34*2);
		BSwapShortArray((unsigned short*)(sprite2), 34*2);

		filew->Write(sprite1, 1, sizeof(sprite1));
		filew->Write(sprite2, 1, sizeof(sprite2));
	}
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

	filew=new FileW("Data/Parts/Starfield/pal.dat");
	filew->Write(amipal, 1, sizeof(amipal));
	delete filew;	


	Image satimage;

	satimage.Load("Data/Parts/Starfield/sat.png");

	unsigned short satellite[8][64][2];
	unsigned char satpixels[64][64];
	unsigned int satpal[16];

	memset(satellite, 0, sizeof(satellite));
	memset(satpixels, 0, sizeof(satpixels));
	memset(satpal, 0, sizeof(satpal));

	int palsize=0;

	for (int y=0 ; y<63 ; y++)
	{
		for (int x=0 ; x<64 ; x++)
		{
			unsigned int col=satimage.GetPixel(x, y);

			bool found=false;

			for (int i=0 ; i<palsize ; i++)
			{
				if (col==satpal[i])
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

					sprintf(msg, "Satellite has too many colors (>16)", palsize);

					MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
					exit(0);
				}

				satpal[palsize]=col;
				palsize++;
			}
		}
	}

	for (int y=0 ; y<63 ; y++)
	{
		for (int x=0 ; x<64 ; x++)
		{
			unsigned int col=satimage.GetPixel(x, y);

			unsigned char co=0;

			for (int i=0 ; i<palsize ; i++)
			{
				if (col==satpal[i])
				{
					co=i;
					break;
				}
			}

			satpixels[y][x]=co;			
		}
	}

	for (int x1=0 ; x1<4 ; x1++)
	{
		for (int y=0 ; y<64 ; y++)
		{
			for (int x=0 ; x<16 ; x++)
			{
				unsigned char co=satpixels[y][x+x1*16];
				if (co & 1)
					satellite[x1*2][y][0]|=(0x8000>>x);

				if (co & 2)
					satellite[x1*2][y][1]|=(0x8000>>x);
					
				if (co & 4)
					satellite[x1*2+1][y][0]|=(0x8000>>x);
					
				if (co & 8)
					satellite[x1*2+1][y][1]|=(0x8000>>x);
			}
		}
	}
	
	BSwapShortArray((unsigned short*)(satellite), 8*64*2);
	
	for (int i=0 ; i<16 ; i++)
	{
		unsigned int col=satpal[i];
		int r=(col>>20) & 0x0f;
		int g=(col>>12) & 0x0f;
		int b=(col>> 4) & 0x0f;

		unsigned char lo=(g<<4) | (b);
		unsigned char hi=r;

		amipal[i][0]=hi;
		amipal[i][1]=lo;
	}

	filew=new FileW("Data/Parts/Starfield/satpal.dat");
	filew->Write(amipal, 1, sizeof(amipal));
	delete filew;	

	filew=new FileW("Data/Parts/Starfield/satsprites.dat");
	filew->Write(satellite, 1, sizeof(satellite));
	delete filew;	


	Image image;

	image.Load("Data/Parts/Starfield/glider_rider.gif");

	unsigned char fontbpl[26][16][2];

	memset(fontbpl, 0, sizeof(fontbpl));

	int i=0;
	for (int y1=0 ; y1<2 ; y1++)
	{
		for (int x1=0 ; x1<13 ; x1++)
		{
			for (int y2=0 ; y2<16 ; y2++)
			{
				for (int x2=0 ; x2<16 ; x2++)
				{
					int xx=x1*16+x2;
					int yy=y1*16+y2;

					if (i==5)
						int huhu=1;

					unsigned int col=image.GetPixel(xx, yy);
					
					if (col & 0xffffff)
						fontbpl[i][y2][x2/8]|=(0x80>>(x2 & 7));
				}
			}
			i++;
		}
	}

	filew=new FileW("Data/Parts/Starfield/upscrollfont.dat");
	filew->Write(fontbpl, 1, sizeof(fontbpl));
	delete filew;	
}

void Starfield::Init( Gfx *_gfx, Input *_input )
{	
	FillerBase::Init(_gfx,_input);
	
	Image image;

	image.Load("Data/Parts/Starfield/font.png");
	
	Letter letter;

	int width=image.GetWidth();
	int height=image.GetHeight();
	
	int palsize=0;
	memset(pal,0,sizeof(pal));

	for (int y=0 ; y<height ; y++)
	{
		for (int x=0 ; x<width ; x++)
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

					sprintf(msg, "Font has too many colors (>16)", palsize);

					MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
					exit(0);
				}

				pal[palsize]=col;
				palsize++;
			}
		}
	}

	int xoffs[] = { 0, 15, 15, 15, 1, 2, 15, 15, 3, 15, 4, 5, 15, 6, 7, 15, 15, 13, 8, 9, 15, 15, 15, 10, 11, 12 };

	for (int i=0 ; i<26 ; i++)
	{
		int xoff=xoffs[i]*16;
		int yoff=0;
		
		memset(letter.pixels, 0, sizeof(letter.pixels));

		for (int y=0 ; y<32 ; y++)
		{
			for (int x=0 ; x<16 ; x++)
			{
				unsigned int col=image.GetPixel(x+xoff, y+yoff);

				unsigned char co=0;

				for (int i=0 ; i<palsize ; i++)
				{
					if (col==pal[i])
					{
						co=i;
						break;
					}

					int huhu=1;
				}

				letter.pixels[y][x]=co;
			}
		}

		letters.push_back(letter);
	}
}

void Starfield::Update( float _rendertime )
{
	FillerBase::Update(_rendertime);

	gfx->Clear(0);

	char* texts[] = {	"axis",
						"faker",
						"yazoo",
						"alien",
						"nytrik",
						"fanta" };

	for (int i=0 ; i<6 ; i++)
	{
		char* text=texts[i];
		int len=strlen(text);

		for (int j=0 ; j<len ; j++)
		{
			unsigned char va=(text[j]-1) & 0x1f;

			Letter &letter=letters[va];

			for (int y=0 ; y<32 ; y++)
			{
				for (int x=0 ; x<16 ; x++)
				{
					unsigned char co=letter.pixels[y][x];
					unsigned int col=pal[co];
					gfx->Plot(x+j*16, y+i*32, col);
				}
			}
		}
	}

	Sleep(15);
}

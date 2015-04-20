#include "include.h"

/*
	TODO:	- 
*/

DEFINE_CLASS(Greets,Effect);
		
Greets::Greets()
{
	
}

Greets::~Greets()
{
	FileW* filew=new FileW("Data/Parts/Greets/font.dat");

	for (int i=0 ; i<27 ; i++)
	{
		Glyph& glyph=glyphs[i];

		short width=BSwapShort(glyph.width);
		filew->Write(&width, 1, sizeof(width));

		for (int x=0 ; x<glyph.width ; x++)
		{
			for (int j=0 ; j<8 ; j++)
			{
				filew->Write(&glyph.data[x][j], 1, 1);
			}
		}
	}

	delete filew;
}

void Greets::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);

	font.Load("Data/Parts/Greets/falsepos.ttf", 85);

	Glyph glyph;
	
	int maxx=0;
	int miny=255;
	int maxy=0;
	int maxcount=0;

	char *convtext = "abcdefghijklmnopqrstuvwxyz2";

	for (int i=0 ; i<27 ; i++)
	{
		Image* image=font.GetGlyph(convtext[i]);

		memset(glyph.data, 0xffff, sizeof(glyph.data));

		glyph.width=image->GetWidth();
		for (int x=0 ; x<glyph.width ; x++)
		{
			maxx=Max(maxx, x);

			bool pixvis=false;
			bool oldpixvis=false;
			int count=0;
			for (int y=0 ; y<image->GetHeight() ; y++)
			{
				unsigned int col=image->GetPixel(x, y);
				pixvis=false;
				if (col & 0xff)
					pixvis=true;

				if (pixvis!=oldpixvis)
				{
					glyph.data[x][count++]=y;
					miny=Min(miny, y);
					maxy=Max(maxy, y);
					maxcount=Max(maxcount, count);
				}
				oldpixvis=pixvis;
			}

			if (oldpixvis)
			{
				int y=image->GetHeight();
				glyph.data[x][count++]=y;
				miny=Min(miny, y);
				maxy=Max(maxy, y);
				maxcount=Max(maxcount, count);
			}
		}	

		glyphs.push_back(glyph);
	}

	for (int i=0 ; i<27 ; i++)
	{
		Glyph& glyph=glyphs[i];

		for (int x=0 ; x<glyph.width ; x++)
		{
			for (int j=0 ; j<8 ; j++)
			{
				char y=glyph.data[x][j];
				if (y<0)
					break;

				glyph.data[x][j]-=miny;
				if (glyph.data[x][j]>=64)
				{
					char msg[256];

					sprintf(msg, "Font is too big (higher than 64 pixels: %d)!", glyph.data[x][j]+1);

					MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
					exit(0);
				}
			}
		}
	}
}

void Greets::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(0);


	static int frame=0;

	FillRect(0, 0, 320, 256, 0);

	char *texts[] = {	"greets fly to",
						"active",
						"algotech",		
						"ancients",		
						"andromeda",
						"arsenic",		
						"bauknecht",		
						"booze design",		
						"camelot",		
						"censor design",
						"checkpoint",
						"dekadence",
						"desire",
						"fairlight",		
						"farbrausch",
						"fan",
						"genesis project",
						"hoaxers",		
						"k2",		
						"metalvotze",
						"nah kolor",
						"nuance",		
						"offence",		
						"onslaught",		
						"plush",		
						"powerline",
						"resource",		
						"scoopex",
						"shape",
						"smash designs",		
						"spaceballs",
						"starion",
						"success and trc",
						"the black lotus",
						"the dreams",		
						"tek",		
						"triad",		
						"trsi",		
						"welle erdball"	};			

	static float xcenters[40];
	static float ycenters[40];

	if (frame==0)
	{
		for (int i=0 ; i<40 ; i++)
		{
			xcenters[i]=randomf(-1.60f*2.0f, 1.60f*2.0f);
			ycenters[i]=randomf(-1.28f*2.0f, 1.28f*2.0f);
		}
	}

	float nearplane=1.0f;
	float farplane=128.0f;

	float texzs[16];

	float camx=OxySin(time*0.0011f)*1.60f*2.0f;
	float camy=OxySin(time*0.0013f)*1.28f*2.0f;

	int texcount=-1;
	for (int k=0 ; k<39 ; k++)
	{
		float z=k*32+farplane-(float)(frame);
		if (z>nearplane && z<farplane)
		{
			texcount++;
			texzs[texcount]=z;

			unsigned char co=1<<texcount;

			char* text=texts[k];
			float xcenter=xcenters[k]-camx;
			float ycenter=ycenters[k]-camy;
				
			float scale=1280.0f/z;

			int len=strlen(text);
		
			int xpos=0;

			short	width;
			char	wordbuf[1024][8];

			memset(wordbuf, -1, sizeof(wordbuf));

			for (int i=0 ; i<len ; i++)
			{
				unsigned char va=text[i];
				if (va==0x20)
					xpos+=16;
				else
				{
					if (va=='2')
						va=27;

					Glyph& glyph=glyphs[(va-1) & 0x1f];

					for (int x=0 ; x<glyph.width ; x++)
					{
						int xx=xpos+x;

						int count=0;
				
						for (int j=0 ; j<8 ; j++)
						{
							char y=glyph.data[x][j];
							if (y<0)
								break;

							wordbuf[xx][count++]=y;
						}
					}
					xpos+=glyph.width;
				}
			}

			width=xpos;

			int screenwidth=(int)(width*scale/64.0f);

			float u=0.0f;
			float ustep=64.0f/scale;

			xpos=(int)(160.0f+xcenter*scale-screenwidth/2.0f);
			int ypos=(int)(128.0f+ycenter*scale-scale/2.0f);

			for (int x=0 ; x<=screenwidth ; x++)
			{
				int intu=(int)(u);
				if (intu>width)
					break;

				for (int j=0 ; j<8 ; j++)
				{
					int y=wordbuf[intu][j];
					if (y<0)
						break;
					
					y=(int)(y*scale/64.0f+ypos);
					if (y>=256)
						break;

					if (y<0)
						y=0;

					int xx=xpos+x;
					if (xx>=0 && xx<320)
						pixelbuffer[y][xx]^=co;
				}
				u+=ustep;
			}	
		}
	}

	texcount++;

	unsigned int tmppal[16];
	unsigned int pal[16];

	memset(tmppal, 0, sizeof(tmppal));

	for (int i=0 ; i<texcount ; i++)
	{
		float z=texzs[i];
		unsigned int co=(int)(192.0f*(farplane-z)/(farplane-nearplane))+64;

		unsigned int col=(co<<16) | (co<<8) | (co);
		tmppal[i+1]=col;
	}

	for (int i=0 ; i<16 ; i++)
	{
		int paloff=0;
		if (i & 8)
			paloff=4;
		if (i & 4)
			paloff=3;
		if (i & 2)
			paloff=2;
		if (i & 1)
			paloff=1;

		pal[i]=tmppal[paloff];
	}

	for (int x=0 ; x<320 ; x++)
	{
		unsigned char co=0;
		for (int y=0 ; y<256 ; y++)
		{
			co^=pixelbuffer[y][x];
			pixelbuffer[y][x]=co;
			gfx->Plot(x, y, pal[co]);
		}
	}

	frame++;

	Sleep(15);
}

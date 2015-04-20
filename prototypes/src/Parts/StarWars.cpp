#include "include.h"

/*
	TODO:	- 
*/

DEFINE_CLASS(StarWars,Effect);
		
StarWars::StarWars()
{
	memset(shadetab, 0, sizeof(shadetab));
	memset(linewidths, -1, sizeof(linewidths));
	memset(linevs, -1, sizeof(linevs));
}

StarWars::~StarWars()
{	
	FileW* filew=new FileW("Data/Parts/StarWars/shadetab.dat");
	filew->Write(shadetab, 1, sizeof(shadetab));
	delete filew;
	
	unsigned char linewidthscomp[256][4];
	unsigned char linevscomp[0x10000];
	int	linevssize=0;
	
	for (int frame=0 ; frame<256 ; frame++)
	{
		unsigned char minx=0;
		unsigned char maxx=0;
		unsigned char miny=0;
		unsigned char maxy=0;

		for (int y=0 ; y<256 ; y++)
		{
			if (linewidths[frame][y]!=0xff)
			{
				minx=linewidths[frame][y];
				miny=y;
				break;
			}
		}

		for (int y=0 ; y<256 ; y++)
		{
			if (linewidths[frame][y]!=0xff)
			{
				maxx=linewidths[frame][y];
				maxy=y;
			}
		}

		linewidthscomp[frame][0]=minx;
		linewidthscomp[frame][1]=miny;
		linewidthscomp[frame][2]=maxx;
		linewidthscomp[frame][3]=maxy;

		linevscomp[linevssize++]=miny;
		linevscomp[linevssize++]=maxy;
		for (int y=miny ; y<=maxy ; y++)
		{
			linevscomp[linevssize++]=linevs[frame][y];
		}
	}

	filew=new FileW("Data/Parts/StarWars/linewidths.dat");
	filew->Write(linewidths, 1, sizeof(linewidths));
	delete filew;

	filew=new FileW("Data/Parts/StarWars/linewidthscomp.dat");
	filew->Write(linewidthscomp, 1, sizeof(linewidthscomp));
	delete filew;

	filew=new FileW("Data/Parts/StarWars/linevs.dat");
	filew->Write(linevs, 1, sizeof(linevs));
	delete filew;
	
	filew=new FileW("Data/Parts/StarWars/linevscomp.dat");
	filew->Write(linevscomp, 1, linevssize);
	delete filew;

	filew=new FileW("Data/Parts/StarWars/letters.dat");
	
	int numletters=letters.size();

	unsigned char letterplanes[9][16][3][4];

	for (int i=0 ; i<numletters ; i++)
	{
		Letter& letter=letters[i];

		memset(letterplanes, 0, sizeof(letterplanes));

		for (int scale=0 ; scale<9 ; scale++)
		{
			int width=20-scale;

			float ustep=20.0f/(float)(width);

			for (int bpl=0 ; bpl<3 ; bpl++)
			{
				for (int y=0 ; y<16 ; y++)
				{
					float u=0.0f;
					for (int x=0 ; x<width ; x++)
					{
						int intu=(int)(u);

						unsigned char co=letter.data[y][intu];

						unsigned char bit=(co>>bpl) & 1;
					
						int shift=7-(x&7);

						letterplanes[scale][y][bpl][x/8]|=(bit<<shift);

						u+=ustep;
					}
				}
			}
		}

		filew->Write(letterplanes, 1, sizeof(letterplanes));
	}

	delete filew;


	filew=new FileW("Data/Parts/StarWars/letterschunky.dat");
	
	for (int i=0 ; i<numletters ; i++)
	{
		Letter& letter=letters[i];

		for (int y=0 ; y<32 ; y++)
		{
			for (int x=0 ; x<32 ; x++)
			{
				unsigned char co=letter.data[y][x];

				filew->Write(&co, 1, sizeof(co));
			}
		}
	}

	delete filew;


	int bittab[9][8] = {	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
							0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 
							0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 
							0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 
							0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x01, 
							0x00, 0x01, 0x01, 0x00, 0x01, 0x00, 0x01, 0x01, 
							0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x01, 0x01, 
							0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
							0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 };

	char coppercode[0x100000];

	memset(coppercode, 0, sizeof(coppercode));
	
	char tmp[256];

	int shadecount=0;

	for (int x1=0 ; x1<=87 ; x1++)
	{
		int shadeoff=(87-x1)*24/87+2;

		sprintf(tmp, "star_tmp%d:\r\n", x1);
		strcat(coppercode, tmp);

		int maskleft=x1+0x79;
		int maskright=0x132-maskleft;

		sprintf(tmp, "\tdc.l\t$008e2c%.2x, $00902c%.2x\r\n", maskleft, maskright);
		strcat(coppercode, tmp);
	
		int x2=320-x1;
		int scroll1=(x1 & 0x07)+8;
		int scroll2=16-scroll1;

		if (scroll1>scroll2)
		{
			int dscroll=scroll1-scroll2;
			int stepx=(160-x1)*45;	
			int xx=x1*8*49+stepx/2;
			int lastx=-100;
			int i=0;
			int scroll=scroll1;
			int lastscroll=16;
			shadecount=7;
		
			for (int scrolla=0 ; scrolla<16 ; scrolla++)
			{
				int x=xx/350;
				int bit=scrolla;
				if (scrolla>=8)
				{
					bit=8-bit;
				}

				if (scrolla==8)
					scroll--;

				if (bittab[(x1 & 7)][bit])
					scroll--;

				if (scroll!=lastscroll)
				{
					int dx=x-lastx;
					if (dx>=24)
					{
						int copx=0x31+((x/2) & 0x1fe);
						if (i==0)
						{
							copx=0x2b;
							x=0;
						}

						int mask=copx & 0x07;
	
						if (scroll<2 && lastscroll>=2 && mask==0x07)
						{
							copx+=2;
						}
						if (scroll<6 && lastscroll>=6 && mask==0x01)
						{
							copx+=2;
						}
						if (scroll<10 && lastscroll>=10 && mask==0x03)
						{
							copx+=2;
						}
						if (scroll<14 && lastscroll>=14 && mask==0x05)
						{
							copx+=2;
						}
					
						sprintf(tmp, "\tdc.l\t$00%xfffe, $010200%.2x\r\n", copx, scroll+(scroll<<4));
						strcat(coppercode, tmp);
						lastx=x;
					}
					else
					{
						if (dx>=12)
						{
							if (shadecount>0)
							{
								unsigned short col=shadetab[shadeoff][shadecount];

								col=(col<<8) | (col>>8);

								sprintf(tmp, "\tdc.l\t$018%.1x%.4x\r\n", shadecount*2, col);
								strcat(coppercode, tmp);
								shadecount--;
							}
							else
							{
								sprintf(tmp, "\tdc.l\t$01a00000\r\n");
								strcat(coppercode, tmp);
							}
							lastx+=8;
						}

						sprintf(tmp, "\tdc.l\t$010200%.2x\r\n", scroll+(scroll<<4));
						strcat(coppercode, tmp);
						lastx+=8;
					}
				}
		
				lastscroll=scroll;
				xx+=stepx;
				i++;
			}

			sprintf(tmp, "\tdc.l\t0\r\n");
			strcat(coppercode, tmp);
		}
		else
		{
			sprintf(tmp, "\tdc.l\t$002ffffe, $01020088, 0\r\n");
			strcat(coppercode, tmp);
		}
	}

	filew=new FileW("Data/Parts/StarWars/coppercode.asm");
	filew->Write(coppercode, 1, strlen(coppercode));
	delete filew;
}

void StarWars::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);

	LoadFont("Data/Parts/StarWars/font.png", 20, 16, 0, 0, 0, 0);

	Image image;

	image.Load("Data/Parts/StarWars/logo.png");

	for (int y=0 ; y<64 ; y++)
	{
		for (int x=0 ; x<320 ; x++)
		{
			unsigned int col=image.GetPixel(x, y);
			unsigned char co=(col & 0xff)>>5;
			
			logo[y][x]=co;
		}
	}
	
	int lastshade=-1;
	int shadecount=0;

	float au=700.0f;
	float tf=0.0f;

	float xs[] = { -200.0f, -200.0f };
	float ys[] = {  -300.0f, 300.0f };
	float zs[] = {   0.0f, 0.0f };

	float cy=0.0f;
	float cz=(880.0f+1930.0f)/2.0f;

	float dy=271.0f+115.0f;
	float dz=1930.0f-880.0f;
	float d=OxySqrt(dy*dy+dz*dz);

	for (int rot=0 ; rot<256 ; rot++)
	{
		float dxs[2];
		float dys[2];
		float dzs[2];

		float destxs[2][256];
		float destvs[2][256];
		
		memset(destxs, 0, sizeof(destxs));
		memset(destvs, 0, sizeof(destvs));

		for (int y=0 ; y<256 ; y++)
		{
			destxs[0][y]=-1.0f;
			destxs[1][y]=-1.0f;
		}

		float rx=(float)(rot)*2.0f*pi/256.0f;
		float sx=OxySin(rx);
		float cx=OxyCos(rx);

		for (int i=0 ; i<2 ; i++)
		{
			float x1=xs[i];
			float y1=ys[i];
			float z1=zs[i];

			float z2=y1*sx+z1*cx;
			float y2=y1*cx-z1*sx;

			y1=y2+cy;
			z1=z2*1.78f+cz;

			float z3=au/(z1);
			float x3=x1*z3+160.0f;
			float y3=y1*z3+100.0f;

			dxs[i]=x3;
			dys[i]=y3;
			dzs[i]=z1;
		}

		float x1=dxs[0];
		float y1=dys[0];
		float z1=1.0f/dzs[0];
		float v1=1.0f*z1;

		float x2=dxs[1];
		float y2=dys[1];
		float z2=1.0f/dzs[1];
		float v2=0.0f*z2;

		if (y2<y1)
		{
			Swap(x1, x2);
			Swap(y1, y2);
			Swap(z1, z2);
			Swap(v1, v2);
		}
	
		float dx=x2-x1;
		float dy=y2-y1;
		float dz=z2-z1;
		float dv=v2-v1;

		float xstep=dx/dy;
		float zstep=dz/dy;
		float vstep=dv/dy;

		float subpy=1.0f-(y1-int(y1));

		x1+=xstep*subpy;
		z1+=zstep*subpy;
		v1+=vstep*subpy;

		int inty1=(int)(y1);
		int inty2=(int)(y2);

		for (int y=inty1 ; y<inty2 ; y++)
		{
			if (y>=0 && y<256)
			{
				float v=v1/z1;

				linewidths[rot][y]=(unsigned char)(x1);
				linevs[rot][y]=(unsigned char)(v*11.0f*16.0f);
			}
			x1+=xstep;
			z1+=zstep;
			v1+=vstep;
		}
	}

	for (int shade=0 ; shade<32 ; shade++)
	{
		for (int i=0 ; i<8 ; i++)
		{
			unsigned int col=pal[i];

			int r=(col>>16) & 0x0ff;
			int g=(col>> 8) & 0x0ff;
			int b=(col    ) & 0x0ff;

			r=((r*(shade-3))/290);
			g=((g*(shade-3))/290);
			b=((b*(shade-3))/290);

			Clamp(r, 0, 15);
			Clamp(g, 0, 15);
			Clamp(b, 0, 15);

			unsigned short amigacol=(g<<12) | (b<<8) | (r);
			shadetab[shade][i]=amigacol;
		}
	}
}

void StarWars::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(GetColor(0x00));

	static int frame=0;

	char* text[] = {		"  a long long   ",
							"    time ago    ",
							"  in a galaxy   ",
							"    far away    ",
							" axis of oxyron ",
							"    proudly     ",
							"    presents    ",
							"    the best    ",
							"starwars scroll ",
							"      ever      ",
							"  see u later   ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                ",
							"                " };

	static bool dologo=false;
	if (input->WasKeyHit(KB_L))
		dologo=!dologo;

	int numletters=letters.size();

	for (int y=0 ; y<256 ; y++)
	{
		float x1=(float)(linewidths[frame & 0xff][y]);
		if (x1<128.0f)
		{
			float x2=319.0f-x1;
			float v=(float)(linevs[frame & 0xff][y]);

			float ustep=1.0f/(x2-x1);

			int intv=(int)(v);
		
			if (dologo)
			{
				intv-=56;
				Clamp(intv, 0, 63);
			}

			int shade=(int)((87-x1)*31/87);

			float u=ustep*(1.0f-(x1-(int)(x1)));
		
			for (int x=(int)(x1) ; x<(int)(x2) ; x++)
			{
				unsigned char co=0;
				if (x>=0 && x<320)
				{
					int intu=(int)(u*320.0f);

					Clamp(intu, 0, 319);

					if (dologo)
					{
						co=logo[intv][intu];
					}
					else
					{
						int chrx=(intu/20) % 16;
						int chry=(intv/16) % 32;

						unsigned char chr=text[chry][chrx]-97;
						
						if (chr>=0 && chr<numletters)
						{
							Letter& letter=letters[chr];

							co=letter.data[intv & 0x0f][intu % 20];
						}
					}
					unsigned int col=pal[co];

					int r=(col>>16) & 0x0ff;
					int g=(col>> 8) & 0x0ff;
					int b=(col    ) & 0x0ff;

					r=((r*shade)>>4);
					g=((g*shade)>>4);
					b=((b*shade)>>4);

					Clamp(r,0,255);
					Clamp(g,0,255);
					Clamp(b,0,255);

					col=(r<<16) | (g<<8) | (b);
					gfx->Plot(x, y, col);
				}
				u+=ustep;
			}
		}
	}

	frame++;

	Sleep(10);
}

void StarWars::BlitText( char* text, int posx, int posy )
{
	int len=strlen(text);

	for (int i=0 ; i<len ; i++)
	{
		posx+=BlitChar(text[i], posx, posy);		
	}
}

int StarWars::BlitChar( char chr, int posx, int posy )
{
	chr-=97;

	int numletters=letters.size();
	if (chr>=0 && chr<numletters)
	{
		Letter& letter=letters[chr];

		for (int y=0 ; y<letter.height ; y++)
		{
			for (int x=0 ; x<letter.width ; x++)
			{
				unsigned char co=letter.data[y][x]<<4;
				unsigned int col=(co)|(co<<8)|(co<<16);

				gfx->Plot(x+posx, y+posy, col);
			}
		}

		return letter.width;
	}
	return 8;
}

void StarWars::LoadFont( char* filename, int charwidth, int charheight, int marginleft, int marginright, int margintop, int marginbottom )
{
	Image image;

	image.Load(filename);

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
	
	int posx=0;
	int posy=0;
	Letter letter;

	for (int i=0 ; i<26 ; i++)
	{
		letter.Clear();

		letter.width=charwidth;
		letter.height=charheight;

		for (int y=0 ; y<charheight ; y++)
		{
			for (int x=0 ; x<charwidth ; x++)
			{
				int intu=x+posx;
				int intv=y+posy;
				
				unsigned int col=image.GetPixel(intu,intv);
				for (int i=0 ; i<palsize ; i++)
				{
					if (col==pal[i])
					{
						letter.data[y][x]=i;
						break;
					}
				}
			}
		}

		letters.push_back(letter);

		posx+=charwidth;
		if (posx>(width-charwidth))
		{
			posx=0;
			posy+=charheight;
		}
	}
}

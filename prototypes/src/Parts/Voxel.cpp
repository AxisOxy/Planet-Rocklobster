#include "include.h"

DEFINE_CLASS(Voxel,Effect);
		
Voxel::Voxel()
{
	skyr=6;
	skyg=10;
	skyb=14;
	fogr=7;
	fogg=11;
	fogb=15;
}

Voxel::~Voxel()
{
	for (int z=0 ; z<numzs ; z++)
	{
		for (int y=0 ; y<128 ; y++)
		{
			persptab[y][z]=persptab[y][z]*160;
		}
	}

	for (int x=0 ; x<80 ; x++)
	{
		unsigned char lastscale=0xff;
		for (int z=0 ; z<numzs ; z++)
		{
			unsigned char scale=scaletab[x][z];
			if (scale==lastscale)
				scaletab[x][z]=0xff;	
			else
				scaletab[x][z]=scale*2;	

			lastscale=scale;
		}
	}

	unsigned char offsets2[2][480][64];

	for (int x=0 ; x<480 ; x++)
	{
		int lastu=0;
		int lastv=0;
		for (int z=0 ; z<numzs ; z++)
		{
			int offset=offsets[x][z];
			int u=offset & 0xff;
			int v=offset>>8;

			offsets2[0][x][z]=(u-lastu) & 0xff;
			offsets2[1][x][z]=(v-lastv) & 0xff;

			lastu=u;
			lastv=v;
		}
	}

	BSwapShortArray((unsigned short*)(sintab), 1280);
	BSwapShortArray((unsigned short*)(persptab), 128*128);
	BSwapShortArray((unsigned short*)(offsets), 480*64);
	
	BSwapIntArray((unsigned int*)(offsetspacked), 480*4);
	BSwapIntArray((unsigned int*)(persptabpacked), 128*2);

	FileW* filew=new FileW("Data/Parts/Voxel/persptab.dat");
	filew->Write(persptab, 2, numzs*256);
	delete filew;

	filew=new FileW("Data/Parts/Voxel/offsets.dat");
	filew->Write(offsets2, 1, 480*numzs*2);
	delete filew;

	filew=new FileW("Data/Parts/Voxel/persptabpacked.dat");
	filew->Write(persptabpacked, 4, numzs*2);
	delete filew;

	filew=new FileW("Data/Parts/Voxel/offsetspacked.dat");
	filew->Write(offsetspacked, 4, 480*4);
	delete filew;
	
	filew=new FileW("Data/Parts/Voxel/scaletab.dat");
	filew->Write(scaletab, 1, 80*numzs);
	delete filew;
	
	filew=new FileW("Data/Parts/Voxel/sintab.dat");
	filew->Write(sintab, 1, 0x140);
	delete filew;

	unsigned char textureheights[0x20000];

	for (int i=0 ; i<0x10000 ; i++)
	{
		texture[i]*=2;

		unsigned char height=heightmap[i];
		unsigned char co=texture[i];
			
		textureheights[i*2  ]=height;
		textureheights[i*2+1]=co;
	}

	filew=new FileW("Data/Parts/Voxel/textureheights.dat");
	filew->Write(textureheights, 1, sizeof(textureheights));
	delete filew;

	filew=new FileW("Data/Parts/Voxel/texture.dat");
	filew->Write(texture, 1, sizeof(texture));
	delete filew;

	filew=new FileW("Data/Parts/Voxel/heightmap.dat");
	filew->Write(heightmap, 1, sizeof(heightmap));
	delete filew;

	BSwapShortArray((unsigned short*)(shadetab), 16*128);

	filew=new FileW("Data/Parts/Voxel/textureheights.dat");
	filew->Write(textureheights, 1, sizeof(textureheights));
	delete filew;

	filew=new FileW("Data/Parts/Voxel/shadetab.dat");
	filew->Write(shadetab, 1, sizeof(shadetab));
	delete filew;

	BSwapShortArray((unsigned short*)(skypal), 128);

	filew=new FileW("Data/Parts/Voxel/skypal.dat");
	filew->Write(skypal, 1, sizeof(skypal));
	delete filew;


	unsigned short	fadesin[512];

	for (int i=0 ; i<512 ; i++)
	{
		fadesin[i]=(short)(OxySin((float)(i)*2.0f*pi/512.0f)*172.5f+172.5f);
	}

	BSwapShortArray((unsigned short*)(fadesin), 512);

	filew=new FileW("Data/Parts/Voxel/fadesin.dat");
	filew->Write(fadesin, 1, sizeof(fadesin));
	delete filew;

	unsigned short sintab256[64];
	unsigned short sintab512[128];
	unsigned short sintab1024[256];
	unsigned short sintab2048[512];

	for (int i=0 ; i<64 ; i++)
		sintab256[i]=(short)(OxySin((float)(i)*2.0f*pi/256.0f)*16383.5f);

	for (int i=0 ; i<128 ; i++)
		sintab512[i]=(short)(OxySin((float)(i)*2.0f*pi/512.0f)*16383.5f);
	
	for (int i=0 ; i<256 ; i++)
		sintab1024[i]=(short)(OxySin((float)(i)*2.0f*pi/1024.0f)*16383.5f);
	
	for (int i=0 ; i<512 ; i++)
		sintab2048[i]=(short)(OxySin((float)(i)*2.0f*pi/2048.0f)*16383.5f);

	BSwapShortArray((unsigned short*)(sintab256), 64);
	BSwapShortArray((unsigned short*)(sintab512), 128);
	BSwapShortArray((unsigned short*)(sintab1024), 256);
	BSwapShortArray((unsigned short*)(sintab2048), 512);

	filew=new FileW("Data/Parts/Voxel/sintab256.dat");
	filew->Write(sintab256, 1, sizeof(sintab256));
	delete filew;

	filew=new FileW("Data/Parts/Voxel/sintab512.dat");
	filew->Write(sintab512, 1, sizeof(sintab512));
	delete filew;

	filew=new FileW("Data/Parts/Voxel/sintab1024.dat");
	filew->Write(sintab1024, 1, sizeof(sintab1024));
	delete filew;

	filew=new FileW("Data/Parts/Voxel/sintab2048.dat");
	filew->Write(sintab2048, 1, sizeof(sintab2048));
	delete filew;
}

void Voxel::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);
	
	std::set<unsigned short> usedcols;

	Image tmpimage;
	Image heights;
	
	tmpimage.Load("Data/Parts/Voxel/texture256.png");
	heights.Load("Data/Parts/Voxel/heights256.png");

	usedcols.clear();

	for (int y=0 ; y<256 ; y++)
	{
		for (int x=0 ; x<256 ; x++)
		{
			unsigned int col=heights.GetPixel(x, 255-y);
			unsigned char height=col & 0xff;

			col=tmpimage.GetPixel(x, 255-y) & 0x00f0f0f0;

			int r=(col>>16) & 0xff;
			int g=(col>> 8) & 0xff;
			int b=(col    ) & 0xff;

			r>>=4;
			g>>=4;
			b>>=4;

			col=(r<<8) | (g<<4) | (b);

			usedcols.insert(col);
		
			texture2[x+y*256]=col;

			heightmap[x+y*256]=height*45/255;
		}
	}

	int colcount=usedcols.size();
	if (colcount>128)
	{
		char msg[256];

		sprintf(msg, "Generated texture has too many colors: %i (instead of max. 128)", colcount);

		MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
	//	exit(0);
	}

	memset(pal, 0, sizeof(pal));
	memset(skypal, 0, sizeof(skypal));

	int numcols=0;

	std::set<unsigned short>::iterator iter=usedcols.begin();
	while(iter!=usedcols.end())
	{
		if (numcols<128)
			pal[numcols++]=(*iter);

		++iter;
	}

	for (int y=0 ; y<256 ; y++)
	{
		for (int x=0 ; x<256 ; x++)
		{
			unsigned short col=texture2[x+y*256];

			unsigned char co=0;
			for (int i=0 ; i<numcols ; i++)
			{
				if (col==pal[i])
				{
					co=i;
					break;
				}
			}		

			texture[x+y*256]=co;
		}
	}

	for (int i=0 ; i<1280 ; i++)
	{
		sintab[i]=(short)(OxySin((float)(i)*2.0f*pi/640.0f)*32767.5f);
	}

	memset(persptab, 0, sizeof(persptab));
	
	memset(persptabpacked, 0, sizeof(persptabpacked));
	memset(offsetspacked, 0, sizeof(offsetspacked));

	numzs=64;

	float floorheight1=-0.3f;
	float floorheight2= 1.0f;
	float au=250.0f;
	float minz=0.6f;
	float maxz=3.2f;
	float yscale=1.0f;
	float zyscale=-0.1f;
	float yoff=0.0f;

	float z=minz;
	float zstep=0.010f;
	float zacc=0.00085f;

	for (int iz=0 ; iz<numzs ; iz++)
	{
		float y1=floorheight1-(z-minz)*zyscale;
		float y3=floorheight2-(z-minz)*zyscale;
		float y2=(y1*au/z)*yscale+yoff;
		float y4=(y3*au/z)*yscale+yoff;
				
		for (int y=0 ; y<128 ; y++)
		{
			float fy=y4+(y2-y4)*(float)(y)/128.0f;

			Clamp(fy, 1.0f, 99.0f);

			persptab[y][iz]=(int)(fy);
		}

		z+=zstep;
		zstep+=zacc;

		persptabpacked[iz][0]=(int)(y2*65536.0f);
		persptabpacked[iz][1]=(int)(y4*65536.0f);
	}

	float uvscale=72.0f;

	float a=pi*0.5f-pi*0.25f;
	float cx=OxySin(a);
	float scale=1.0f/cx;
	for (int angle2=0 ; angle2<160 ; angle2++)
	{
		float cx=OxySin(a);
		a+=2.0f*pi/640.0f;

		float scale=cx;
	
		for (int angle=0 ; angle<480 ; angle++)
		{
			float b=(float)(angle)*2.0f*pi/480.0f;
			float sy=OxySin(b)*scale;
			float cy=OxyCos(b)*scale;

			float z=minz;
			float zstep=0.010f;
			float zacc=0.00085f;

			for (int iz=0 ; iz<numzs ; iz++)
			{
				int uoff=(int)(z*sy*uvscale) & 0xff;
				int voff=(int)(z*cy*uvscale) & 0xff;

				int off=uoff+voff*256;
				offsets[angle][iz]=off;

				z+=zstep;
				zstep+=zacc;
			}

			offsetspacked[angle][0]=(int)(minz*sy*uvscale*65536.0f);
			offsetspacked[angle][1]=(int)(minz*cy*uvscale*65536.0f);
			offsetspacked[angle][2]=(int)((maxz-minz)*sy*uvscale*65536.0f/(float)(numzs-1));
			offsetspacked[angle][3]=(int)((maxz-minz)*cy*uvscale*65536.0f/(float)(numzs-1));
		}
	}

	a=pi*0.5f-pi*0.25f;
	for (int angle2=0 ; angle2<80 ; angle2++)
	{
		float cx=OxySin(a);
		a+=2.0f*pi/480.0f;

		float scale2=1.0f/(cx*scale);
	
		for (int iz=0 ; iz<numzs ; iz++)
		{
			int offset=(int)((float)(iz)*scale2);
			scaletab[angle2][iz]=offset;
		}		
	}


	memset(shadetab, 0, sizeof(shadetab));

	for (int i=0 ; i<16 ; i++)
	{
		for (int j=0 ; j<128 ; j++)
		{
			unsigned short col=pal[j];

			int r1=(col>>4) & 0xf0;
			int g1=(col   ) & 0xf0;
			int b1=(col<<4) & 0xf0;
			int r2=fogr<<4;
			int g2=fogg<<4;
			int b2=fogb<<4;
			int r=r1+(r2-r1)*(i)/18;
			int g=g1+(g2-g1)*(i)/18;
			int b=b1+(b2-b1)*(i)/18;

			r>>=4;
			g>>=4;
			b>>=4;

			col=(r<<8) | (g<<4) | (b);
			
			shadetab[i][j]=col;
		}
	}
}

void Voxel::Update( float _rendertime )
{
	Effect::Update(_rendertime);
	
	gfx->Clear(0);
	
	unsigned int col=(skyr<<20) | (skyg<<12) | (skyb<<4);

	gfx->Box(0, 0, 319, 199, col, true);

		static int frame=0;

	static int ry=0;
	static int uoff=0;
	static int voff=0;
	static int camheight=0;
	
	int movespeed=8;

	Vector2 mousedelta;

	input->GetMouseDelta(&mousedelta.x, &mousedelta.y);

	ry=(ry+(int)(mousedelta.x));
	if (ry<0)
		ry+=640;
	if (ry>640)
		ry-=640;

	int umovex=sintab[ry+560]*movespeed;
	int vmovex=sintab[ry+80 ]*movespeed;
	int umovey=sintab[ry+80 ]*movespeed;
	int vmovey=sintab[ry+240]*movespeed;
	
	if (input->IsKeyDown(KB_UP))
	{
		uoff+=umovey;
		voff+=vmovey;
	}

	if (input->IsKeyDown(KB_DOWN))
	{
		uoff-=umovey;
		voff-=vmovey;
	}

	if (input->IsKeyDown(KB_LEFT))
	{
		uoff+=umovex;
		voff+=vmovex;
	}

	if (input->IsKeyDown(KB_RIGHT))
	{
		uoff-=umovex;
		voff-=vmovex;
	}

	int uvoffset=((uoff>>16) & 0xff)+((voff>>16) & 0xff)*256;

	int camu=uoff+umovey*7;
	int camv=voff+vmovey*7;

	int camuv=((camu>>16) & 0xff)+((camv>>16) & 0xff)*256;

	int tmpheight=heightmap[camuv & 0xffff];

	camheight=(camheight*3+tmpheight*1)>>2;

	int camoffset=64-camheight;
/*
	int r1=63;
	int g1=63;
	int b1=255;
	int r2=255*8/6;
	int g2=191*8/6;
	int b2=127*8/6;
*/	
	int r1=160;
	int g1=160;
	int b1=255;
	int r2=160;
	int g2=160;
	int b2=255;

	for (int i=0 ; i<128 ; i++)
	{
		int r4=r1+(r2-r1)*(i-28)/60;
		int g4=g1+(g2-g1)*(i-28)/60;
		int b4=b1+(b2-b1)*(i-28)/60;
		r4>>=4;
		g4>>=4;
		b4>>=4;
		Clamp(r4, 0, 15);
		Clamp(g4, 0, 15);
		Clamp(b4, 0, 15);
		skypal[i]=(r4<<8) | (g4<<4) | (b4);
	}
	
	int ry2=(ry+20)*6/8;

	for (int x=0 ; x<80 ; x++)
	{
		int miny=100;

		int angle=(x+ry2) % 480;
		
		for (int z=0 ; z<numzs ; z++)
		{
//			int offset=offsets[angle][scaletab[x][z]];
			int offset=offsets[angle][z];
			int uv=(uvoffset+offset) & 0xffff;
			
			int shadeoff=(z-48);

			Clamp(shadeoff, 0, 15);

			unsigned int col=shadetab[shadeoff][texture[uv]];

			int r=(col>>4) & 0xf0;
			int g=(col   ) & 0xf0;
			int b=(col<<4) & 0xf0;
		
			col=(r<<16) | (g<<8) | (b);

			unsigned char height=heightmap[uv];
			int y=persptab[height+camoffset][z];
			if (y<miny)
			{
				for (int y2=y ; y2<miny ; y2++)
				{
					for (int yy=0 ; yy<2 ; yy++)
					{
						for (int xx=0 ; xx<4 ; xx++)
						{
							gfx->Plot(x*4+xx, y2*2+yy, col);
						}
					}
				}

				miny=y;
			}
		}
	}

	Sleep(45);
}

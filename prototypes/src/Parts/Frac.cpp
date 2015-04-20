#include "include.h"

/*
	TODO:	- 
*/

DEFINE_CLASS(Frac,Effect);
		
Frac::Frac()
{
	numsubframes=0;
}

Frac::~Frac()
{
	unsigned char pal2[16][2];

	for (int i=0 ; i<16 ; i++)
	{
		unsigned int col=pal[i];
		int r=(col>>20) & 0x0f;
		int g=(col>>12) & 0x0f;
		int b=(col>> 4) & 0x0f;

		unsigned char lo=(g<<4) | (b);
		unsigned char hi=r;

		pal2[i][0]=hi;
		pal2[i][1]=lo;
	}

	FileW* filew=new FileW("Data/Parts/Frac/pal.dat");
	filew->Write(pal2, 1, 32);
	delete filew;
	
	
	unsigned char planedata1[224*2][4][28];
	unsigned char planedata2[224][4][20];

	//original pic

	PicData& picdata=picdatas[0];

	memset(planedata1, 0, sizeof(planedata1));
		
	for (int y=0 ; y<224 ; y++)
	{
		for (int x=0 ; x<224 ; x++)
		{
			unsigned char palid=picdata.basepic[y][x];

			for (int bpl=0 ; bpl<4 ; bpl++)
			{
				unsigned char bit=(palid>>bpl) & 1;
				
				int shift=7-(x&7);

				planedata1[y][bpl][x/8]|=(bit<<shift);
			}
		}
	}
	
	filew=new FileW("Data/Parts/Frac/basepic.dat");
	filew->Write(planedata1, 1, 224*224/2);
	delete filew;


	int numlines=numsubframes*2;
	int filesize1=numlines*28*4;

	int numcolumns=(numsubframes*2+15)/16*16;
	int filesize2=numcolumns*224*4/8;
	
	int filesize3=numlines*28*8;
	
	char filename[256];

	for (int i=0 ; i<numpics ; i++)
	{
		PicData& picdata=picdatas[i];

		memset(planedata1, 0, sizeof(planedata1));
		memset(planedata2, 0, sizeof(planedata2));

		sprintf(filename, "Data/Parts/Frac/pic_%d.dat", i);

		filew=new FileW(filename);
			
		for (int j=0 ; j<2 ; j++)
		{
			for (int k=0 ; k<numsubframes ; k++)
			{
				int y=k*2+j;

				for (int x=0 ; x<224 ; x++)
				{
					unsigned char palid=picdata.rowdata[k+1][j+2][x];

					for (int bpl=0 ; bpl<4 ; bpl++)
					{
						unsigned char bit=(palid>>bpl) & 1;
						
						int shift=7-(x&7);

						planedata1[y][bpl][x/8]|=(bit<<shift);
					}
				}
			}
		}
			
		for (int j=0 ; j<2 ; j++)
		{
			for (int k=0 ; k<numsubframes ; k++)
			{
				int x=k*2+j;

				for (int y=0 ; y<224 ; y++)
				{
					unsigned char palid=picdata.rowdata[k+1][j+0][y];

					for (int bpl=0 ; bpl<4 ; bpl++)
					{
						unsigned char bit=(palid>>bpl) & 1;
						
				//		int shift=7-(x&7);
				//		planedata2[y][bpl][x/8]|=(bit<<shift);

						int shift=7-(y&7);
						planedata1[x+numlines][bpl][y/8]|=(bit<<shift);
					}
				}
			}
		}

		filew->Write(planedata1, 1, filesize3);
	//	filew->Write(planedata1, 1, filesize1);
	//	filew->Write(planedata2, 1, filesize2);
		delete filew;
	}

	BSwapShortArray((unsigned short*)(zoomxs), 128);
	BSwapShortArray((unsigned short*)(zoomus), 128);

	filew=new FileW("Data/Parts/Frac/zoomxs.dat");
	filew->Write(zoomxs, 1, sizeof(zoomxs));
	delete filew;

	filew=new FileW("Data/Parts/Frac/zoomus.dat");
	filew->Write(zoomus, 1, sizeof(zoomus));
	delete filew;
}

void Frac::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);
	
	pal[ 0]=0x000000;
	pal[ 1]=0x2080c0;
	pal[ 2]=0x1090a0;
	pal[ 3]=0x00a090;
	pal[ 4]=0x30a060;
	pal[ 5]=0x70b040;
	pal[ 6]=0xa0c020;
	pal[ 7]=0xe0c000;
	pal[ 8]=0xc09030;
	pal[ 9]=0xa06060;
	pal[10]=0x903090;
	pal[11]=0x7000d0;
	pal[12]=0x6020d0;
	pal[13]=0x5050d0;
	pal[14]=0x4060d0;
	pal[15]=0x3070e0;

	int width=512;
	int height=512;
	int maxiter=256;

	numpics=16;

	int lerpsize=width*(1<<(numpics-1));

	double* lerpxs=new double[lerpsize];
	double* lerpys=new double[lerpsize];

	double scale=1.0;
	//double xoff=-0.5723;
	//double yoff=0.64765;
	double xoff=-0.58065;
	double yoff=0.65235;
	double minx=-1.25*scale+xoff;
	double maxx= 1.25*scale+xoff;
	double miny=-1.60*scale+yoff;
	double maxy= 1.60*scale+yoff;
	
	double fx,fy,fxstep,fystep;

	fxstep=(maxx-minx)/(double)(lerpsize);
	fystep=(maxy-miny)/(double)(lerpsize);
	
	fy=miny;
	fx=minx;
	for (int i=0 ; i<lerpsize ; i++)
	{
		lerpxs[i]=fx;
		lerpys[i]=fy;
		
		fx+=fxstep;
		fy+=fystep;
	}

	int center=lerpsize/2;

	for (int i=0 ; i<numpics ; i++)
	{
		int step=(1<<(numpics-(i+1)));
		int start=center-step*width/2;

		int iy=start;
		for(int y=0 ; y<height ; y++)
		{
			fy=lerpys[iy];

			int ix=start;
			for(int x=0 ; x<width ; x++)
			{
				fx=lerpxs[ix];

				int iter=IteratePixel(fx, fy, maxiter);
				if (maxiter==iter)
				{
					iter=0;
				}
				else
				{
					if (iter>=128)
						iter>>=1;
					if (iter>=32)
						iter>>=1;

					iter=(iter % 15)+1;
				}

				pics[i][y][x]=iter;								

				ix+=step;
			}
			iy+=step;
		}
	}

	delete [] lerpxs;
	delete [] lerpys;

	picdatas.resize(numpics);
}

void Frac::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(0);

	static int zoomframe=0;
	static int picid=0;

	int zoomtab[]	= {	128, 
						 64, 192, 
						 32, 160, 96, 224,
						 16, 144, 80, 208, 48, 176, 112, 240,
						  8, 136, 72, 200, 40, 168, 104, 232, 24, 152, 88, 216, 56, 184, 120, 248,
						  4, 132, 68, 196, 36, 164, 100, 228, 20, 148, 84, 212, 52, 180, 116, 244,
						 12, 140, 76, 204, 44, 172, 108, 236, 28, 156, 92, 220, 60, 188, 124, 252,
						  2, 130, 66, 194, 34, 162,  98, 226, 18, 146, 82, 210, 50, 178, 114, 242,
						 10, 138, 74, 202, 42, 170, 106, 234, 26, 154, 90, 218, 58, 186, 122, 250,
						  6, 134, 70, 198, 38, 166, 102, 230, 22, 150, 86, 214, 54, 182, 118, 246,
						 14, 142, 78, 206, 46, 174, 110, 238, 30, 158, 94, 222, 62, 190, 126, 254 };
	
	int rows[256];
	int rowframes[128][256];

	for (int i=0 ; i<256 ; i++)
	{
		rows[i]=i;
	}

	numsubframes=0;

	for (int frame=0 ; frame<127 ; frame++)
	{
		int zoomu=zoomtab[frame]+1;

		int zoomx=-1;
		for (int x=0 ; x<256 ; x++)
		{
			if (rows[x]==zoomu)
			{
				zoomx=x;
				break;
			}
		}

		if (zoomx>=144 && zoomu>=88)
		{
			zoomxs[numsubframes]=zoomx;
			zoomus[numsubframes]=zoomu;

			memcpy(rowframes[numsubframes], rows, 256*sizeof(int)); 

			numsubframes++;
		}

		for (int x=zoomx-1 ; x>0 ; x--)
		{
			rows[x+1]=rows[x];
		}		
	}

	if (picid<numpics)
	{
		PicData& picdata=picdatas[picid];

		if (zoomframe==0)
		{
			if (picid==0)
			{
				memset(buffer, 0, sizeof(buffer));
				memset(us, 0, sizeof(us));
				memset(vs, 0, sizeof(vs));
				memset(frames, 0, sizeof(frames));

				for (int y=0 ; y<224 ; y++)
				{
					for (int x=0 ; x<224 ; x++)
					{
						int xoff=x*2+32;
						int yoff=y*2+32;
						if (x>=112)
							xoff+=2;
						if (y>=112)
							yoff+=2;

						unsigned char co=pics[picid][yoff][xoff];

						buffer[y+144][x+144]=co;
						us[y+144][x+144]=xoff;
						vs[y+144][x+144]=yoff;
						frames[y+144][x+144]=picid;
						picdata.basepic[y][x]=co;
					}
				}
			}
		}
		else
		{
			int subframe=numsubframes-(zoomframe);

			int zoomx1=zoomxs[subframe];
			int zoomx2=511-zoomx1;
			int zoomu1=zoomus[subframe];
			int zoomu2=512-zoomu1;
	
			Blit(     1,      1,      0,      0,     zoomx1,     zoomx1, false, false);
			Blit(zoomx1,      1, zoomx1,      0, 256-zoomx1,     zoomx1, false, false);
			Blit(     1, zoomx1,      0, zoomx1,     zoomx1, 256-zoomx1, false, false);

			Blit( zoomx2,      1, zoomx2+1,      0,     zoomx1,     zoomx1,  true, false);
			Blit(    256,      1,      256,      0, 256-zoomx1,     zoomx1,  true, false);
			Blit( zoomx2, zoomx1, zoomx2+1, zoomx1,     zoomx1, 256-zoomx1,  true, false);

			Blit(      1, zoomx2,      0, zoomx2+1,     zoomx1,     zoomx1, false, true);
			Blit(      1,    256,      0,      256,     zoomx1, 256-zoomx1, false, true);
			Blit( zoomx1, zoomx2, zoomx1, zoomx2+1, 256-zoomx1,     zoomx1, false, true);

			Blit( zoomx2, zoomx2, zoomx2+1, zoomx2+1,     zoomx1,     zoomx1, true, true);
			Blit( zoomx2,    256, zoomx2+1,      256,     zoomx1, 256-zoomx1, true, true);
			Blit(    256, zoomx2,      256, zoomx2+1, 256-zoomx1,     zoomx1, true, true);

			int v;

			for (int y=144 ; y<368 ; y++)
			{
				if (y>=256)
					v=512-rowframes[subframe][511-y];
				else
					v=rowframes[subframe][y];

				unsigned char co1=pics[picid][v][zoomu1];
				unsigned char co2=pics[picid][v][zoomu2];
		
				if (us[144][zoomx1]==223)
					int huhu=1;

				buffer[y][zoomx1]=co1;
				buffer[y][zoomx2]=co2;
				us[y][zoomx1]=zoomu1;
				us[y][zoomx2]=zoomu2;
				vs[y][zoomx1]=v;
				vs[y][zoomx2]=v;
				frames[y][zoomx1]=picid;
				frames[y][zoomx2]=picid;

				picdata.rowdata[zoomframe][0][y-144]=co1;
				picdata.rowdata[zoomframe][1][y-144]=co2;
			}

			for (int x=144 ; x<368 ; x++)
			{
				if (x>=256)
					v=512-rowframes[subframe][511-x];
				else
					v=rowframes[subframe][x];

				unsigned char co1=pics[picid][zoomu1][v];
				unsigned char co2=pics[picid][zoomu2][v];

				buffer[zoomx1][x]=co1;
				buffer[zoomx2][x]=co2;
				us[zoomx1][x]=v;
				us[zoomx2][x]=v;
				vs[zoomx1][x]=zoomu1;
				vs[zoomx2][x]=zoomu2;
				frames[zoomx1][x]=picid;
				frames[zoomx2][x]=picid;

				picdata.rowdata[zoomframe][2][x-144]=co1;
				picdata.rowdata[zoomframe][3][x-144]=co2;
			}
		}

		for (int y=144 ; y<368 ; y++)
		{
			for (int x=144 ; x<368 ; x++)
			{
				unsigned char co=buffer[y][x];
				unsigned int col=pal[co];

				gfx->Plot(x-96, y-128, col);
			}
		}
	}

	zoomframe++;
	if (zoomframe==(numsubframes+1))
	{
		zoomframe=0;
		picid++;
	}

	Sleep(5);
}

void Frac::Blit( int srcx, int srcy, int dstx, int dsty, int xsize, int ysize, bool backwardx, bool backwardy )
{
	int xstart=0;
	int ystart=0;
	int xend=xsize;
	int yend=ysize;
	int xstep=1;
	int ystep=1;
	
	if (backwardx)
	{
		xstart=xsize-1;
		xend=-1;
		xstep=-1;
	}
	
	if (backwardy)
	{
		ystart=ysize-1;
		yend=-1;
		ystep=-1;
	}	

	for (int y=ystart ; y!=yend ; y+=ystep)
	{
		for (int x=xstart ; x!=xend ; x+=xstep)
		{
			int x1=srcx+x;
			int y1=srcy+y;
			int x2=dstx+x;
			int y2=dsty+y;

			buffer[y2][x2]=buffer[y1][x1];
			us[y2][x2]=us[y1][x1];
			vs[y2][x2]=vs[y1][x1];
			frames[y2][x2]=frames[y1][x1];
		}
	}
}

int Frac::IteratePixel( double x, double y, int maxiter )
{
	int iter=0;

	double i=0.0;
	double r=0.0;

	double i2,r2;

	while(true)
	{
		i2=i*i-r*r+x;
		r2=2*i*r+y;
		i=i2;
		r=r2;
		iter++;

		if ((i*i+r*r)>4.0)
		{
			break;
		}

		if (iter>=maxiter)
		{
			break;
		}
	}
	return iter;
}

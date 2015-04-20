#include "include.h"

/*
	TODO:	- 
*/

DEFINE_CLASS(City,FillerBase);
		
City::City()
{

}

City::~City()
{	
	FileW* filew=new FileW("Data/Parts/City/texture.dat");
	filew->Write(texture, 1, sizeof(texture));
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
	
	filew=new FileW("Data/Parts/City/pal.dat");
	filew->Write(amipal, 1, sizeof(amipal));
	delete filew;

	int numbodies=bodies.size();

	float minx= 10000;
	float maxx=-10000;
	float miny= 10000;
	float maxy=-10000;
	float minz= 10000;
	float maxz=-10000;

	for (int i=0 ; i<numbodies ; i++)
	{
		Body& body=bodies[i];

		Vertices& vertices=body.vertices;

		int numvertices=vertices.size();
		for (int j=0 ; j<numvertices ; j++)
		{
			Vector3& p1=vertices[j];

			minx=Min(minx, p1.x);
			maxx=Max(maxx, p1.x);
			miny=Min(miny, p1.y);
			maxy=Max(maxy, p1.y);
			minz=Min(minz, p1.z);
			maxz=Max(maxz, p1.z);
		}
	}

	float dstminx=-350.0f;
	float dstmaxx= 350.0f;
	float dstminy=-120.0f;
	float dstmaxy= 120.0f;
	float dstminz=-350.0f;
	float dstmaxz= 350.0f;
	
	float dx1=maxx-minx;
	float dy1=maxy-miny;
	float dz1=maxz-minz;
	float dx2=dstmaxx-dstminx;
	float dy2=dstmaxy-dstminy;
	float dz2=dstmaxz-dstminz;

	float xscale=dx2/dx1;
	float yscale=dy2/dy1;
	float zscale=dz2/dz1;

	float xbias=dstminx/xscale-minx;
	float ybias=dstminy/yscale-miny;
	float zbias=dstminz/zscale-minz;

	short numxzs=0;
	short numys=0;
	
	short xs[256];
	short zs[256];
	short ys[512];

	int indices[]= { 0, 1, 5, 4 };

	for (int i=0 ; i<numbodies ; i++)
	{
		Body& body=bodies[i];

		for (int j=0 ; j<4 ; j++)
		{
			Vector3& p1=body.vertices[indices[j]  ];
			Vector3& p2=body.vertices[indices[j]+2];

			float x=(p1.x+xbias)*xscale;
			float z=(p1.z+zbias)*zscale;
			float y1=(p1.y+ybias)*yscale;
			float y2=(p2.y+ybias)*yscale;
			
			xs[numxzs]=(short)(x);
			zs[numxzs]=(short)(z);
			numxzs++;	
			
			ys[numys++]=(short)(-y2);
			ys[numys++]=(short)(-y1);
		}
	}

	std::set<short> usedxs;
	std::set<short> usedzs;

	for (int i=0 ; i<numxzs ; i++)
	{
		usedxs.insert((abs)(xs[i]));
		usedzs.insert((abs)(zs[i]));
	}

	short numxcos=0;
	short numzcos=0;

	short xcos[256];
	short zcos[256];

	std::set<short>::iterator iterx=usedxs.begin();
	while(iterx!=usedxs.end())
	{
		xcos[numxcos++]=(*iterx)*4;
		++iterx;
	}
	
	std::set<short>::iterator iterz=usedzs.begin();
	while(iterz!=usedzs.end())
	{
		zcos[numzcos++]=(*iterz)*4;
		++iterz;
	}

	short numvertices=0;

	short vertices[256][4];

	for (int i=0 ; i<numbodies ; i++)
	{
		for (int j=0 ; j<4 ; j++)
		{
			int j2=(j+1) & 3;

			int xzoff1=i*4+j;
		
			short x1=xs[xzoff1];
			short z1=zs[xzoff1];
			std::set<short>::iterator iterx1=usedxs.find(abs(x1));
			std::set<short>::iterator iterz1=usedzs.find(abs(z1));

			short xoff1=std::distance(usedxs.begin(), iterx1)*2;
			short zoff1=std::distance(usedzs.begin(), iterz1)*2;

			if (x1<0)
				xoff1++;
			if (z1<0)
				zoff1++;

			int yoff=xzoff1*2;
			short y1=ys[yoff];
			short y2=ys[yoff+1];
			
			vertices[numvertices][0]=xoff1*4;
			vertices[numvertices][1]=zoff1*4;
			vertices[numvertices][2]=y1*4;
			vertices[numvertices][3]=y2*4;
			numvertices++;
		}
	}

	short numindices=0;

	short indexlist[256][4][2];

	short vertexstride=8;

	for (int i=0 ; i<numbodies ; i++)
	{
		for (int j=0 ; j<4 ; j++)
		{
			int j2=(j+1) & 3;

			int off1=i*4+j;
			int off2=i*4+j2;

			indexlist[numindices][j][0]=off1*vertexstride;
			indexlist[numindices][j][1]=off2*vertexstride;
		}
		numindices++;
	}

	BSwapShortArray((unsigned short*)(xcos), numxcos);
	BSwapShortArray((unsigned short*)(zcos), numzcos);
	BSwapShortArray((unsigned short*)(vertices), numvertices*4);
	BSwapShortArray((unsigned short*)(indexlist), numindices*8);
	
	short eov=-1;
	short eoi=0x1234;

	eov=BSwapShort(eov);
	eoi=BSwapShort(eoi);

	filew=new FileW("Data/Parts/City/xcoords.dat");
	filew->Write(xcos, 2, numxcos);
	delete filew;

	filew=new FileW("Data/Parts/City/zcoords.dat");
	filew->Write(zcos, 2, numzcos);
	delete filew;

	filew=new FileW("Data/Parts/City/vertices.dat");
	filew->Write(vertices, 2, numvertices*4);
	filew->Write(&eov, 1, sizeof(eov));
	delete filew;

	filew=new FileW("Data/Parts/City/indices.dat");
	filew->Write(indexlist, 2, numindices*8);
	filew->Write(&eoi, 1, sizeof(eoi));
	delete filew;
}

void City::Init( Gfx *_gfx, Input *_input )
{	
	FillerBase::Init(_gfx,_input);
	
	Image image;

	image.Load("Data/Parts/City/city06.png");

	int width=image.GetWidth();
	int height=image.GetHeight();
	
	if (width!=128 || height!=128)
	{
		char msg[256];

		sprintf(msg, "Envmap has wrong size: %ix%i (instead of 128x128)", width, height);

		MessageBox(0, msg, "Error", MB_ICONERROR|MB_DEFAULT_DESKTOP_ONLY);
		exit(0);
	}

	int palsize=1;
	memset(pal,0,sizeof(pal));
	memset(texture, 0, sizeof(texture));

	for (int y=0 ; y<128 ; y++)
	{
		for (int x=0 ; x<128 ; x++)
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

					sprintf(msg, "Texture has too many colors (>15)", palsize+1);

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

	for (int y=0 ; y<127 ; y++)
	{
		for (int x=0 ; x<128 ; x++)
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

			texture[0x7f-x][0x7f-y]=co;
		}
	}

	InitCity();
}

void City::Update( float _rendertime )
{
	FillerBase::Update(_rendertime);

	gfx->Clear(0);

	gfx->Box(0,   0, 319,  99, 0x303040, true);
	gfx->Box(0, 100, 319, 199, 0x403040, true);

	static int frame=0;

	static float ry=0.0f*pi;
	
	float rx=90.0f*DegtoRad;

	ry+=1.0f*pi/192.0f;

	float zoff=OxySin(ry)*100.0f+450.0f;

	Vector3 camerapos(0, -55, -zoff);

	int numbodies=bodies.size();

	sortvalues.resize(numbodies);
	
	for (int i=0 ; i<numbodies ; i++)
	{
		CalcBodyZ(bodies[i], rx, ry, camerapos);

		sortvalues[i]=SortValue(i, bodies[i].z);
	}

	for (int i=0 ; i<numbodies ; i++)
	{
		SortValue& sort1=sortvalues[i];
		for (int j=0 ; j<i ; j++)
		{
			SortValue& sort2=sortvalues[j];

			if (sort1.z>sort2.z)
			{
				Swap(sort1, sort2);
			}
		}
	}

	for (int i=0 ; i<numbodies ; i++)
	{
		int bodyid=sortvalues[i].bodyid;

		ShowBody(bodies[bodyid], rx, ry, camerapos, i);
	}

	frame++;

	Sleep(15);
}

void City::InitCity( void )
{
	bodies.clear();	

	float size1=35.0f;
	float size2=70.0f;
	float offset=140.0f;

//	for (int i=0 ; i<20 ; i++)
	for (int i=0 ; i<15 ; i++)
	{
		float x=randomf(-200.0f, 200.0f);
		float z=randomf(-200.0f, 200.0f);
		float xsize=randomf(15.0f, 30.0f);
		float zsize=randomf(15.0f, 30.0f);
		float ysize=randomf(40.0f, 80.0f);
		float rot=randomf(0.0f, 90.0f);
		
		AddCube(Vector3(x, 0.0f, z), Vector3(xsize, ysize, zsize), rot);
	}
}

void City::CalcBodyZ( Body& body, float rx, float ry, Vector3& camerapos )
{
	float sx=OxySin(rx);
	float cx=OxyCos(rx);
	float sy=OxySin(ry);
	float cy=OxyCos(ry);
	
	float	x1,x2,
			y1,
			z1,z2,z3;

	x1=body.center.x;
	y1=body.center.y;
	z1=body.center.z;

	x2=x1*sy+z1*cy;
	z2=z1*sy-x1*cy;
	
	z3=z2*sx-y1*cx;
	
	z3-=camerapos.z;

	body.z=z3;
}

void City::AddCube( const Vector3& pos, const Vector3& size, float ry )
{
	int		numverts=8;
	float	vecx[]={ -1.0f,  1.0f,  1.0f, -1.0f, -1.0f,  1.0f,  1.0f, -1.0f };
	float	vecz[]={ -1.0f, -1.0f, -1.0f, -1.0f,  1.0f,  1.0f,  1.0f,  1.0f };
	float	vecy[]={ -1.0f, -1.0f,  1.0f,  1.0f, -1.0f, -1.0f,  1.0f,  1.0f };
					
	int		numpolys=4;
	int		polys[]={	0, 3, 2, 1,
						1, 2, 6, 5,
						5, 6, 7, 4,
						4, 7, 3, 0 };
						
	float sy=OxySin(ry);
	float cy=OxyCos(ry);

	Body body;

	for (int i=0 ; i<numverts ; i++)
	{
		float x1=vecx[i]*size.x;	
		float y1=vecy[i]*size.y;	
		float z1=vecz[i]*size.z;	

		float x2=x1*sy+z1*cy;
		float z2=x1*cy-z1*sy;

		body.AddVertex(x2+pos.x, y1+pos.y, z2+pos.z);
	}

	for (int i=0 ; i<numpolys ; i++)
	{
		body.AddPoly(polys[i*4+2], polys[i*4+1], polys[i*4+0], polys[i*4+3]);
	}

	body.Init();

	bodies.push_back(body);
}

void City::ShowBody( Body& body, float rx, float ry, Vector3& camerapos, int sortid )
{
	float destx[256];
	float desty[256];
	float destz[256];
	bool visible[256];

	memset(visible, 0, sizeof(visible));

	float au=300.0f;
		
	float sx=OxySin(rx);
	float cx=OxyCos(rx);
	float sy=OxySin(ry);
	float cy=OxyCos(ry);

	float	x1,x2,x3,x4,
			y1,y2,y3,y4,
			z1,z2,z3,z4;

	Vertices& vertices=body.vertices;

	int numvertices=vertices.size();

	for (int i=0 ; i<numvertices ; i++)
	{
		Vector3& vertex=vertices[i];

		x1=vertex.x;
		y1=vertex.y;
		z1=vertex.z;

		x2=x1*sy+z1*cy;
		z2=z1*sy-x1*cy;
		
		y2=y1*sx+z2*cx;
		z3=z2*sx-y1*cx;
		
		x2-=camerapos.x;
		y2-=camerapos.y;
		z3-=camerapos.z;

		z4=au/z3;
		x3=x2*z4+160.0f;
		y3=y2*z4+100.0f;

		destx[i]=x3*0.5f;
		desty[i]=y3*0.5f;
		destz[i]=z3;
	}

	int o1,o2,o3,o4;
	float cross;

	Polys& polys=body.polys;
	int numpolys=polys.size();

	for (int i=0 ; i<numpolys ; i++)
	{
		Poly& poly=polys[i];

		o1=poly.cv1;
		o2=poly.cv2;
		o3=poly.cv3;
		o4=poly.cv4;

		x1=destx[o1];
		y1=desty[o1];
		x2=destx[o2];
		y2=desty[o2];
		x3=destx[o3];
		y3=desty[o3];
		x4=destx[o4];
		y4=desty[o4];

		cross=((x2-x1)*(y3-y1)) - ((y2-y1)*(x3-x1));
		visible[i]=false;
		if (cross<0)
		{
			int minx=(int)(Min(x1, x2));
			int maxx=(int)(Max(x1, x2));

			float baseu=(i & 1)*64.0f;

			DoLine(x3, y3, baseu+0.0f, x4, y4, baseu+63.0f);
			DoLine(x1, y1, baseu+0.0f, x2, y2, baseu+63.0f);

			FillPoly(minx, maxx);
		}
	}
}

void City::DoLine( float x1, float y1, float u1, float x2, float y2, float u2 )
{
	int off=0;
	if (x2<x1)
	{
		Swap(x1, x2);
		Swap(y1, y2);
		Swap(u1, u2);
		off=1;
	}

	float dx=x2-x1;
	float dy=y2-y1;
	float du=u2-u1;
	float ystep=dy/dx;
	float ustep=du/dx;

	int ix1=(int)(x1);
	int ix2=(int)(x2);
	if (ix1==ix2)
		return;

	for (int x=ix1 ; x<ix2 ; x++)
	{
		if (x>=0 && x<160)
		{
			linebuf[x][off]=y1;
			linebuf[x][2]=u1;
		}

		y1+=ystep;
		u1+=ustep;
	}
}

void City::FillPoly( int minx, int maxx )
{
	for (int x=minx ; x<maxx ; x++)
	{
		if (x>=0 && x<160)
		{
			float y1=linebuf[x][1];
			float y2=linebuf[x][0];
			int u=(int)(linebuf[x][2]) & 0x7f;
			
			float v1=0.0f;
			float v2=126.0f;
			
			float dy=y2-y1;
			float dv=v2-v1;
			float vstep=dv/dy;

			for (int y=(int)(y1) ; y<(int)(y2) ; y++)
			{
				if (y<100)
				{
					int v=(int)(v1) & 0x7f;

					unsigned int col=pal[texture[0x7f-u][0x7f-v]];

					gfx->Plot(x*2  , y*2  , col);
					gfx->Plot(x*2+1, y*2  , 0);
					gfx->Plot(x*2  , y*2+1, 0);
					gfx->Plot(x*2+1, y*2+1, col);
				}
				v1+=vstep;
			}
		}
	}
}

#include "include.h"

/*
	TODO:	- 
*/

DEFINE_CLASS(Morph,Effect);
		
Morph::Morph()
{
	
}

Morph::~Morph()
{
	WriteMesh("Data/Parts/Morph/mesh1.dat", points1);
	WriteMesh("Data/Parts/Morph/mesh2.dat", points2);
	WriteMesh("Data/Parts/Morph/mesh3.dat", points3);
}

void Morph::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);

	LoadMesh("Data/Parts/Morph/lobster.dat", points1);	
	LoadMesh("Data/Parts/Morph/donut6lines.dat", points2);
	
	int guardband=10;

	int x1= 60+guardband;
	int y1=  0+guardband;
	int x2=260-guardband;
	int y2=199-guardband;

	AddLine(x1, y1, x2, y1, points3);
	AddLine(x2, y1, x2, y2, points3);
	AddLine(x2, y2, x1, y2, points3);
	AddLine(x1, y2, x1, y1, points3);

	int numpoints1=points1.size();
	int numpoints2=points2.size();
	int numpoints3=points3.size();
	int numpoints=Max(Max(numpoints1, numpoints2), numpoints3);

	ExtendArray(points1, numpoints);
	ExtendArray(points2, numpoints);
	ExtendArray(points3, numpoints);

	ConvPoints(points1, points2);
	ConvPoints(points2, points3);
}

void Morph::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(0);

	static int frame=0;

	int morphframe=frame & 0x7f;
	int picid=(frame>>7) & 1;
	
	Clamp(morphframe, 32, 96); 
	
	morphframe-=32;

	if (picid)
		Display(points2, points3, morphframe);
	else
		Display(points1, points2, morphframe);

	frame++;

	Sleep(15);
}

void Morph::Randomize( Points& points )
{
	int numpoints=points.size();

	for (int i=0 ; i<0x100000 ; i++)
	{
		int id1=randomi(numpoints);
		int id2=randomi(numpoints);

		Swap(points[id1], points[id2]);
	}
}

void Morph::ExtendArray( Points& points, int newsize )
{
	int oldsize=points.size();
	if (newsize>oldsize)
	{
		points.resize(newsize);

		for (int i=0 ; i<newsize ; i++)
		{
			points[i]=points[i % oldsize];
		}
	}

	Randomize(points);
}

void Morph::ConvPoints( Points& points1, Points& points2 )
{
	int numpoints=points1.size();

	int maxdelta=96;

	bool found;
	do
	{
		found=false;

		for (int i=0 ; i<numpoints ; i++)
		{
			Point& point1=points1[i];
			Point& point2=points2[i];

			int dx=abs(point2.x-point1.x);
			int dy=abs(point2.y-point1.y);

			if (dx>=maxdelta || dy>=maxdelta)
			{
				if (i==numpoints-1)
					int huhu=1;

				while(true)
				{
					int id=randomi(0, numpoints);

					Point& point3=points1[id];
					Point& point4=points2[id];

					int dx1=abs(point4.x-point1.x);
					int dy1=abs(point4.y-point1.y);
					int dx2=abs(point3.x-point2.x);
					int dy2=abs(point3.y-point2.y);
					if (dx1<maxdelta && dy1<maxdelta && dx2<maxdelta && dy2<maxdelta)
					{
						Swap(points2[i], points2[id]);
						break;
					}
				}

				found=true;
			}
		}
	}while(found);
}

void Morph::LoadMesh( const char* filename, Points& points )
{
	points.clear();

	FileR* filer=new FileR(filename);
	int size=filer->GetSize();

	unsigned char* data=new unsigned char[size];

	filer->Read(data, 1, size);

	int off=0;

	unsigned char bit=0x80;	// initial bit for stream
	int bitcount=0;
	int x1=0, x2=0, y1=0, y2=0;

	while(true)
	{
		unsigned char tmpy=data[off++];
		if (tmpy==0xc8)	// share p1
		{
			y2=data[off++];
			unsigned char x2lo=data[off++];
			x2=x2lo*2+FetchBit(bit, data, off, bitcount);

			AddLine(x1, y1, x2, y2, points);
			continue;
		}
		
		if (tmpy==0xc9)	// share p2
		{
			y1=data[off++];
			unsigned char x1lo=data[off++];
			x1=x1lo*2+FetchBit(bit, data, off, bitcount);

			AddLine(x1, y1, x2, y2, points);
			continue;
		}

		if (tmpy==0xff)	// end of frame
		{
			break;
		}

		// no share
		y1=tmpy;
		unsigned char x1lo=data[off++];
		x1=x1lo*2+FetchBit(bit, data, off, bitcount);
		
		y2=data[off++];
		unsigned char x2lo=data[off++];
		x2=x2lo*2+FetchBit(bit, data, off, bitcount);

		AddLine(x1, y1, x2, y2, points);
	};

	delete [] data;
	delete filer;
}

void Morph::WriteMesh( const char* filename, Points& points )
{
	int numpoints=points.size();
	
	FileW* filew=new FileW(filename);
	for (int i=0 ; i<numpoints ; i++)
	{
		Point& point=points[i];

		short x=BSwapShort(point.x);
		short y=BSwapShort(point.y);

		filew->Write(&x, 1, sizeof(x));
		filew->Write(&y, 1, sizeof(y));
	}
	delete filew;

}

int Morph::FetchBit( unsigned char& bit, unsigned char* data, int& off, int& bitcount )
{
	bitcount--;
	if (bitcount<0)
	{
		bit=data[off++];
		bitcount=7;
	}
	
	return (bit>>(bitcount-1)) & 0x01;
}

void Morph::AddLine( int x1, int y1, int x2, int y2, Points& points )
{
	int dx=x2-x1;
	int dy=y2-y1;

	if (abs(dy)>abs(dx))
	{
		if (dy!=0)
		{
			if (dy<0)
			{
				Swap(x1, x2);
				Swap(y1, y2);
			}

			int xstep=dx*65536/dy;
			x1*=65536;

			for (int y=y1 ; y<y2 ; y++)
			{
				points.push_back(Point(x1>>16, y));
				
				x1+=xstep;
			}
		}
	}
	else
	{
		if (dx!=0)
		{
			if (dx<0)
			{
				Swap(x1, x2);
				Swap(y1, y2);
			}

			int ystep=dy*65536/dx;
			y1*=65536;

			for (int x=x1 ; x<x2 ; x++)
			{
				points.push_back(Point(x, y1>>16));
				
				y1+=ystep;
			}
		}
	}
}

void Morph::Display( Points& points1, Points& points2, int morphframe )
{
	int numpoints1=points1.size();
	int numpoints2=points2.size();
	int numpoints=Max(numpoints1, numpoints2);

	for (int i=0 ; i<numpoints ; i++)
	{
		Point& point1=points1[i % numpoints1];
		Point& point2=points2[i % numpoints2];

		int x=point1.x+(point2.x-point1.x)*morphframe/64;
		int y=point1.y+(point2.y-point1.y)*morphframe/64;
		
		gfx->Plot(x, y, 0xffffff);
	}
}

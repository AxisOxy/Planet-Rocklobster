#include "include.h"

DEFINE_CLASS(Logo,FillerBase);
		
Logo::Logo()
{
	
}

Logo::~Logo()
{
	
}

void Logo::Init( Gfx *_gfx, Input *_input )
{	
	FillerBase::Init(_gfx,_input);
	
	sLogo	logo_oxyron;
		
	ScanLogo("Data/Parts/Logo/logo.png", logo_oxyron);

	ExportLogo("Data/Parts/Logo/oxyron.dat", logo_oxyron);
}

void Logo::Update( float _rendertime )
{
	FillerBase::Update(_rendertime);

	gfx->Clear(0);

	static int frame=0;
	static bool invcol=false;
	static int logoid;
	
	FillRect(0, 0, 320, 256, 0);

	int numlines;

	sLogo& logo=logos[logoid];

	numlines=ShowObject(logo, (frame & 0xff)  , 8);	

	Fill(invcol);

	if ((frame & 0xff)==0xff)
	{
		invcol=!invcol;
		logoid=(logoid+1) % 1;
	}

	char text[256];

	sprintf(text, "numlines: %d", numlines);
	Label(0, 0, text, 0xff);

	frame++;	
	
	Sleep(15);
}

void Logo::ScanLogo( const char* filename, sLogo& logo )
{
	Outlines& outlines=logo.outlines;

	Image image;

	image.Load(filename);

	Pixels pixels;

	for (int y=1 ; y<255 ; y++)
	{
		for (int x=318 ; x>0 ; x--)
		{
			unsigned int co1=image.GetPixel(x  , y  );
			unsigned int co2=image.GetPixel(x+1, y  );
			unsigned int co3=image.GetPixel(x  , y+1);
			unsigned int co4=image.GetPixel(x+1, y+1);

			if (co1!=co2 || co1!=co3 || co1!=co4)
				pixels.push_back(Pixel(x, y+71));
		}
	}

	while(true)
	{
		if (pixels.empty())
			break;

		PixelIter iter=pixels.begin();
		Pixel pixel1=*iter;

		iter=pixels.erase(iter);

		Pixels pixels2;

		while(true)
		{
			PixelIter iterfound=pixels.end();
			while(iter!=pixels.end())
			{
				Pixel pixel2=*iter;

				int dx=pixel2.x-pixel1.x;
				int dy=pixel2.y-pixel1.y;
				int d=dx*dx+dy*dy;
				if (d<=1)
				{
					iterfound=iter;
					break;
				}
				++iter;
			}

			if (iterfound==pixels.end())
			{
				break;
			}

			pixel1=*iterfound;
			pixels2.push_back(pixel1);
			pixels.erase(iterfound);
			iter=pixels.begin();
		}

		Outline outline;

		while(true)
		{	
			if (!ScanEdges(pixels2, outline))
				break;
		}

		int numedges=outline.edges.size();
		if (numedges>0)
		{
			Edge& edge1=outline.edges[0];
			Edge& edge2=outline.edges[numedges-1];
			edge2.p2=edge1.p1;

			outlines.push_back(outline);
		}
	}

	logos.push_back(logo);
}

bool Logo::ScanEdges( Pixels& pixels, Outline& outline )
{
	if (pixels.size()<2)
		return false;

	PixelIter iter=pixels.begin();
	Pixel& pixel1=*iter;

	const float maxerror=2.0f*2.0f;

	while(iter!=pixels.end())
	{
		Pixel& pixel2=*iter;

		PixelIter iter2=pixels.begin();
		while(iter2!=iter)
		{
			Pixel& pixel3=*iter2;

			float error=GetError(pixel1, pixel2, pixel3);
			if (error>maxerror)
			{
				outline.edges.push_back(Edge(pixel1, pixel3));

				pixels.erase(pixels.begin(), iter2);
			
				return true;
			}

			++iter2;
		}

		++iter;
	}
	
	PixelIter iter2=pixels.end();
	iter2--;

	Pixel& pixel3=*iter2;

	outline.edges.push_back(Edge(pixel1, pixel3));

	return false;
}

float Logo::GetError( Pixel& pixel1, Pixel& pixel2, Pixel& pixel3 )
{
	float dx=(float)(pixel2.x-pixel1.x);
	float dy=(float)(pixel2.y-pixel1.y);
	float len=OxySqrt(dx*dx+dy*dy);

	float x=(float)(pixel1.x);
	float y=(float)(pixel1.y);

	dx/=len;
	dy/=len;

	float x3=(float)(pixel3.x);
	float y3=(float)(pixel3.y);

	float dx2,dy2;

	float error;
	float minerror=99999.0f;
	
	for (int i=0 ; i<len ; i++)
	{
		dx2=x3-x;
		dy2=y3-y;
		error=dx2*dx2+dy2*dy2;
		if (error<minerror)
			minerror=error;
		
		x+=dx;
		y+=dy;
	}

	return minerror;
}

	struct IndexedPoint
	{
		short	x,
				y;

		IndexedPoint()
		{
			this->x=0;
			this->y=0;
		}

		IndexedPoint( short x, short y )
		{
			this->x=x;
			this->y=y;
		}
	};
	typedef std::vector<IndexedPoint> IndexedPoints;

	struct IndexedEdge
	{
		unsigned short id1;
		unsigned short id2;

		IndexedEdge()
		{
			this->id1=0xff;
			this->id2=0xff;
		}

		IndexedEdge( unsigned short id1, unsigned short id2 )
		{
			this->id1=id1;
			this->id2=id2;
		}
	};
	typedef std::vector<IndexedEdge> IndexedEdges;

void Logo::ExportLogo( const char* filename, sLogo& logo )
{
	IndexedPoints points;
	IndexedEdges indexededges;

	Outlines& outlines=logo.outlines;

	int numoutlines=outlines.size();
	for (int ioutline=0 ; ioutline<numoutlines ; ioutline++)
	{
		Outline& outline=outlines[ioutline];
	
		Edges& edges=outline.edges;
		int numedges=edges.size();
		for (int iedge=0 ; iedge<numedges ; iedge++)
		{
			Edge& edge=edges[iedge];

			Pixel& p1=edge.p1;
			Pixel& p2=edge.p2;

			int id1=-1;
			int id2=-1;

			int numpoints=points.size();

			for (int ipoint=0 ; ipoint<numpoints ; ipoint++)
			{
				IndexedPoint& p3=points[ipoint];

				if (p1.x==p3.x && p1.y==p3.y)
				{
					id1=ipoint;
				}

				if (p2.x==p3.x && p2.y==p3.y)
				{
					id2=ipoint;
				}
			}

			if (id1==-1)
			{
				id1=points.size();
				points.push_back(IndexedPoint(p1.x, p1.y));
			}

			if (id2==-1)
			{
				id2=points.size();
				points.push_back(IndexedPoint(p2.x, p2.y));
			}

			indexededges.push_back(IndexedEdge(id1, id2));
		}
	}

	FileW* filew=new FileW(filename);

	short numpoints=points.size();
	short numpointsswap=BSwapShort(numpoints);
	
	filew->Write(&numpointsswap, 1, sizeof(numpointsswap));
	
	for (int ipoint=0 ; ipoint<numpoints ; ipoint++)
	{
		IndexedPoint& point=points[ipoint];
		
		point.x=BSwapShort((319-point.x)*128/320*2);
		point.y=BSwapShort((point.y+32)*128/320*2);

		filew->Write(&point.x, 1, sizeof(point.x));
		filew->Write(&point.y, 1, sizeof(point.y));
	}

	short numedges=indexededges.size();
	short numedgesswap=BSwapShort(numedges);

	filew->Write(&numedgesswap, 1, sizeof(numedgesswap));
	
	for (int iedge=0 ; iedge<numedges ; iedge++)
	{
		IndexedEdge& edge=indexededges[iedge];
	
		edge.id1=BSwapShort(edge.id1*4);
		edge.id2=BSwapShort(edge.id2*4);

		filew->Write(&edge.id1, 1, sizeof(edge.id1));
		filew->Write(&edge.id2, 1, sizeof(edge.id2));
	}

	delete filew;
}

int Logo::ShowObject( sLogo& logo, int frame, unsigned char co )
{
	float rz=-pi*0.5f+(float)(frame)*2.0f*pi/256.0f;

	float scale=10.0f/(float)((0x109-(frame))/5.0f);

	float sz=OxySin(rz);
	float cz=OxyCos(rz);

	int numlines=0;

	float x1,x2,x3,x4;
	float y1,y2,y3,y4;

	Outlines& outlines=logo.outlines;

	int numoutlines=outlines.size();
	for (int ioutline=0 ; ioutline<numoutlines ; ioutline++)
	{
		Outline& outline=outlines[ioutline];
	
		Edges& edges=outline.edges;
		int numedges=edges.size();
		for (int iedge=0 ; iedge<numedges ; iedge++)
		{
			Edge& edge=edges[iedge];

			Pixel& p1=edge.p1;
			Pixel& p2=edge.p2;

			x1=(float)(-p1.x+160)*scale;
			y1=(float)(p1.y-128)*scale;
			x2=(float)(-p2.x+160)*scale;
			y2=(float)(p2.y-128)*scale;

			x3=x1*sz+y1*cz;
			y3=x1*cz-y1*sz;

			x4=x2*sz+y2*cz;
			y4=x2*cz-y2*sz;
			
			DoLine((int)(x3)+160, (int)(y3)+128, (int)(x4)+160, (int)(y4)+128, co, true);

			numlines++;
		}
	}

	return numlines;
}

void Logo::Fill( bool invcol )
{
	unsigned int col0=0x000000;
	unsigned int col1=0x303030;
	unsigned int col2=0x606060;
	unsigned int col4=0x909090;
	unsigned int col8=0xc0c0c0;

	if (invcol)
	{
		Swap(col0, col8);
		Swap(col1, col4);
	}

	unsigned int pal[] = {	col0, col1, col2, col2,
							col4, col4, col4, col4,
							col8, col8, col8, col8,
							col8, col8, col8, col8 };

	int x,y;
	unsigned char co;

	for (x=0 ; x<320 ; x++)
	{
		co=0;
		for (y=0 ; y<256 ; y++)
		{
			co^=pixelbuffer[y][x];
			pixelbuffer[y][x]=co;
			
			unsigned int col=pal[co];

			gfx->Plot(x, y, col);
		}
	}
}

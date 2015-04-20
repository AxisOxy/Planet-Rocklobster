#include "include.h"

/*
	TODO:	- add support for conkave polygons (triangulate clippolygons?)
			- merge triangles with shared edge on the same plane on import
*/

//#define WIRE_AMIGA					// use for filled versions on amiga
#define WIRE_RESORT_BITS				// use for wireframe on amiga
//#define WIRE_FAKERS_LINIEN_STINKEN	// should make files smaller (neccessary for compatibility with the c64 player)
//#define WIRE_EXPORT_LINECOLORS		// used for colored wireframes on c64

DEFINE_CLASS(VectorizerWire,Effect);
		
VectorizerWire::VectorizerWire()
{
	//camrx=0.0f+15.0f*DegtoRad;
	//camry=0.0f+45.0f*DegtoRad;
	//camrz=0.0f;
	//campos.Set(0.0f, 0.0f, 0.0f);

	camrx=0.0f;
	camry=-90.0f*DegtoRad;
	camrz=0.0f;
	campos.Set(23.0f, 0.0f, 0.0f);

	//donut
//	maxframes=256;

	//all others
	maxframes=128;

	au=300.0f;
	tf=  0.0f;
	centerx=160.0f;
	centery=100.0f;
	minx=  0.0f;
	maxx=319.0f;
	miny=  0.0f;
	maxy=199.0f;
	nearplane=0.1f;
	
	memset(pal, 0, sizeof(pal));

	numlines=0;
	datapoi=0;
	memset(data, 0, sizeof(data));
}

VectorizerWire::~VectorizerWire()
{
	int numvertices=vertices.size();
	for (int i=0 ; i<numvertices ; i++)
	{
		delete vertices[i];
	}
	vertices.clear();

	int numpolys=polys.size();
	for (int i=0 ; i<numpolys ; i++)
	{
		delete polys[i];
	}
	polys.clear();

	FileW* filew=new FileW("Data/Parts/VectorizerWire/lines.dat");
	filew->Write(data, 1, datapoi);
	delete filew;
}

void VectorizerWire::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);
	
	vertices.clear();
	polys.clear();

//	AddMesh("Data/Parts/VectorizerWire/donut6.obj", "", 3.2f, pi*0.5f, 0.0f, 0.0f, Vector3(0.0f, 0.0f, 0.0f), false);
	AddMesh("Data/Parts/VectorizerWire/lobster.obj", "", 0.04f, 0.0f, pi*0.5f, 0.0f, Vector3(-0.84898019f, 2.8f, -0.81333804f), false);
}

void VectorizerWire::Update( float _rendertime )
{
	gfx->Clear(0);

#ifdef WIRE_AMIGA
	static bool filled=true;
#else
	static bool filled=false;
#endif

	numlines=0;

	if (input->WasKeyHit(KB_F))
	{
		filled=!filled;
	}

	if (filled)
	{
		FillRect(0, 0, 320, 256, 0);

		unsigned char bestcolswapflags=0;
		int bestcost=99999999;

		for (unsigned char colswapflags=0 ; colswapflags<1 ; colswapflags++)
		{
			drawedges.clear();
			drawpoints.clear();
		
			bool dostep=false;
			if (colswapflags==0)
				dostep=true;

			ShowObject(_rendertime, filled, colswapflags, dostep);

			Lines lines;
			Lines tmplines;
			std::vector<unsigned char> cols;

			int numedges=drawedges.size();

			for (int i=0 ; i<numedges ; i++)
			{
				Edge& edge=drawedges[i];

				if (edge.col!=0)
				{
					Point p1=drawpoints[edge.o1];
					Point p2=drawpoints[edge.o2];

					tmplines.clear();
					ClipScreenFill(p1, p2, tmplines);

					for (int i=0 ; i<(int)(tmplines.size()) ; i++)
					{
						lines.push_back(tmplines[i]);
						cols.push_back(edge.col);
					}
				}
			}
			int cost=GetAccumFilledEdgeCost(lines, cols);
			if (cost<bestcost)
			{
				bestcost=cost;
				bestcolswapflags=colswapflags;
			}
		}

		drawedges.clear();
		drawpoints.clear();
		
		ShowObject(_rendertime, filled, bestcolswapflags, false);

		Lines lines;
		Lines tmplines;
		std::vector<unsigned char> cols;

		int numedges=drawedges.size();

		for (int i=0 ; i<numedges ; i++)
		{
			Edge& edge=drawedges[i];

			if (edge.col!=0)
			{
				Point p1=drawpoints[edge.o1];
				Point p2=drawpoints[edge.o2];

				tmplines.clear();
				ClipScreenFill(p1, p2, tmplines);

				for (int i=0 ; i<(int)(tmplines.size()) ; i++)
				{
					lines.push_back(tmplines[i]);
					cols.push_back(edge.col);
				}
			}
		}

		int numlines=lines.size();

		for (int j=0 ; j<numlines ; j++)
		{
			Vector3& p1=lines[j].p1;
			Vector3& p2=lines[j].p2;

			int ix1=(int)(p1.x);
			int iy1=(int)(p1.y);
			int ix2=(int)(p2.x);
			int iy2=(int)(p2.y);

			if (iy1!=iy2)
			{
				unsigned char col=cols[j];

				DoLineFill(ix1, iy1, ix2, iy2, col);

				this->numlines++;

				if (frame<maxframes && datapoi<=0x1fff9)
				{
					data[datapoi++]=(col) | ((ix1 & 0x01)<<6) | ((ix2 & 0x01)<<5);
					data[datapoi++]=ix1>>1;
					data[datapoi++]=iy1;
					data[datapoi++]=ix2>>1;
					data[datapoi++]=iy2;
				}
			}
		}

		Fill();
	}
	else
	{
		resultlines.clear();

		ShowObject(_rendertime, filled, 0, true);

		BuildResultData();
	}

	if(frame<maxframes)
	{
		data[datapoi++]=0xff;
	}

	if (!filled)
	{
		ShowResultData();
	}

	char text[256];

	sprintf(text, "rendertime: %.02f ms", rendertime);
	Label(320, 2, text, 0x01);

	sprintf(text, "numlines: %d", numlines);
	Label(320, 10, text, 0x01);

	sprintf(text, "frame: %d", frame);
	Label(320, 18, text, 0x01);

	sprintf(text, "datasize: %d", datapoi);
	Label(320, 26, text, 0x01);
	
	Sleep(15);

	Effect::Update(_rendertime);
}

int VectorizerWire::GetAccumFilledEdgeCost( Lines& lines, const std::vector<unsigned char>& cols )
{
	int numlines=lines.size();
	int cost=0;

	for (int i=0 ; i<numlines ; i++)
	{
		Line& line=lines[i];
		unsigned char co=cols[i];
		cost+=GetFilledEdgeCost(line, co);
	}
	return cost;
}

int VectorizerWire::GetFilledEdgeCost( Line& line, unsigned char co )
{
	int cobits[] = {	0, 1, 1, 2, 1, 2, 2, 3,
						1, 2, 2, 3, 2, 3, 3, 4 };

	int dx=abs((int)(line.p2.x-line.p1.x));
	int dy=abs((int)(line.p2.y-line.p1.y));
	int len=max(dx, dy);
	int cost=len*cobits[co & 0x0f];
	
	return cost;
}

void VectorizerWire::ShowObject( float time_diff, bool filled, unsigned char colswapflags, bool dostep )
{
	// starship
/*
	static float objrx=0.0f;
	static float objry=0.0f;
	static float objrz=0.0f;
	
	//static Vector3 objpos(31.0f, 0.0f, 40.0f);	// starship
	//Vector3 movevec(0.0f, -0.5f, 0.0f);
	
	static Vector3 objpos(39.0f, -18.0f, 50.0f);	// ship2 & ship5
	Vector3 movevec(0.0f, -0.65f, 0.0f);

	if (dostep)
	{
		//objrx=0.01f+(float)(frame)*0.525f*pi/(float)(maxframes);	// starship
		//objry=0.01f+(float)(frame)*1.25f*pi/(float)(maxframes);	
		//objrz=0.01f+pi*1.5f+OxySin(2.0f*pi*(float)(frame)/(float)(maxframes))*0.25f;

		//objrx=-0.35f+(float)(frame)*0.70f*pi/(float)(maxframes);	// ship2
		//objry=-1.4f+(float)(frame)*2.5f*pi/(float)(maxframes);	
		//objrz=-0.5f+pi*1.5f+OxySin(2.0f*pi*(float)(frame)/(float)(maxframes))*0.25f;
	
		objrx=-0.35f+(float)(frame)*0.55f*pi/(float)(maxframes);	// ship5
		objry=0.3f+(float)(frame)*4.0f*pi/(float)(maxframes);	
		objrz=-0.5f+pi*1.5f+OxySin(2.0f*pi*(float)(frame)/(float)(maxframes))*0.25f;
	}
		
	Matrix3x4 mat;

	mat.Unit();
	mat.RotateY(objry);
	mat.RotateX(objrx);
	mat.RotateZ(objrz);
	movevec.MultiplyMatrixNoTranslate(mat);
	mat.Translate(objpos);
	
	if (dostep)
		objpos+=movevec;
*/	
/*
	// mech
	static float objrx=0.0f;
	static float objry=0.0f;
	static float objrz=0.0f;
	//static Vector3 objpos(0.0f, 7.6f, 15.0f);
	static Vector3 objpos(0.0f, 0.0f, 15.0f);

	if (dostep)
	{
		objrx=0.12f*pi;
		objry=0.01f+(float)(frame)*2.0f*pi/(float)(maxframes);
		objrz=0.0f;
	}

	Matrix3x4 mat;

	mat.Unit();
	mat.RotateY(objry);
	mat.RotateX(objrx);
	mat.RotateZ(objrz);
	mat.Translate(objpos);
*/
	// lobster
	static float objrx=0.0f;
	static float objry=0.0f;
	static float objrz=0.0f;
	//static Vector3 objpos(0.0f, 7.6f, 15.0f);
	static Vector3 objpos(0.0f, 0.0f, 18.0f);

	if (dostep)
	{
		objrx=0.20f*pi;
		objry=-1.05f+(float)(frame)*2.0f*pi/(float)(maxframes);
		objrz=0.0f;

		float zoompos=1.8f+pi*0.5f+(float)(frame)*2.0f*pi/(float)(maxframes);

		objpos.y=-OxySin(zoompos)*1.35f-0.5f;
		objpos.z=OxySin(zoompos)*8.0f+19.0f;
	}

	Matrix3x4 mat;

	mat.Unit();
	mat.RotateY(objry);
	mat.RotateX(objrx);
	mat.RotateZ(objrz);
	mat.Translate(objpos);
/*
	// donut
	static float objrx=0.0f;
	static float objry=0.0f;
	static float objrz=0.0f;
	static Vector3 objpos(0.0f, 0.0f, 15.0f);

	if (dostep)
	{
		objrx+=1.0f*2.0f*pi/(float)(maxframes);
		objry+=2.0f*2.0f*pi/(float)(maxframes);
		objrz-=1.0f*2.0f*pi/(float)(maxframes);
	}

	Matrix3x4 mat;

	mat.Unit();
	mat.RotateY(objrx);
	mat.RotateX(objry);
	mat.RotateZ(objrz);
	mat.Translate(objpos);
*/
/*
	// scene
	static float objrx=0.0f;
	static float objry=0.0f;
	static float objrz=0.0f;
	static Vector3 objpos(0.0f, 1.0f, 13.5f);

	if (dostep)
	{
		objrx=0.1f*pi;
		objry=0.01f+(float)(frame)*2.0f*pi/(float)(maxframes);
		objrz=0.0f;
	}

	Matrix3x4 mat;

	mat.Unit();
	mat.RotateY(objry);
	mat.RotateX(objrx);
	mat.RotateZ(objrz);
	mat.Translate(objpos);
*/

	int numvertices=vertices.size();

	for (int i=0 ; i<numvertices ; i++)
	{
		Vertex* vertex=vertices[i];

		if (vertex->transform)
			vertex->pos2=TransformPoint(vertex->pos, mat);
		else
			vertex->pos2=vertex->pos;
	}

	int numpolys=polys.size();

	sortvalues.resize(numpolys);
	clippolys.resize(numpolys);

	for (int i=0 ; i<numpolys ; i++)
	{
		Poly* poly=polys[i];
		ClipPoly& clippoly=clippolys[i];

		clippoly.Clear();
		clippoly.col=poly->col;
		
		float z=0.0f;
		float minz=999999.0f;
		float maxz=     0.0f;
			
		for (int j=0 ; j<poly->numids ; j++)
		{
			int o1=poly->ids[j];

			Vector3& p1=vertices[o1]->pos2;

			poly->vertices[j]=p1;
			clippoly.AddPoint(Vector2(p1.x, p1.y));
			UpdatePolyBounds(poly);
			UpdateClipPolyBounds(clippoly);

			z+=poly->vertices[j].z;
			minz=Min(minz, poly->vertices[j].z);
			maxz=Max(maxz, poly->vertices[j].z);
		}

		clippoly.Reverse();

		z/=(float)(poly->numids);

		// lobster
		float sort=minz*0.0f+maxz*0.0f+z*1.0f;

		// scene
//		float sort=minz*0.0f+maxz*0.5f+z*0.5f;

		// mech
//		float sort=minz*0.0f+maxz*1.0f+z*1.0f;

		// mech2 & baller
//		float sort=minz*1.0f+maxz*0.0f+z*1.0f;
		
		sortvalues[i]=SortValue(i, sort);

		if (poly->cull)
		{	
			Vector3& p1=poly->vertices[0];
			Vector3& p2=poly->vertices[1];
			Vector3& p3=poly->vertices[2];
		
			float cross=(((p2.x-p1.x)*(p3.y-p1.y)) - ((p2.y-p1.y)*(p3.x-p1.x)));
		
			poly->visible=false;
			if (cross>0.0f && minz>nearplane)
			{
				poly->visible=true;
			}
		
			if (poly->visible)
			{
				int clipcounts[4] = { 0, 0, 0, 0 };
				for (int j=0 ; j<poly->numids ; j++)
				{
					Vector3& p1=poly->vertices[j];
					if (p1.x<minx)
					{
						clipcounts[0]++;
					}
					if (p1.x>maxx)
					{
						clipcounts[1]++;
					}
					if (p1.y<miny)
					{
						clipcounts[2]++;
					}
					if (p1.y>maxy)
					{
						clipcounts[3]++;
					}
				}
				if (clipcounts[0]==poly->numids ||
					clipcounts[1]==poly->numids ||
					clipcounts[2]==poly->numids ||
					clipcounts[3]==poly->numids)
				{
					poly->visible=false;
				}					
			}
		}
		else
		{
			poly->visible=true;
		}
	}

	for (int i=0 ; i<numpolys ; i++)
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

	for (int i=0 ; i<numpolys ; i++)
	{
		SortValue& sort=sortvalues[i];
		
		Poly* poly=polys[sort.polyid];
		
		if (poly->visible)
		{
			if (filled)
			{
				ClipPoly& clippoly=clippolys[sort.polyid];

				DoPoly(clippoly, i, colswapflags);
			}
			else
			{
				for (int j=0 ; j<poly->numids ; j++)
				{
					int j2=(j+1) % poly->numids;

					Vector3& p1=poly->vertices[j ];
					Vector3& p2=poly->vertices[j2];
				
					if (poly->draw)
						DoLine(p1, p2, i, poly->col);
				}
			}
		}
	}
}

Vector3 VectorizerWire::TransformPoint( Vector3 pos, Matrix3x4& mat )
{
	pos.MultiplyMatrix(mat);

	float z=au/(pos.z+tf);
	float x=pos.x*z+centerx;
	float y=pos.y*z+centery;

	return Vector3(x, y, pos.z);
}

void VectorizerWire::DoPoly( ClipPoly& poly, int sortid, unsigned char colswapflags )
{	
	int numpolys=polys.size();
	
	ClipPolys	clippolys,
				newclippolys;
				
	ClipPoly polypoly(poly);

	int numpoints=poly.numpoints;

	Planes planes;

	for (int i=sortid+1 ; i<numpolys ; i++)
	{
		SortValue& sort=sortvalues[i];
		
		Poly* poly=polys[sort.polyid];
		if (poly->visible)
		{
			GatherClipPlanes(polypoly, poly, planes);
		}
	}

	Clip(polypoly, planes, clippolys);
	
	int numclippolys=clippolys.size();

	newclippolys.clear();

	for (int j=0 ; j<numclippolys ; j++)
	{
		ClipPoly& clippoly=clippolys[j];

		bool covered=false;

		for (int i=sortid+1 ; i<numpolys ; i++)
		{
			SortValue& sort=sortvalues[i];
		
			Poly* poly=polys[sort.polyid];

			if (poly->visible)
			{
				if (IsCovered(clippoly, poly))
				{
					covered=true;
					break;
				}
			}
		}

		for (int i=0 ; i<clippoly.numpoints ; i++)
		{
			int i2=(i+1) % clippoly.numpoints;
			Vector2& p1=clippoly.points[i ];
			Vector2& p2=clippoly.points[i2];

			gfx->Line(p1.x+720, p1.y, p2.x+720, p2.y, 0xffffff);
			if (!covered)
			{
				gfx->Line(p1.x+1160, p1.y, p2.x+1160, p2.y, 0xffffff);
			}
		}

		if (!covered)
		{
			newclippolys.push_back(clippoly);
		}
	}

	if (newclippolys.size()>0)
	{
		int numuncoveredpolys=newclippolys.size();

		for (int j=0 ; j<numuncoveredpolys ; j++)
		{
			ClipPoly& clippoly=newclippolys[j];
		
			int numpoints=clippoly.numpoints;

			for (int i=0 ; i<numpoints ; i++)
			{
				int i2=(i+1) % numpoints;

				Vector2& p1=clippoly.points[i ];
				Vector2& p2=clippoly.points[i2];

				Vector3 p3(p1.x, p1.y, 0.0f);
				Vector3 p4(p2.x, p2.y, 0.0f);

				AddDrawEdge(p3, p4, poly.col);//GetSwappedCol(poly.col, 0));
			}
		}
	}
}

unsigned char  VectorizerWire::GetSwappedCol( unsigned char col, unsigned char colswapflags )
{
	unsigned char co1=(col   ) & 1;
	unsigned char co2=(col>>1) & 1;
	unsigned char co3=(col>>2) & 1;
	
	if (colswapflags & 1)
		Swap(co1, co2);

	if (colswapflags & 2)
		Swap(co1, co3);

	if (colswapflags & 4)
		Swap(co2, co3);

	return (co3<<2) | (co2<<1) | (co1);
}

void VectorizerWire::GatherClipPlanes( ClipPoly& clippoly, Poly* coverpoly, Planes& out_planes )
{
	int numpoints=clippoly.numpoints;
	
	Vector3 cutpoint;

	bool cutfound=false;

	for (int i=0 ; i<numpoints ; i++)
	{
		int i2=(i+1) % numpoints;

		Vector2& p1=clippoly.points[i ];
		Vector2& p2=clippoly.points[i2];

		Vector3 p5(p1.x, p1.y, 0.0f);
		Vector3 p6(p2.x, p2.y, 0.0f);
		
		for (int j=0 ; j<coverpoly->numids ; j++)
		{
			int j2=(j+1) % coverpoly->numids;

			Vector3& p3=coverpoly->vertices[j ];
			Vector3& p4=coverpoly->vertices[j2];
		
			if (Clip(p5, p6, p3, p4, cutpoint, -0.001f))
			{
				cutfound=true;
				break;
			}
		}
	}

	if (!cutfound)
	{
		return;
	}

	for (int j=0 ; j<coverpoly->numids ; j++)
	{
		int j2=(j+1) % coverpoly->numids;
		
		Vector3& p3=coverpoly->vertices[j ];
		Vector3& p4=coverpoly->vertices[j2];

		Plane plane(p3, p4, p4+Vector3(0.0f, 0.0f, 1.0f));

		float angleepsilon=0.01f;
		float distepsilon=1.0f;

		bool planefound=false;
		int numplanes=out_planes.size();
		for (int iplane=0 ; iplane<numplanes ; iplane++)
		{
			Plane& usedplane=out_planes[iplane];
			if ( (plane.normal-usedplane.normal).Scalar()<angleepsilon &&
				 OxyFabs(plane.distance-usedplane.distance)<distepsilon)
			{
			//	planefound=true;
				break;
			}
			
			if ( (plane.normal+usedplane.normal).Scalar()<angleepsilon &&
				 OxyFabs(plane.distance+usedplane.distance)<distepsilon)
			{
			//	planefound=true;
				break;
			}
		}

		if (!planefound)
		{
			out_planes.push_back(plane);
		}
	}
}

void VectorizerWire::Clip( ClipPoly& clippoly, Planes& planes, ClipPolys& out_polys )
{	
	ClipPolys newpolys;

	newpolys.push_back(clippoly);

	float epsilon=0.001f;

	int numplanes=planes.size();
	for (int i=0 ; i<numplanes ; i++)
	{
		Plane& plane=planes[i];

		ClipPolys tmppolys;

		int numpolys=newpolys.size();
		for (int i=0 ; i<numpolys ; i++)
		{
			ClipPoly& clippoly2=newpolys[i];
		
			SplitPolyOnPlane(clippoly2, plane, tmppolys, epsilon);
		}
		newpolys=tmppolys;
	}

	int numpolys=newpolys.size();
	for (int i=0 ; i<numpolys ; i++)
	{
		out_polys.push_back(newpolys[i]);
	}
}

bool VectorizerWire::SplitPolyOnPlane( ClipPoly& clippoly, Plane& plane, ClipPolys& out_polys, float epsilon )
{
	bool left=false;
	bool right=false;

	int numpoints=clippoly.numpoints;

	for (int i=0 ; i<numpoints ; i++)
	{
		Vector2& p1=clippoly.points[i];
		Vector3 p2(p1.x, p1.y, 0.0f);

		float dist=plane.GetDistance(p2);
		if(dist<-epsilon)
			left=true;

		if (dist>epsilon)
			right=true;
	}

	if (left && right)
	{
		ClipPoly	newclippoly1,
					newclippoly2;						

		if (SplitPolyOnPlane(clippoly, plane, newclippoly1, 0.0f, -1.0f))
		{
			out_polys.push_back(newclippoly1);
		}

		if (SplitPolyOnPlane(clippoly, plane, newclippoly2, 0.0f, 1.0f))
		{
			out_polys.push_back(newclippoly2);
		}

		return true;
	}

	out_polys.push_back(clippoly);

	return false;
}

bool VectorizerWire::SplitPolyOnPlane( ClipPoly& clippoly, Plane& plane, ClipPoly& out_poly, float epsilon, float scale )
{
	out_poly.Clear();
	out_poly.col=clippoly.col;

	int numpoints=clippoly.numpoints;
	
	for (int i=0 ; i<numpoints ; i++)
	{
		int i2=(i+1) % numpoints;
		Vector2& p1=clippoly.points[i ];
		Vector2& p2=clippoly.points[i2];
		Vector3 p3(p1.x, p1.y, 0.0f);
		Vector3 p4(p2.x, p2.y, 0.0f);

		float dist1=plane.GetDistance(p3)*scale;
		float dist2=plane.GetDistance(p4)*scale;
			
		// both points outside, skip
		if (dist1<-epsilon && dist2<-epsilon)
		{
			continue;
		}

		// both points inside, use p1
		if (dist1>=epsilon && dist2>=epsilon)
		{
			out_poly.AddPoint(p1);
			
			continue;
		}

		// p2 inside, entering visible area, add clipped point
		if (dist2>=epsilon)
		{
			float factor=(0.0f-dist1)/(dist2-dist1);

			Vector2 p3=p1+(p2-p1)*factor;
			
			out_poly.AddPoint(p3);
			continue;
		}

		// p1 inside, exiting visible area, add p1 and clipped point
		if (dist1>=epsilon)
		{
			float factor=(0.0f-dist2)/(dist1-dist2);

			Vector2 p3=p2+(p1-p2)*factor;
		
			out_poly.AddPoint(p1);
			out_poly.AddPoint(p3);
			continue;
		}
	}

	if (out_poly.numpoints>2)
	{
		return true;
	}
	return false;
}

void VectorizerWire::DoLine( Vector3& p1, Vector3& p2, int sortid, int col )
{
	if (p1.z<nearplane || p2.z<nearplane)
	{
		return;
	}
	if (p1.x<minx && p2.x<minx)
	{
		return;
	}
	if (p1.x>maxx && p2.x>maxx)
	{
		return;
	}
	if (p1.y<miny && p2.y<miny)
	{
		return;
	}
	if (p1.y>maxy && p2.y>maxy)
	{
		return;
	}

//	gfx->Line(p1.x+320, p1.y, p2.x+320, p2.y, 0xffffff);

	int numpolys=polys.size();
	
	Lines	lines,
			newlines;

	lines.push_back(Line(p1, p2, col));

	for (int i=sortid+1 ; i<numpolys ; i++)
	{
		SortValue& sort=sortvalues[i];
		
		Poly* poly=polys[sort.polyid];

		if (poly->visible)
		{
		//	if (CheckPolyBounds(poly, p1) ||
		//		CheckPolyBounds(poly, p2))
			{
				newlines.clear();

				Lines::iterator iter=lines.begin();
				while(iter != lines.end())
				{
					Clip((*iter), poly, newlines);
				
					++iter;
				};

				lines=newlines;
			}
		}
	}

	int numlines=lines.size();

	for (int i=0 ; i<numlines ; i++)
	{
		Line line=lines[i];
		if (ClipScreen(line))
		{
			AddResultLine((int)(line.p1.x), (int)(line.p1.y), (int)(line.p2.x), (int)(line.p2.y), line.col);
			//DoLineScreen((int)(line.p1.x), (int)(line.p1.y), (int)(line.p2.x), (int)(line.p2.y));
		}
	}
}

int	VectorizerWire::AddDrawPoint( Vector3& p1 )
{
	static const float epsilon=1.0f;

	Points::iterator iter=drawpoints.begin();
	int i=0;
	while(iter!=drawpoints.end())
	{
		Point& p2=*iter;

		float dx=p2.x-p1.x;
		float dy=p2.y-p1.y;
		float dist=OxySqrt(dx*dx+dy*dy);
				
		if (dist<epsilon)
		{
			return i;
		}

		i++;
		++iter;
	}

	drawpoints.push_back(Point(p1.x, p1.y));

	return drawpoints.size()-1;
}
		
void VectorizerWire::AddDrawEdge( Vector3 p2, Vector3 p3, unsigned char col )
{
	static const float epsilon=1.0f;
	static const float epsilon2=-1.0f;

	if (col==0)
	{
		return;
	}

	Vector3 delta(p3-p2);
	if (delta.Scalar()<0.01f)
	{
		//return;
	}
	
	if (p3.x<p2.x)
	{
		Swap(p2, p3);
	}

	p2.z=0.0f;
	p3.z=0.0f;

	Vector3 cross;

	cross.Cross(p2, p3, p2+Vector3(0.0f, 0.0f, 1.0f));

	Plane plane1(p2, p2+cross, p2+Vector3(0.0f, 0.0f, 1.0f));
	Plane plane3(p2, p3, p2+Vector3(0.0f, 0.0f, 1.0f));

	float t2=plane1.GetDistance(p2);
	float t3=plane1.GetDistance(p3);
	
	if (t3<t2)
	{
		Swap(t2, t3);
		Swap(p2, p3);
	}

	Edges::iterator iter=drawedges.begin();
	while(iter!=drawedges.end())
	{
		Edge& edge=*iter;
		
		unsigned char edgecol=edge.col;
		unsigned char sharedcol=col^edgecol;
		
		Point& p02=drawpoints[edge.o1];
		Point& p12=drawpoints[edge.o2];

		Vector3 p0(p02.x, p02.y, 0.0f);
		Vector3 p1(p12.x, p12.y, 0.0f);
		
		float dist1=OxyFabs(plane3.GetDistance(p0));
		float dist2=OxyFabs(plane3.GetDistance(p1));
	
		if (dist1<epsilon && dist2<epsilon)
		{
			float t0=plane1.GetDistance(p0);
			float t1=plane1.GetDistance(p1);
			
			if (t1<t0)
			{
				Swap(t0, t1);
				Swap(p0, p1);
			}
			
			if ((t3+epsilon2)>=t0 && (t1+epsilon2)>=t2)
			{
				if (t2<=t0 && t3>=t1)
				{
					drawedges.erase(iter);
					AddDrawEdge(p2, p0, col);
					AddDrawEdge(p0, p1, sharedcol);
					AddDrawEdge(p1, p3, col);
					return;
				}

				if (t0<=t2 && t1>=t3)
				{
					drawedges.erase(iter);
					AddDrawEdge(p0, p2, edgecol);
					AddDrawEdge(p2, p3, sharedcol);
					AddDrawEdge(p3, p1, edgecol);
					return;
				}

				if (t0<=t2 && t3>=t1)
				{
					drawedges.erase(iter);
					AddDrawEdge(p0, p2, edgecol);
					AddDrawEdge(p2, p1, sharedcol);
					AddDrawEdge(p1, p3, col);
					return;
				}

				if (t2<=t0 && t1>=t3)
				{
					drawedges.erase(iter);
					AddDrawEdge(p2, p0, col);
					AddDrawEdge(p0, p3, sharedcol);
					AddDrawEdge(p3, p1, edgecol);
					return;
				}
			}
		}

		++iter;
	}

	AddDrawEdgeClipped(p2, p3, col);
}

void VectorizerWire::AddDrawEdgeClipped( Vector3 p1, Vector3 p2, unsigned char col )
{
	if (col==0)
	{
		return;
	}

	int o1=AddDrawPoint(p1);
	int o2=AddDrawPoint(p2);

	if (o1==o2)
	{
		return;
	}

	Edges::iterator iter=drawedges.begin();
	while(iter!=drawedges.end())
	{
		Edge& edge=*iter;
		
		bool shared=false;
		if (edge.o1==o1 && 
			edge.o2==o2)
		{
			shared=true;
		}

		if (edge.o1==o2 && 
			edge.o2==o1)
		{
			shared=true;
		}

		if (shared)
		{
			edge.col^=col;
			if (edge.col==0)
			{
				drawedges.erase(iter);
			}
			return;
		}
		++iter;
	}

	drawedges.push_back(Edge(o1, o2, col));
}

void VectorizerWire::Clip( Line& line, Poly* poly, Lines& out_lines )
{
	bool inside1=IsInside(line.p1, poly, -0.1f);
	bool inside2=IsInside(line.p2, poly, -0.1f);

	if (inside1 && inside2)
	{
		return;
	}

	std::vector<Vector3> cutpoints;

	Vector3 cutpoint;

	for (int j=0 ; j<poly->numids ; j++)
	{
		int j2=(j+1) % poly->numids;
		
		Vector3& p3=poly->vertices[j ];
		Vector3& p4=poly->vertices[j2];
		
		if (Clip(line.p1, line.p2, p3, p4, cutpoint))
		{
			bool found=false;
			for (int i=0 ; i<(int)(cutpoints.size()) ; i++)
			{
				Vector3 delta(cutpoints[i]-cutpoint);
				if (delta.ScalarSquared()<1.0f)
				{
					found=true;
					break;
				}
			}
			if (!found)
			{
				cutpoints.push_back(cutpoint);
			}
		}
	}

	int cutcount=cutpoints.size();

	for (int i=0 ; i<cutcount ; i++)
	{
		for (int j=0 ; j<i ; j++)
		{
			float t1=(cutpoints[i]-line.p1).ScalarSquared();
			float t2=(cutpoints[j]-line.p1).ScalarSquared();
			if (t2>t1)
			{
				Swap(cutpoints[i], cutpoints[j]);
			}
		}
	}

	if (inside1)
	{
		if (inside2)
		{
			return;
		}
		else
		{
			if (cutcount>0)
			{
				AddLine(out_lines, cutpoints[cutcount-1], line.p2, line.col);
			}
			else
			{
				AddLine(out_lines, line.p1, line.p2, line.col);
			}
		}
	}
	else
	{
		if (inside2)
		{
			if (cutcount>0)
			{
				AddLine(out_lines, line.p1, cutpoints[0], line.col);
			}
			else
			{
				AddLine(out_lines, line.p1, line.p2, line.col);
			}
		}
		else
		{
			if (cutcount>0)
			{
				AddLine(out_lines, line.p1, cutpoints[0], line.col);
				AddLine(out_lines, cutpoints[cutcount-1], line.p2, line.col);
			}
			else
			{
				AddLine(out_lines, line.p1, line.p2, line.col);
			}
		}
	}
}

void VectorizerWire::AddLine( Lines& lines, Vector3& p1, Vector3& p2, int col )
{
	Vector3 delta(p2-p1);

	if (delta.ScalarSquared()<1.0f)
	{
		return;
	}

	lines.push_back(Line(p1, p2, col));
}

bool VectorizerWire::Clip( Vector3& p1, Vector3& p2, Vector3& p3, Vector3& p4, Vector3& out_cut, float epsilon )
{
	Vector3 delta1(p2-p1);
	Vector3 delta2(p4-p3);
	Vector3 delta3(p3-p1);
	Vector3 delta4(p4-p2);
	Vector3 delta5(p3-p2);
	Vector3 delta6(p4-p1);

	delta1.z=0.0f;
	delta2.z=0.0f;
	delta3.z=0.0f;
	delta4.z=0.0f;
	delta5.z=0.0f;
	delta6.z=0.0f;
	
	float len1=delta1.ScalarSquared();
	float len2=delta2.ScalarSquared();
	float len3=delta3.ScalarSquared();
	float len4=delta4.ScalarSquared();
	float len5=delta5.ScalarSquared();
	float len6=delta6.ScalarSquared();
	if (len1<0.01f || 
		len2<0.01f)
	{
//		return false;
	}

	float smallx=Min(OxyFabs(delta1.x), OxyFabs(delta2.x));
	float smally=Min(OxyFabs(delta1.y), OxyFabs(delta2.y));

	float mint=epsilon;
	float maxt=1.0f-epsilon;

	if (smallx<smally)
	{
		float m1=delta1.x/delta1.y;
		float m2=delta2.x/delta2.y;
		float b1=p1.x-p1.y*m1;
		float b2=p3.x-p3.y*m2;

		float cuty=(b2-b1)/(m1-m2);
		float cutx=m1*cuty+b1;

		float t1=(cuty-p1.y)/delta1.y;
		float t2=(cuty-p3.y)/delta2.y;

		if (t1>=mint && t1<=maxt &&
			t2>=mint && t2<=maxt)
		{
			out_cut.Set(cutx, cuty, 0.0f);
			return true;
		}
	}
	else
	{
		float m1=delta1.y/delta1.x;
		float m2=delta2.y/delta2.x;
		float b1=p1.y-p1.x*m1;
		float b2=p3.y-p3.x*m2;

		float cutx=(b2-b1)/(m1-m2);
		float cuty=m1*cutx+b1;

		float t1=(cutx-p1.x)/delta1.x;
		float t2=(cutx-p3.x)/delta2.x;

		if (t1>=mint && t1<=maxt &&
			t2>=mint && t2<=maxt)
		{
			out_cut.Set(cutx, cuty, 0.0f);
			return true;
		}
	}
	return false;
}

bool VectorizerWire::IsInside( Vector3& point, Poly* poly, float epsilon )
{
	for (int j=0 ; j<poly->numids ; j++)
	{
		int j2=(j+1) % poly->numids;

		Vector3& p3=poly->vertices[j ];
		Vector3& p4=poly->vertices[j2];

		Plane plane(p3, p4, p4+Vector3(0.0f, 0.0f, 1.0f));
		if (plane.GetDistance(point)<epsilon)
		{
			return false;
		}
	}

	return true;
}

bool VectorizerWire::IsInside( Vector2& point, ClipPoly& poly, float epsilon )
{
	Vector3 point3(point.x, point.y, 0.0f);

	for (int j=0 ; j<poly.numpoints ; j++)
	{
		int j2=(j+1) % poly.numpoints;

		Vector2& p1=poly.points[j ];
		Vector2& p2=poly.points[j2];

		Vector3 p13(p1.x, p1.y, 0.0f);
		Vector3 p23(p2.x, p2.y, 0.0f);

		Plane plane(p13, p23, p23+Vector3(0.0f, 0.0f, 1.0f));
		if (plane.GetDistance(point3)>epsilon)
		{
			return false;
		}
	}

	return true;
}

bool VectorizerWire::IsCovered( ClipPoly& clippoly, Poly* poly )
{
	int numclippoints=clippoly.numpoints;

	for (int i=0 ; i<numclippoints ; i++)
	{
		Vector2& p1=clippoly.points[i];
		Vector3 p2(p1.x, p1.y, 0.0f);

		if (!IsInside(p2, poly, -0.001f))
		{
			return false;
		}
	}
	return true;
}		

bool VectorizerWire::ClipScreen( Line& line )
{
	if (!ClipValueMin(line.p1.x, line.p1.y, line.p2.x, line.p2.y, minx))
	{
		return false;
	}
	
	if (!ClipValueMin(line.p1.y, line.p1.x, line.p2.y, line.p2.x, miny))
	{
		return false;
	}

	if (!ClipValueMax(line.p1.x, line.p1.y, line.p2.x, line.p2.y, maxx))
	{
		return false;
	}

	if (!ClipValueMax(line.p1.y, line.p1.x, line.p2.y, line.p2.x, maxy))
	{
		return false;
	}

	return true;
}

void VectorizerWire::ClipScreenFill( Point& p1, Point& p2, Lines& out_lines )
{	
#ifdef WIRE_AMIGA
	//if (!ClipValueMax(p1.x, p1.y, p2.x, p2.y, maxx))
	//	return;

	if (!ClipValueMax(p1.y, p1.x, p2.y, p2.x, maxy))
		return;

	//if (!ClipValueMin(p1.x, p1.y, p2.x, p2.y, minx))
	//	return;

	if (!ClipValueMin(p1.y, p1.x, p2.y, p2.x, miny))
		return;

	ClipValueMinBorderX(p1.x, p1.y, p2.x, p2.y, minx, out_lines);
	ClipValueMaxBorderX(p1.x, p1.y, p2.x, p2.y, maxx, out_lines);

	out_lines.push_back(Line(Vector3(p1.x, p1.y, 0.0f), Vector3(p2.x, p2.y, 0.0f)));

#else // WIRE_AMIGA
	if (!ClipValueMax(p1.x, p1.y, p2.x, p2.y, maxx))
		return;

	if (!ClipValueMax(p1.y, p1.x, p2.y, p2.x, maxy))
		return;

	if (!ClipValueMin(p1.x, p1.y, p2.x, p2.y, minx))
		return;

	ClipValueMinBorderY(p1.x, p1.y, p2.x, p2.y, miny, out_lines, 0);
#endif // WIRE_AMIGA
}

void VectorizerWire::ClipValueMinBorderX( float& x1, float& y1, float& x2, float& y2, float minx, Lines& out_lines, int col )
{
	if (x1<minx && x2<minx)
	{
		x1=minx;
		x2=minx;

		return;
	}

	if (x1<minx)
	{
		float y3=y1+(y2-y1)*(minx-x1)/(x2-x1);

		out_lines.push_back(Line(Vector3(minx, y1, 0.0f), Vector3(minx, y3, 0.0f), col));
		
		x1=minx;
		y1=y3;

		return;
	}
	
	if (x2<minx)
	{
		float y3=y2+(y1-y2)*(minx-x2)/(x1-x2);

		out_lines.push_back(Line(Vector3(minx, y2, 0.0f), Vector3(minx, y3, 0.0f), col));
		
		x2=minx;
		y2=y3;

		return;
	}
}

void VectorizerWire::ClipValueMinBorderY( float& x1, float& y1, float& x2, float& y2, float miny, Lines& out_lines, int col )
{
	if (y1<miny && y2<miny)
	{	
		y1=miny;
		y2=miny;
	
		return;
	}

	if (y1<miny)
	{
		float x3=x1+(x2-x1)*(miny-y1)/(y2-y1);

		out_lines.push_back(Line(Vector3(x1, miny, 0.0f), Vector3(x3, miny, 0.0f), col));

		y1=miny;
		x1=x3;

		return;
	}
	
	if (y2<miny)
	{
		float x3=x2+(x1-x2)*(miny-y2)/(y1-y2);

		out_lines.push_back(Line(Vector3(x2, miny, 0.0f), Vector3(x3, miny, 0.0f), col));

		y2=miny;
		x2=x3;

		return;
	}
}

void VectorizerWire::ClipValueMaxBorderX( float& x1, float& y1, float& x2, float& y2, float maxx, Lines& out_lines, int col )
{
	if (x1>maxx && x2>maxx)
	{
		x1=maxx;
		x2=maxx;
	
		return;
	}

	if (x1>maxx)
	{
		float y3=y1+(y2-y1)*(maxx-x1)/(x2-x1);

		out_lines.push_back(Line(Vector3(maxx, y1, 0.0f), Vector3(maxx, y3, 0.0f), col));

		x1=maxx;
		y1=y3;

		return;
	}
	
	if (x2>maxx)
	{
		float y3=y2+(y1-y2)*(maxx-x2)/(x1-x2);

		out_lines.push_back(Line(Vector3(maxx, y2, 0.0f), Vector3(maxx, y3, 0.0f), col));

		x2=maxx;
		y2=y3;

		return;
	}
}

void VectorizerWire::ClipValueMaxBorderY( float& x1, float& y1, float& x2, float& y2, float maxy, Lines& out_lines, int col )
{
	if (y1>maxy && y2>maxy)
	{
		y1=maxy;
		y2=maxy;
	
		return;
	}

	if (y1>maxy)
	{
		float x3=x1+(x2-x1)*(maxy-y1)/(y2-y1);

		out_lines.push_back(Line(Vector3(x1, maxy, 0.0f), Vector3(x3, maxy, 0.0f), col));

		y1=maxy;
		x1=x3;

		return;
	}
	
	if (y2>maxy)
	{
		float x3=x2+(x1-x2)*(maxy-y2)/(y1-y2);

		out_lines.push_back(Line(Vector3(x2, maxy, 0.0f), Vector3(x3, maxy, 0.0f), col));

		y2=maxy;
		x2=x3;

		return;
	}
}

bool VectorizerWire::ClipValueMin( float& x1, float& y1, float& x2, float& y2, float minx )
{
	if (x1<minx && x2<minx)
	{
		return false;
	}

	if (x1<minx)
	{
		y1=y1+(y2-y1)*(minx-x1)/(x2-x1);
		x1=minx;
	}
	
	if (x2<minx)
	{
		y2=y2+(y1-y2)*(minx-x2)/(x1-x2);
		x2=minx;
	}
	return true;
}

bool VectorizerWire::ClipValueMax( float& x1, float& y1, float& x2, float& y2, float maxx )
{
	if (x1>maxx && x2>maxx)
	{
		return false;
	}

	if (x1>maxx)
	{
		y1=y1+(y2-y1)*(maxx-x1)/(x2-x1);
		x1=maxx;
	}
	
	if (x2>maxx)
	{
		y2=y2+(y1-y2)*(maxx-x2)/(x1-x2);
		x2=maxx;
	}
	return true;
}

void VectorizerWire::UpdatePolyBounds( Poly* poly )
{
	int numpoints=poly->numids;
	if (numpoints>0)
	{
		poly->center.Clear();
		for (int i=0 ; i<numpoints ; i++)
		{
			poly->center+=poly->vertices[i];
		}
		poly->center/=(float)(numpoints);
		
		poly->radius=0.0f;
		for (int i=0 ; i<numpoints ; i++)
		{
			Vector3 delta(poly->vertices[i]-poly->center);
			poly->radius=Max(poly->radius, delta.Scalar());
		}
	}
}

bool VectorizerWire::CheckPolyBounds( Poly* poly, Vector3& point )
{
	float dx=point.x-poly->center.x;
	float dy=point.y-poly->center.y;
	float d=dx*dx+dy*dy;
	if (d>(poly->radius*poly->radius))
	{
		return false;
	}
	return true;
}
		
void VectorizerWire::UpdateClipPolyBounds( ClipPoly& poly )
{
	int numpoints=poly.numpoints;
	if (numpoints>0)
	{
		poly.center.x=0.0f;
		poly.center.y=0.0f;
		for (int i=0 ; i<numpoints ; i++)
		{
			poly.center+=poly.points[i];
		}
		poly.center.x/=(float)(numpoints);
		poly.center.y/=(float)(numpoints);
		
		poly.radius=0.0f;
		for (int i=0 ; i<numpoints ; i++)
		{
			Vector2 delta(poly.points[i]-poly.center);
			poly.radius=Max(poly.radius, delta.Scalar());
		}
	}
}
		
bool VectorizerWire::CheckClipPolyBounds( ClipPoly& poly2, Poly* poly )
{
	float dx=poly2.center.x-poly->center.x;
	float dy=poly2.center.y-poly->center.y;
	float d=dx*dx+dy*dy;
	float rad=poly->radius+poly2.radius;
	if (d>(rad*rad))
	{
		return false;
	}
	return true;
}

bool VectorizerWire::CheckClipPolyBounds( ClipPoly& poly2, Vector3& point )
{
	float dx=point.x-poly2.center.x;
	float dy=point.y-poly2.center.y;
	float d=dx*dx+dy*dy;
	float rad=poly2.radius;
	if (d>(rad*rad))
	{
		return false;
	}
	return true;
}

void VectorizerWire::Fill( void )
{
	int x,y;
	unsigned char co;
	
#ifdef WIRE_AMIGA
	co=0;
	for (y=(int)(miny) ; y<(int)(maxy) ; y++)
	{
		for (x=(int)(minx) ; x<=(int)(maxx) ; x++)
		{
			co^=pixelbuffer[y][x];
			pixelbuffer[y][x]=co;
			gfx->Plot(x,y,pal[co]);
		}
	}
#else // WIRE_AMIGA
	for (x=(int)(minx) ; x<(int)(maxx) ; x++)
	{
		co=0;
		for (y=(int)(miny) ; y<(int)(maxy) ; y++)
		{
			co^=pixelbuffer[y][x];
			pixelbuffer[y][x]=co;
			gfx->Plot(x,y,pal[co]);
		}
	}
#endif // WIRE_AMIGA
}

void VectorizerWire::AddVertex( float x, float y, float z, bool transform )
{
	vertices.push_back(new Vertex(Vector3(x, y, z), transform));
}

void VectorizerWire::AddPoly( int id1, int id2, int id3, unsigned char col, bool cull )
{
	int ids[] = { id1, id2, id3 };

	polys.push_back(new Poly(3, ids, col, cull));
}

void VectorizerWire::AddPoly( int id1, int id2, int id3, int id4, unsigned char col, bool cull )
{
	int ids[] = { id1, id2, id3, id4 };

	polys.push_back(new Poly(4, ids, col, cull));
}

bool VectorizerWire::AddMesh( const char* filename, const char* materialfile, float scale, float rx, float ry, float rz, Vector3& offset, bool swapwind )
{
	char line[1024];
	int len;
	int veccount;
	char va1,va2,va;
	char whitespaces[] = { ' ', '\t', '\r', '\n' };

	std::string matname;
	float diffuse[3];
	
	FileR* filer=new FileR(materialfile);

	typedef std::map<std::string, unsigned char> Materials;

	Materials materials;

	unsigned char count=0;

	while(true)	
	{
		if (!filer->ReadLine(line, 1024))
		{
			break;
		}

		len=strlen(line);
		if (len>0)
		{
			if (!strncmp(line,"newmtl ", 7))
			{
				matname=line+7;
			}

			if (!strncmp(line,"Kd ", 3))
			{
				veccount=0;
				for (int ipos=2 ; ipos<len ; ipos++)
				{
					va=line[ipos];
					for (int iwhitespace=0 ; iwhitespace<4 ; iwhitespace++)
					{
						if (va==whitespaces[iwhitespace])
						{
							if (veccount<3)
							{
								diffuse[veccount++]=(float)atof(&line[ipos+1]);
							}
						}
					}
				}

				if (veccount>=3)
				{					
					int r=(int)(diffuse[0]*255.0f);
					int g=(int)(diffuse[1]*255.0f);
					int b=(int)(diffuse[2]*255.0f);

					Clamp(r, 0, 255);
					Clamp(g, 0, 255);
					Clamp(b, 0, 255);

					pal[count]=(r<<16) | (g<<8) | (b);

					materials[matname]=count;

					count++;
				}
			}
		}
	}
	delete filer;


	Matrix3x4 matrix;

	matrix.Unit();
	matrix.Scale(Vector3(scale, scale, scale));
	matrix.RotateXYZ(Vector3(rx, ry, rz));
	matrix.Translate(offset);

	filer=new FileR(filename);

	float pos[3];
	int idxs[128];
	unsigned char col=0;

	int basevertex=vertices.size();

	while(true)	
	{
		if (!filer->ReadLine(line, 1024))
		{
			break;
		}

		len=strlen(line);
		if (len>0)
		{
			if (!strncmp(line,"usemtl ", 7))
			{
				matname=line+7;
				if (materials.find(matname)!=materials.end())
				{
					col=materials[matname];
				}
			}

			if (!strncmp( line,"v ", 2 ))
			{
				veccount=0;
				for (int ipos=1 ; ipos<len ; ipos++)
				{
					va1=line[ipos-1];
					va2=line[ipos];
					for (int iwhitespace=0 ; iwhitespace<4 ; iwhitespace++)
					{
						if (va1!=whitespaces[iwhitespace] && va2==whitespaces[iwhitespace])
						{
							if (veccount<3)
							{
								pos[veccount++]=(float)(atof(&line[ipos+1]));
							}
						}
					}
				}

				if (veccount>=3)
				{
					Vector3 vec(pos[0], pos[1], pos[2]);

					vec.MultiplyMatrix(matrix);
					
					AddVertex(vec.x, -vec.y, vec.z, true);
				}
			}

			if (!strncmp(line,"f ", 2))
			{
				veccount=0;
				for (int ipos=1 ; ipos<len ; ipos++)
				{
					va=line[ipos];
					for (int iwhitespace=0 ; iwhitespace<4 ; iwhitespace++)
					{
						if (va== whitespaces[iwhitespace])
						{
							if (veccount<128)
							{
								unsigned char va2=line[ipos+1];
								if (va2=='-' || (va2>='0' && va2<='9'))
								{
									idxs[veccount++]=atoi(&line[ipos+1]);
									if (idxs[veccount-1]==0)
										int huhu=1;
								}
							}
						}
					}
				}

				if (veccount>=2)
				{
					Poly* poly=new Poly();

					poly->cull=true;
					if (veccount<3)
						poly->cull=false;

					poly->col=col;
				
					poly->numids=veccount;

					for (int i=0 ; i<veccount ; i++)
					{
						if (swapwind)
							poly->ids[i]=idxs[veccount-(i+1)]+basevertex-1;
						else
							poly->ids[i]=idxs[i]+basevertex-1;
					
						poly->vertices[i].Clear();
					}

					poly->center.Clear();
					poly->radius=0.0f;
					poly->draw=true;

					polys.push_back(poly);
				}
			}
		}
	};

	Vector3 vmin( 99999.0f,  999999.0f,  999999.0f);
	Vector3 vmax(-99999.0f, -999999.0f, -999999.0f);

	int numvertices=vertices.size();
	for (int i=0 ; i<numvertices ; i++)
	{
		Vertex* vertex=vertices[i];
		vmin.x=Min(vmin.x, vertex->pos.x);
		vmin.y=Min(vmin.y, vertex->pos.y);
		vmin.z=Min(vmin.z, vertex->pos.z);

		vmax.x=Max(vmax.x, vertex->pos.x);
		vmax.y=Max(vmax.y, vertex->pos.y);
		vmax.z=Max(vmax.z, vertex->pos.z);
	}

	Vector3 vcenter=(vmin+vmax)*0.5f;

	int huhu=1;


/*
	// add custom clipplanes for logo
	basevertex=vertices.size();

	AddVertex( 63.0f, 159.0f, nearplane*2.0f, false);
	AddVertex(320.0f, 159.0f, nearplane*2.0f, false);
	AddVertex(320.0f, 200.0f, nearplane*2.0f, false);
	AddVertex( 63.0f, 200.0f, nearplane*2.0f, false);
	
	Poly* poly=new Poly();
	poly->cull=false;
	poly->col=1;
	poly->numids=4;
	poly->ids[0]=basevertex+0;
	poly->ids[1]=basevertex+1;
	poly->ids[2]=basevertex+2;
	poly->ids[3]=basevertex+3;
	poly->center.Clear();
	poly->radius=0.0f;
	poly->draw=false;
	
	polys.push_back(poly);
	
	
	AddVertex(127.0f, 151.0f, nearplane*2.0f, false);
	AddVertex(136.0f, 151.0f, nearplane*2.0f, false);
	AddVertex(136.0f, 160.0f, nearplane*2.0f, false);
	AddVertex(127.0f, 160.0f, nearplane*2.0f, false);
	
	poly=new Poly();
	poly->cull=false;
	poly->col=1;
	poly->numids=4;
	poly->ids[0]=basevertex+4;
	poly->ids[1]=basevertex+5;
	poly->ids[2]=basevertex+6;
	poly->ids[3]=basevertex+7;
	poly->center.Clear();
	poly->radius=0.0f;
	poly->draw=false;
	
	polys.push_back(poly);
*/

	delete filer;

	return true;
}

void VectorizerWire::ClipPoly::Reverse( void )
{
	for (int i=0 ; i<(numpoints)/2 ; i++)
	{
		int i2=numpoints-(i+1);
		Swap(points[i], points[i2]);
	}
}

void VectorizerWire::DrawClipPoly( ClipPoly& poly, int offx, int offy )
{
	int numpoints=poly.numpoints;

	char text[256];

	for (int i=0 ; i<numpoints ; i++)
	{
		int i2=(i+1) % numpoints;
		Vector2& p1=poly.points[i ];
		Vector2& p2=poly.points[i2];

		gfx->Line(p1.x+offx, p1.y+offy, p2.x+offx, p2.y+offy, pal[poly.col]);

		sprintf(text, "%d", i);

		Label((int)(p1.x+2+offx), (int)(p1.y+2+offy), text, 1);
	}
}

void VectorizerWire::AddResultLine( int x1, int y1, int x2, int y2, int col )
{
	if (x1<0 || y1<0 || x2<0 || y2<0 || 
		x1>=320 || y1>=320 || x2>=320 || y2>=320)
	{
		return;
	}

#ifdef WIRE_FAKERS_LINIEN_STINKEN
	if (y1>y2)
	{
		Swap(x1, x2);		
		Swap(y1, y2);		
	}
#endif

	static int maxd=0;

	int dx=abs(x2-x1);
	int dy=abs(y2-y1);

	if (dx<2 && dy<2)
	{
		return;
	}

	maxd=Max(maxd, dx);
	maxd=Max(maxd, dy);

	ResultLine line;

	line.x1=x1;
	line.y1=y1;
	line.x2=x2;
	line.y2=y2;
	line.col=col;

	resultlines.push_back(line);
}

unsigned char VectorizerWire::GetHiBit( int val )
{
#ifdef WIRE_RESORT_BITS
	return val & 0x01;
#else
	return val>>8;
#endif
}

unsigned char VectorizerWire::GetLowByte( int val )
{
#ifdef WIRE_RESORT_BITS
	return val>>1;
#else
	return val & 0xff;
#endif
}

int VectorizerWire::FetchHiBit( unsigned char val )
{
#ifdef WIRE_RESORT_BITS
	return (int)(val & 0x80)>>7;
#else
	return (int)(val & 0x80)<<1;
#endif
}

int VectorizerWire::FetchLowByte( unsigned char val )
{
#ifdef WIRE_RESORT_BITS
	return (int)(val)<<1;
#else
	return val & 0xff;
#endif
}

void VectorizerWire::BuildResultData( void )
{
	if (frame<maxframes)
	{
		int numlines=resultlines.size();
		if (numlines==0)
		{
			return;
		}

		ResultLine lastline;

		lastline.x1=-1;
		lastline.y1=-1;
		lastline.x2=-1;
		lastline.y2=-1;

		for (int i=0 ; i<numlines ; i++)
		{
			ResultLine& line=resultlines[i];

			if (!line.Point1Shared(lastline) &&
				!line.Point2Shared(lastline))
			{
				for (int j=i+1 ; j<numlines ; j++)
				{
					ResultLine& line2=resultlines[j];

					if (line2.Point1Shared(lastline) ||
						line2.Point2Shared(lastline))
					{
						Swap(resultlines[i], resultlines[j]);
						break;
					}
				}
			}
			lastline=resultlines[i];
		}

		lastline.x1=-1;
		lastline.y1=-1;
		lastline.x2=-1;
		lastline.y2=-1;

		int lastgap=0;
		unsigned char hibits=0;
		int numhibits=0;

#ifdef WIRE_EXPORT_LINECOLORS
		static int oldcol=-1;
		lastgap=1;
#endif

		for (int i=0 ; i<numlines ; i++)
		{
			ResultLine& line=resultlines[i];

			if (datapoi<=0x1fff0)
			{
#ifdef WIRE_EXPORT_LINECOLORS
				if (line.col!=oldcol)
				{
					data[datapoi++]=0xd0+line.col;
					oldcol=line.col;
				}
#endif
				if (line.Point1Shared(lastline))
				{
					data[datapoi++]=0xc8;
					data[datapoi++]=line.y2;
					data[datapoi++]=GetLowByte(line.x2);
					if (numhibits==0)
					{
						lastgap=datapoi++;
					}

					hibits<<=1;
					hibits|=GetHiBit(line.x2);
					numhibits++;
					if (numhibits==8)
					{
						data[lastgap]=hibits;
						hibits=0;
						numhibits=0;
					}

					lastline=line;
					continue;
				}

				if (line.Point2Shared(lastline))
				{
					data[datapoi++]=0xc9;
					data[datapoi++]=line.y1;
					data[datapoi++]=GetLowByte(line.x1);
					if (numhibits==0)
					{
						lastgap=datapoi++;
					}

					hibits<<=1;
					hibits|=GetHiBit(line.x1);
					numhibits++;
					if (numhibits==8)
					{
						data[lastgap]=hibits;
						hibits=0;
						numhibits=0;
					}

					lastline=line;
					continue;
				}

				data[datapoi++]=line.y1;
				data[datapoi++]=GetLowByte(line.x1);
				if (numhibits==0)
				{
					lastgap=datapoi++;
				}

				hibits<<=1;
				hibits|=GetHiBit(line.x1);
				numhibits++;
				if (numhibits==8)
				{
					data[lastgap]=hibits;
					hibits=0;
					numhibits=0;
				}

				data[datapoi++]=line.y2;
				data[datapoi++]=GetLowByte(line.x2);
				if (numhibits==0)
				{
					lastgap=datapoi++;
				}

				hibits<<=1;
				hibits|=GetHiBit(line.x2);
				numhibits++;
				if (numhibits==8)
				{
					data[lastgap]=hibits;
					hibits=0;
					numhibits=0;
				}

				lastline=line;
			}
		}

		if (numhibits!=0)
		{
			data[lastgap]=hibits<<(8-numhibits);
		}
	}
}

void VectorizerWire::ShowResultData( void )
{
	static int poi=0;
	int val;
	int x1=-1,
		x2=-1,
		y1=-1,
		y2=-1;
	
	unsigned char hibits=0;
	int numhibits=8;

	static int col=0x01;

	while(poi<datapoi)
	{
		val=data[poi++];
		if (val==0xff)
			break;

		if (val>=0xd0 && val<=0xdf)
		{
			col=val-0xd0;
			continue;
		}

		if (val==0xc8)
		{	
			y2=data[poi++];
			x2=FetchLowByte(data[poi++]);
			if (numhibits==8)
			{
				hibits=data[poi++];
				numhibits=0;
			}
			x2|=FetchHiBit(hibits);
			hibits<<=1;
			numhibits++;
			
			gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), GetColor(col));
			continue;
		}

		if (val==0xc9)
		{
			y1=data[poi++];
			x1=FetchLowByte(data[poi++]);
			if (numhibits==8)
			{
				hibits=data[poi++];
				numhibits=0;
			}
			x1|=FetchHiBit(hibits);
			hibits<<=1;
			numhibits++;
			
			gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), GetColor(col));
			continue;
		}

		y1=val;
		x1=FetchLowByte(data[poi++]);			
		if (numhibits==8)
		{
			hibits=data[poi++];
			numhibits=0;
		}
		x1|=FetchHiBit(hibits);
		hibits<<=1;
		numhibits++;
		
		y2=data[poi++];
		x2=FetchLowByte(data[poi++]);
		if (numhibits==8)
		{
			hibits=data[poi++];
			numhibits=0;
		}
		x2|=FetchHiBit(hibits);
		hibits<<=1;
		numhibits++;
		
		gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), GetColor(col));

		numlines++;
	}
}

void VectorizerWire::DoLineScreen( int x1, int y1, int x2, int y2 )
{
	gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), 0xffffff);
	//LineOverDraw((float)(x1), (float)(y1), (float)(x2), (float)(y2));
}

void VectorizerWire::DoLineFill( int x1, int y1, int x2, int y2, unsigned char col )
{
#ifdef WIRE_AMIGA
	int dx,dy,m,x,y;

	dy=y2-y1;
	if(dy==0)
		return;

	if(dy<0)
	{
		Swap(x1, x2);
		Swap(y1, y2);
	}

	dx=x2-x1;
	m=(dx<<16)/abs(dy);
	
	x=x1<<16;

	for (y=y1 ; y<y2 ; y++)
	{
		FillerBase::DoPixel(x>>16, y, col, false);
		x+=m;
	}
#else // WIRE_AMIGA
	FillerBase::DoLine(x1, y1, x2, y2, col, false);
#endif // WIRE_AMIGA
}

void VectorizerWire::LineOverDraw( float x1, float y1, float x2, float y2 )
{
	unsigned int	*buffer2;
	int				intx1,intx2,inty1,inty2,x,y;
	float			x3,y3,dx,dy,dxstep,dystep,subpx,subpy;
	
	unsigned int *buffer=gfx->GetBuffer();
	
	int xsize=gfx->GetXSize();

	dx=x2-x1;
	dy=y2-y1;
	if (fabs(dy)>fabs(dx))
	{
		dxstep=dx/dy;
		if (y1>y2)
		{
			x3=x1;
			x1=x2;
			x2=x3;
			y3=y1;
			y1=y2;
			y2=y3;
		}
		
		subpy=1.0f-(float)(y1-int(y1));

		x1+=subpy*dxstep;
	
		inty1=(int)(y1);
		inty2=(int)(y2);
		
		if (inty1==inty2)
			return;
		
		buffer2=buffer+inty1*xsize;
		for (y=inty1 ; y<inty2 ; y++)
		{
			intx1=(int)(x1);
			buffer2[intx1]+=0x404040;

			buffer2+=xsize;
			x1+=dxstep;
		}
	}
	else
	{
		dystep=dy/dx;
		if (x1>x2)
		{
			x3=x1;
			x1=x2;
			x2=x3;
			y3=y1;
			y1=y2;
			y2=y3;
		}
		
		if (x1<0)
		{
			subpx=1.0f-x1;
			x1=0.0f;
		}
		else
			subpx=1.0f-(float)(x1-int(x1));
	
		y1+=subpx*dystep;
	
		intx1=(int)(x1);
		intx2=(int)(x2);
		if (intx2>=xsize)
			intx2=xsize-1;
	
		if (intx1==intx2)
			return;

		buffer2=buffer+intx1;
		for (x=intx1 ; x<intx2 ; x++)
		{
			inty1=(int)(y1);
			buffer2[inty1*xsize]+=0x404040;

			buffer2++;
			y1+=dystep;
		}
	}
}

#include "include.h"

/*
	TODO:	- use nicer objects
*/

#define VECTORIZER_AMIGA
//#define VECTORIZER_FAKERS_LINIEN_STINKEN

#define VECTORIZER_SHOWSHIP

#define TUNNELSEG_SCALE 1.0f

DEFINE_CLASS(Vectorizer,Effect);
		
Vectorizer::Vectorizer()
{
	//camrx=0.0f+15.0f*DegtoRad;
	//camry=0.0f+45.0f*DegtoRad;
	//camrz=0.0f;
	//campos.Set(0.0f, 0.0f, 0.0f);

	camrx=0.0f;
	camry=-90.0f*DegtoRad;
	camrz=0.0f;
	campos.Set(23.0f, 0.0f, 0.0f);

	maxframes=448;
	au=300.0f;
	centerx=184.0f;
	centery= 85.0f;
	minx=  0.0f;
	maxx=367.0f;
	miny=  0.0f;
	maxy=169.0f;
	nearplane=0.1f;

#ifdef VECTORIZER_AMIGA
	//centery=128.0f;
	//maxy=255.0f;
#endif
	
	palsize=0;
	memset(pal, 0, sizeof(pal));

	numlines=0;
	datapoi=0;
	memset(data, 0, sizeof(data));
}

Vectorizer::~Vectorizer()
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

	FileW* filew=new FileW("Data/Parts/Vectorizer/lines.dat");
	filew->Write(data, 1, datapoi);
	delete filew;

	unsigned char amipal[256][2];

	for (int i=0 ; i<palsize ; i++)
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

	filew=new FileW("Data/Parts/Vectorizer/pal.dat");
	filew->Write(amipal, 1, palsize*2);
	delete filew;
}

void Vectorizer::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);
	
	vertices.clear();
	polys.clear();

#ifndef VECTORIZER_SHOWSHIP
	for (int i=0 ; i<12 ; i++)
	{
		float y=(float)(i*4.0f*15.0f/TUNNELSEG_SCALE);
		
		AddMesh("Data/Parts/Vectorizer/tunneltmp.obj", "Data/Parts/Vectorizer/tunneltmp.mtl", 15.0f, 0.0f, 0.0f, 0.0f, Vector3(0.0f, y, 0.0f), false, true);
	}
#else
	AddMesh("Data/Parts/Vectorizer/sat.obj", "Data/Parts/Vectorizer/sat.mtl", 6.0f, pi*0.3f, pi*0.5f, pi*0.5f, Vector3(0.0f, 0.0f, 0.0f));
#endif
}

void Vectorizer::Update( float _rendertime )
{
	gfx->Clear(0);

#ifdef VECTORIZER_AMIGA
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
		FillRect(0, 0, 368, 256, 0);

		drawedges.clear();
		drawpoints.clear();
	}
	else
	{
		resultlines.clear();
	}

	ShowObject(_rendertime, filled);

	if (filled)
	{
		Lines lines;
	
		int numedges=drawedges.size();
		int numpoints=drawpoints.size();
	
		struct DstLine
		{
			int xy1, xy2;
			unsigned char co;

			DstLine(int xy1, int xy2, unsigned char co)
			{
				this->xy1=xy1;
				this->xy2=xy2;
				this->co=co;
			}
		};

		std::set<int> dstpoints;
		std::vector<DstLine> dstlines;

		for (int i=0 ; i<numedges ; i++)
		{
			Edge& edge=drawedges[i];

			if (edge.col!=0)
			{
				Point p1=drawpoints[edge.o1];
				Point p2=drawpoints[edge.o2];

				lines.clear();

				ClipScreenFill(p1, p2, lines);
				
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
						if (ix1>ix2)
						{
							Swap(ix1, ix2);
							Swap(iy1, iy2);
						}
						
						int xy1=ix1+(iy1<<16);
						int xy2=ix2+(iy2<<16);
						dstpoints.insert(xy1);
						dstpoints.insert(xy2);

						dstlines.push_back(DstLine(xy1, xy2, edge.col));

						DoLineFill(ix1, iy1, ix2, iy2, edge.col);

						this->numlines++;

						gfx->Line(p1.x+320, p1.y, p2.x+320, p2.y, 0xffffff);
					}
				}
			}
		}

		static int maxpoints=0;
		static int framesize1=0;
		static int framesize2=0;

		int numdstpoints=dstpoints.size();
		int numdstlines=dstlines.size();

		maxpoints=Max(maxpoints, numdstpoints);

		framesize1+=numdstlines*37;
		framesize2+=numdstlines*15;
		framesize2+=numdstpoints*17;

		if (frame<maxframes && datapoi<=0x3fff9)
		{
			std::set<int>::iterator iter=dstpoints.begin();
			int i=7;
			unsigned char hixs=0;
			int lasthixpoi=-1;

			data[datapoi++]=numdstpoints;

			while(iter!=dstpoints.end())
			{
				int xy=*iter;
				int x=xy & 0x1ff;
				int y=xy>>16;
			
				i++;
				if (i==8)
				{
					if (lasthixpoi!=-1)
						data[lasthixpoi]=hixs;

					lasthixpoi=datapoi;
					datapoi++;
					hixs=0;
					i=0;
				}

				hixs<<=1;
				hixs|=x & 1;

				data[datapoi++]=x>>1;
				data[datapoi++]=y;
		
				++iter;
			}

			if (lasthixpoi!=-1)
			{
				hixs<<=(7-i);
				data[lasthixpoi]=hixs;
			}

			data[datapoi++]=numdstlines;

			for (int i=0 ; i<numdstlines ; i++)
			{
				DstLine& dstline=dstlines[i];
	
				int o1=std::distance(dstpoints.begin(), dstpoints.find(dstline.xy1));
				int o2=std::distance(dstpoints.begin(), dstpoints.find(dstline.xy2));
				
				data[datapoi++]=o1 | (( dstline.co     & 3)<<6);
				data[datapoi++]=o2 | (((dstline.co>>2) & 3)<<6);
			}
		}

		if (frame==maxframes)
			int huhu=1;

		Fill();
	}
	else
	{
		BuildResultData();
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

void Vectorizer::ShowObject( float time_diff, bool filled )
{
	static int frame=0;

	static Vector3 objpos(0.0f, 0.0f, 0.0f);
	static Vector3 objtarget(0.0f, 0.0f, 0.0f);

	static float objrx=0.0f;
	static float objry=0.0f;
	static float objrz=0.0f;

	static Vector3 campos(0.0f, 0.0f, 0.0f);

	static float camrx=pi*0.5f;
	static float camry=0.0f;
	static float camrz=0.0f;
	
	static float t_obj=0.0f;
	static float t_cam=0.0f;
	static float t_objstep=1.0f/(float)(maxframes);
	static float t_camstep=1.0f/(float)(maxframes);

	t_obj+=t_objstep;
	t_cam+=t_camstep;
	if (frame>=256)
	{
		t_camstep+=(t_objstep*0.001f);
		if (t_camstep>t_objstep)
			t_camstep=t_objstep;
	}

	objry=OxySin(t_obj*8.0f*pi)*0.5f;
	if (frame>=168 && frame<224)
		objry=t_obj*16.0f*pi;
	if (frame>=336 && frame<448)
		camry=t_obj*8.0f*pi;

	float rad=300.0f;
	float moverad=20.0f;

	objpos.x=OxySin(t_obj*2.0f*pi)*rad;
	objpos.y=OxyCos(t_obj*2.0f*pi)*rad;
	objpos.z=0.0f;

	objtarget.x=OxySin(t_obj*2.0f*pi+0.1f)*rad;
	objtarget.y=OxyCos(t_obj*2.0f*pi+0.1f)*rad;
	objtarget.z=0.0f;

	campos.x=OxySin(t_cam*2.0f*pi)*rad+OxySin(t_cam*4.0f*pi        )*moverad;
	campos.y=OxyCos(t_cam*2.0f*pi)*rad+OxySin(t_cam*4.0f*pi+0.4f*pi)*moverad;
	campos.z=                     0.0f+OxySin(t_cam*4.0f*pi+0.7f*pi)*moverad;

	Vector3 delta=objpos-campos;
	Vector3 delta2=objtarget-objpos;

	camrz=OxyAtan2(delta.y, delta.x)+pi*0.5f;
	camrx=-OxyAtan2(delta.z, OxySqrt(delta.y*delta.y+delta.x*delta.x))+pi*0.5f;

	objrz=OxyAtan2(delta2.y, delta2.x)+pi*0.5f;

	Matrix3x4 objmat;
	Matrix3x4 cammat;
	
	objmat.Unit();
#ifdef VECTORIZER_SHOWSHIP
	objmat.RotateX(objrx);
	objmat.RotateY(objry);
	objmat.RotateZ(objrz);
	objmat.Translate(objpos);
#endif

	cammat.Unit();
	cammat.RotateX(camrx);
	cammat.RotateZ(camrz);
	cammat.Translate(campos);
	cammat.Invert();
	cammat.RotateZ(camry);
	
	Matrix3x4 mat=objmat;
	
	mat.MultiplyMatrix(cammat);

	frame++;

	int numvertices=vertices.size();

	for (int i=0 ; i<numvertices ; i++)
	{
		Vertex* vertex=vertices[i];

		Vector3 pos=vertex->pos;

		pos.MultiplyMatrix(mat);
	
		float z=au/pos.z;
		float x=pos.x*z+centerx;
		float y=pos.y*z+centery;

		vertex->pos2.x=x;
		vertex->pos2.y=y;
		vertex->pos2.z=pos.z;
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
		
		int numclippedpoints=0;

		std::vector<Vector3> clippedpoints;

		for (int j=0 ; j<poly->numids ; j++)
		{
			int j2=(j+1) % poly->numids;

			int o1=poly->ids[j];
			int o2=poly->ids[j2];

			Vector3& p1=vertices[o1]->pos;
			Vector3& p2=vertices[o2]->pos;
			float z1=vertices[o1]->pos2.z;
			float z2=vertices[o2]->pos2.z;

			// both points outside, skip
			if (z1<nearplane && z2<nearplane)
			{
				continue;
			}

			// both points inside, add p1
			if (z1>=nearplane && z2>=nearplane)
			{
				clippedpoints.push_back(p1);
				continue;
			}

			// p2 inside, entering visible area, add clipped point
			if (z1<nearplane)
			{
				Vector3 p3=p1+(p2-p1)*(nearplane-z1)/(z2-z1);

				clippedpoints.push_back(p3);
				continue;
			}

			// p1 inside, exiting visible area, add p1 and clipped point
			if (z2<nearplane)
			{
				Vector3 p3=p2+(p1-p2)*(nearplane-z2)/(z1-z2);
		
				clippedpoints.push_back(p1);
				clippedpoints.push_back(p3);
				continue;
			}
		}

		poly->numvertices=clippedpoints.size();
		for (int j=0 ; j<poly->numvertices ; j++)
		{
			Vector3 p1=clippedpoints[j];

			p1.MultiplyMatrix(mat);

			Vector3 p2;
		
			float z=au/p1.z;
			p2.x=p1.x*z+centerx;
			p2.y=p1.y*z+centery;
			p2.z=p1.z;

			poly->vertices[j]=p2;
			clippoly.AddPoint(Vector2(p2.x, p2.y));
			UpdatePolyBounds(poly);
			UpdateClipPolyBounds(clippoly);

			z+=poly->vertices[j].z;
			minz=Min(minz, poly->vertices[j].z);
			maxz=Max(maxz, poly->vertices[j].z);
		}

		clippoly.Reverse();

		z/=(float)(poly->numvertices);

		float sort=minz*1.0f+maxz*0.0f+z*0.0f;

		sortvalues[i]=SortValue(i, sort);

		if (poly->cull)
		{	
			Vector3& p1=poly->vertices[0];
			Vector3& p2=poly->vertices[1];
			Vector3& p3=poly->vertices[2];
		
			float cross=(((p2.x-p1.x)*(p3.y-p1.y)) - ((p2.y-p1.y)*(p3.x-p1.x)));

			poly->visible=false;
			if (cross>0.0f)
			{
				poly->visible=true;
			}

			if (poly->visible)
			{
				int clipcounts[4] = { 0, 0, 0, 0 };
				for (int j=0 ; j<poly->numvertices ; j++)
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
				if (clipcounts[0]==poly->numvertices ||
					clipcounts[1]==poly->numvertices ||
					clipcounts[2]==poly->numvertices ||
					clipcounts[3]==poly->numvertices)
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

				DoPoly(clippoly, i);
			}
			else
			{
				for (int j=0 ; j<poly->numvertices ; j++)
				{
					int j2=(j+1) % poly->numids;

					Vector3& p1=poly->vertices[j ];
					Vector3& p2=poly->vertices[j2];
				
					DoLine(p1, p2, i);
				}
			}
		}
	}
}

void Vectorizer::DoPoly( ClipPoly& poly, int sortid )
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

				AddDrawEdge(p3, p4, poly.col);
			}
		}
	}
}

void Vectorizer::GatherClipPlanes( ClipPoly& clippoly, Poly* coverpoly, Planes& out_planes )
{
	if (!IsOverlapping(clippoly, coverpoly))
		return;

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
		
		for (int j=0 ; j<coverpoly->numvertices ; j++)
		{
			int j2=(j+1) % coverpoly->numvertices;

			Vector3& p3=coverpoly->vertices[j ];
			Vector3& p4=coverpoly->vertices[j2];
		
			if (Clip(p5, p6, p3, p4, cutpoint, 0.001f))
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

	for (int j=0 ; j<coverpoly->numvertices ; j++)
	{
		int j2=(j+1) % coverpoly->numvertices;
		
		Vector3& p3=coverpoly->vertices[j ];
		Vector3& p4=coverpoly->vertices[j2];
	
		int count1=0;
		int count2=0;

		bool outside=false;

		for (int i=0 ; i<numpoints ; i++)
		{
			int i2=(i+1) % numpoints;

			Vector2& p1=clippoly.points[i ];
			Vector2& p2=clippoly.points[i2];
			Vector3 p12(p1.x, p1.y, 0.0f);
			Vector3 p22(p2.x, p2.y, 0.0f);

			Plane plane(p12, p22, p22+Vector3(0.0f, 0.0f, 1.0f));

			float dist1=plane.GetDistance(p3);
			float dist2=plane.GetDistance(p4);
			if (dist1>=0.0f && dist2>=0.0f)
			{
				outside=true;
				break;
			}
		}

		if (outside)
			continue;

		Plane plane(p3, p4, p4+Vector3(0.0f, 0.0f, 1.0f));

		float angleepsilon=0.01f;
		float distepsilon=0.1f;

		bool planefound=false;

		int numplanes=out_planes.size();
		for (int iplane=0 ; iplane<numplanes ; iplane++)
		{
			Plane& usedplane=out_planes[iplane];
			if ( (plane.normal-usedplane.normal).Scalar()<angleepsilon &&
				 OxyFabs(plane.distance-usedplane.distance)<distepsilon)
			{
				planefound=true;
				break;
			}
			
			if ( (plane.normal+usedplane.normal).Scalar()<angleepsilon &&
				 OxyFabs(plane.distance+usedplane.distance)<distepsilon)
			{
				planefound=true;
				break;
			}
		}

		if (!planefound)
		{
			out_planes.push_back(plane);
		}
	}
}

void Vectorizer::Clip( ClipPoly& clippoly, Planes& planes, ClipPolys& out_polys )
{	
	ClipPolys newpolys;

	newpolys.push_back(clippoly);

	float epsilon=0.0f;

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

bool Vectorizer::SplitPolyOnPlane( ClipPoly& clippoly, Plane& plane, ClipPolys& out_polys, float epsilon )
{
	bool left=false;
	bool right=false;

	int numpoints=clippoly.numpoints;

	for (int i=0 ; i<numpoints ; i++)
	{
		Vector2& p1=clippoly.points[i];
		Vector3 p2(p1.x, p1.y, 0.0f);

		float dist=plane.GetDistance(p2);
		if(dist<=-epsilon)
			left=true;

		if (dist>=epsilon)
			right=true;
	}

	if (left && right)
	{
		ClipPoly	newclippoly1,
					newclippoly2;						

		if (SplitPolyOnPlane(clippoly, plane, newclippoly1, epsilon, -1.0f))
		{
			out_polys.push_back(newclippoly1);
		}

		if (SplitPolyOnPlane(clippoly, plane, newclippoly2, epsilon, 1.0f))
		{
			out_polys.push_back(newclippoly2);
		}

		return true;
	}

	out_polys.push_back(clippoly);

	return false;
}

bool Vectorizer::SplitPolyOnPlane( ClipPoly& clippoly, Plane& plane, ClipPoly& out_poly, float epsilon, float scale )
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
		if (dist1<0.0f && dist2<0.0f)
		{
			continue;
		}

		// both points inside, use p1
		if (dist1>=0.0f && dist2>=0.0f)
		{
			out_poly.AddPoint(p1);
			//out_poly.points[out_poly.numpoints++]=p1;
			
			continue;
		}

		// p2 inside, entering visible area, add clipped point
		if (dist2>=0.0f)
		{
			float factor=(0.0f-dist1)/(dist2-dist1);

			Vector2 p3=p1+(p2-p1)*factor;
			
			out_poly.AddPoint(p3);
			//out_poly.points[out_poly.numpoints++]=p3;
			continue;
		}

		// p1 inside, exiting visible area, add p1 and clipped point
		if (dist1>=0.0f)
		{
			float factor=(0.0f-dist2)/(dist1-dist2);

			Vector2 p3=p2+(p1-p2)*factor;
		
			out_poly.AddPoint(p1);
			out_poly.AddPoint(p3);
			//out_poly.points[out_poly.numpoints++]=p1;
			//out_poly.points[out_poly.numpoints++]=p3;
			continue;
		}
	}

	if (out_poly.numpoints>2)
	{
		return true;
	}
	return false;
}

void Vectorizer::DoLine( Vector3& p1, Vector3& p2, int sortid )
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

	lines.push_back(Line(p1, p2));

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
			AddResultLine((int)(line.p1.x), (int)(line.p1.y), (int)(line.p2.x), (int)(line.p2.y));
			//DoLineScreen((int)(line.p1.x), (int)(line.p1.y), (int)(line.p2.x), (int)(line.p2.y));
		}
	}
}

int	Vectorizer::AddDrawPoint( Vector3& p1 )
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
		
void Vectorizer::AddDrawEdge( Vector3 p2, Vector3 p3, unsigned char col )
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
		return;
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

void Vectorizer::AddDrawEdgeClipped( Vector3 p1, Vector3 p2, unsigned char col )
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

void Vectorizer::Clip( Line& line, Poly* poly, Lines& out_lines )
{
	bool inside1=IsInside(line.p1, poly,-0.1f);
	bool inside2=IsInside(line.p2, poly,-0.1f);

	if (inside1 && inside2)
	{
		return;
	}

	std::vector<Vector3> cutpoints;

	Vector3 cutpoint;

	for (int j=0 ; j<poly->numvertices ; j++)
	{
		int j2=(j+1) % poly->numvertices;
		
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
				AddLine(out_lines, cutpoints[cutcount-1], line.p2);
			}
			else
			{
				AddLine(out_lines, line.p1, line.p2);
			}
		}
	}
	else
	{
		if (inside2)
		{
			if (cutcount>0)
			{
				AddLine(out_lines, line.p1, cutpoints[0]);
			}
			else
			{
				AddLine(out_lines, line.p1, line.p2);
			}
		}
		else
		{
			if (cutcount>0)
			{
				AddLine(out_lines, line.p1, cutpoints[0]);
				AddLine(out_lines, cutpoints[cutcount-1], line.p2);
			}
			else
			{
				AddLine(out_lines, line.p1, line.p2);
			}
		}
	}
}

void Vectorizer::AddLine( Lines& lines, Vector3& p1, Vector3& p2 )
{
	Vector3 delta(p2-p1);

	if (delta.ScalarSquared()<1.0f)
	{
		return;
	}

	lines.push_back(Line(p1, p2));
}

bool Vectorizer::Clip( Vector3& p1, Vector3& p2, Vector3& p3, Vector3& p4, Vector3& out_cut, float epsilon )
{
	p1.z=0.0f;
	p2.z=0.0f;
	p3.z=0.0f;
	p4.z=0.0f;

	Plane plane(p3, p4, p4+Vector3(0.0f, 0.0f, 1.0f));

	float dist1=plane.GetDistance(p1);
	float dist2=plane.GetDistance(p2);
	if (dist1*dist2>0.0f)
		return true;

	return false;
}

bool Vectorizer::IsInside( Vector3& point, Poly* poly, float epsilon )
{
	for (int j=0 ; j<poly->numvertices ; j++)
	{
		int j2=(j+1) % poly->numvertices;

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

bool Vectorizer::IsInside( Vector2& point, ClipPoly& poly, float epsilon )
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

bool Vectorizer::IsOverlapping( ClipPoly& clippoly, Poly* poly )
{
	int numpoints1=poly->numvertices;
	int numpoints2=clippoly.numpoints;
	for (int i=0 ; i<numpoints1 ; i++)
	{
		int i2=(i+1) % numpoints1;

		Vector3& p1=poly->vertices[i];
		Vector3& p2=poly->vertices[i2];
		
		Vector3 p11(p1.x, p1.y, 0.0f);
		Vector3 p21(p2.x, p2.y, 0.0f);

		Plane plane(p11, p21, p21+Vector3(0.0f, 0.0f, 1.0f));
	
		int count=0;

		for (int j=0 ; j<numpoints2 ; j++)
		{
			Vector2& p3=clippoly.points[j];
			Vector3 p4(p3.x, p3.y, 0.0f);

			if (plane.GetDistance(p4)>1.0f)
			{
				count++;
				break;
			}
		}

		if (count==0)
			return false;
	}

	return true;
}

bool Vectorizer::IsCovered( ClipPoly& clippoly, Poly* poly )
{
	int numclippoints=clippoly.numpoints;
	for (int i=0 ; i<numclippoints ; i++)
	{
		Vector2& p1=clippoly.points[i];
		Vector3 p2(p1.x, p1.y, 0.0f);

		if (!IsInside(p2, poly, -1.0f))
		{
			return false;
		}
	}
	return true;
}		

bool Vectorizer::ClipScreen( Line& line )
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

void Vectorizer::ClipScreenFill( Point& p1, Point& p2, Lines& out_lines )
{	
#ifdef VECTORIZER_AMIGA
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

#else // VECTORIZER_AMIGA
	if (!ClipValueMax(p1.x, p1.y, p2.x, p2.y, maxx))
		return;

	if (!ClipValueMax(p1.y, p1.x, p2.y, p2.x, maxy))
		return;

	if (!ClipValueMin(p1.x, p1.y, p2.x, p2.y, minx))
		return;

	ClipValueMinBorderY(p1.x, p1.y, p2.x, p2.y, miny, out_lines);
#endif // VECTORIZER_AMIGA
}

void Vectorizer::ClipValueMinBorderX( float& x1, float& y1, float& x2, float& y2, float minx, Lines& out_lines )
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

		out_lines.push_back(Line(Vector3(minx, y1, 0.0f), Vector3(minx, y3, 0.0f)));
		
		x1=minx;
		y1=y3;

		return;
	}
	
	if (x2<minx)
	{
		float y3=y2+(y1-y2)*(minx-x2)/(x1-x2);

		out_lines.push_back(Line(Vector3(minx, y2, 0.0f), Vector3(minx, y3, 0.0f)));
		
		x2=minx;
		y2=y3;

		return;
	}
}

void Vectorizer::ClipValueMinBorderY( float& x1, float& y1, float& x2, float& y2, float miny, Lines& out_lines )
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

		out_lines.push_back(Line(Vector3(x1, miny, 0.0f), Vector3(x3, miny, 0.0f)));

		y1=miny;
		x1=x3;

		return;
	}
	
	if (y2<miny)
	{
		float x3=x2+(x1-x2)*(miny-y2)/(y1-y2);

		out_lines.push_back(Line(Vector3(x2, miny, 0.0f), Vector3(x3, miny, 0.0f)));

		y2=miny;
		x2=x3;

		return;
	}
}

void Vectorizer::ClipValueMaxBorderX( float& x1, float& y1, float& x2, float& y2, float maxx, Lines& out_lines )
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

		out_lines.push_back(Line(Vector3(maxx, y1, 0.0f), Vector3(maxx, y3, 0.0f)));

		x1=maxx;
		y1=y3;

		return;
	}
	
	if (x2>maxx)
	{
		float y3=y2+(y1-y2)*(maxx-x2)/(x1-x2);

		out_lines.push_back(Line(Vector3(maxx, y2, 0.0f), Vector3(maxx, y3, 0.0f)));

		x2=maxx;
		y2=y3;

		return;
	}
}

void Vectorizer::ClipValueMaxBorderY( float& x1, float& y1, float& x2, float& y2, float maxy, Lines& out_lines )
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

		out_lines.push_back(Line(Vector3(x1, maxy, 0.0f), Vector3(x3, maxy, 0.0f)));

		y1=maxy;
		x1=x3;

		return;
	}
	
	if (y2>maxy)
	{
		float x3=x2+(x1-x2)*(maxy-y2)/(y1-y2);

		out_lines.push_back(Line(Vector3(x2, maxy, 0.0f), Vector3(x3, maxy, 0.0f)));

		y2=maxy;
		x2=x3;

		return;
	}
}

bool Vectorizer::ClipValueMin( float& x1, float& y1, float& x2, float& y2, float minx )
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

bool Vectorizer::ClipValueMax( float& x1, float& y1, float& x2, float& y2, float maxx )
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

void Vectorizer::UpdatePolyBounds( Poly* poly )
{
	int numpoints=poly->numvertices;
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

bool Vectorizer::CheckPolyBounds( Poly* poly, Vector3& point )
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
		
void Vectorizer::UpdateClipPolyBounds( ClipPoly& poly )
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
		
bool Vectorizer::CheckClipPolyBounds( ClipPoly& poly2, Poly* poly )
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

bool Vectorizer::CheckClipPolyBounds( ClipPoly& poly2, Vector3& point )
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

void Vectorizer::Fill( void )
{
	int x,y;
	unsigned char co;
	
#ifdef VECTORIZER_AMIGA
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
#else // VECTORIZER_AMIGA
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
#endif // VECTORIZER_AMIGA
}

void Vectorizer::AddVertex( float x, float y, float z )
{
	vertices.push_back(new Vertex(Vector3(x, y, z)));
}

void Vectorizer::AddPoly( int id1, int id2, int id3, unsigned char col, bool cull )
{
	int ids[] = { id1, id2, id3 };

	polys.push_back(new Poly(3, ids, col, cull));
}

void Vectorizer::AddPoly( int id1, int id2, int id3, int id4, unsigned char col, bool cull )
{
	int ids[] = { id1, id2, id3, id4 };

	polys.push_back(new Poly(4, ids, col, cull));
}

bool Vectorizer::AddMesh( const char* filename, const char* materialfile, float scale, float rx, float ry, float rz, Vector3& offset, bool swapwind, bool extrudepath )
{
	char line[1024];
	int len;
	int veccount;
	char va;
	char whitespaces[] = { ' ', '\t', '\r', '\n' };

	std::string matname;
	float diffuse[3];
	
	FileR* filer=new FileR(materialfile);

	typedef std::map<std::string, unsigned char> Materials;

	Materials materials;

	unsigned char count=palsize;

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

					unsigned int col=(r<<16) | (g<<8) | (b);

					pal[count]=col;

					int colid=-1;

					for (int i=0 ; i<count ; i++)
					{
						if (col==pal[i])
						{
							colid=i;
							break;
						}
					}

					if (colid!=-1)
					{
						materials[matname]=colid;
					}
					else
					{
						materials[matname]=count;

						count++;
					}
				}
			}
		}
	}
	delete filer;

	palsize=count;

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
					va=line[ipos];
					for (int iwhitespace=0 ; iwhitespace<4 ; iwhitespace++)
					{
						if (va== whitespaces[iwhitespace])
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
					
					if (extrudepath)
					{
						float t=-pi+2.0f*pi*(vec.y*TUNNELSEG_SCALE)/(12.0f*15.0f*4.0f);
						float rad=300.0f+vec.x*2.0f;

						float x=OxySin(t)*rad;
						float y=OxyCos(t)*rad;
						float z=vec.z*2.0f;
			
						vec.Set(x, y, z);
					}

					AddVertex(vec.x, -vec.y, vec.z);
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
								idxs[veccount++]=atoi(&line[ipos+1]);
							}
						}
					}
				}

				if (veccount>=3)
				{
					Poly* poly=new Poly();

					poly->cull=true;
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

					polys.push_back(poly);
				}
			}
		}
	};

	delete filer;

	return true;
}

void Vectorizer::ClipPoly::Reverse( void )
{
	for (int i=0 ; i<(numpoints)/2 ; i++)
	{
		int i2=numpoints-(i+1);
		Swap(points[i], points[i2]);
	}
}

void Vectorizer::DrawClipPoly( ClipPoly& poly, int offx, int offy )
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

void Vectorizer::AddResultLine( int x1, int y1, int x2, int y2 )
{
	if (x1<0 || y1<0 || x2<0 || y2<0 || 
		x1>=320 || y1>=320 || x2>=320 || y2>=320)
	{
		return;
	}

#ifdef VECTORIZER_FAKERS_LINIEN_STINKEN
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

	resultlines.push_back(line);
}

void Vectorizer::BuildResultData( void )
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

		for (int i=0 ; i<numlines ; i++)
		{
			ResultLine& line=resultlines[i];

			if (datapoi<=0x1fff0)
			{
				if (line.Point1Shared(lastline))
				{
					data[datapoi++]=0xc8;
					data[datapoi++]=line.y2;
					data[datapoi++]=line.x2 & 0xff;
					if (numhibits==0)
					{
						lastgap=datapoi++;
					}

					hibits<<=1;
					hibits|=(line.x2>>8);
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
					data[datapoi++]=line.x1 & 0xff;
					if (numhibits==0)
					{
						lastgap=datapoi++;
					}

					hibits<<=1;
					hibits|=(line.x1>>8);
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
				data[datapoi++]=line.x1 & 0xff;
				if (numhibits==0)
				{
					lastgap=datapoi++;
				}

				hibits<<=1;
				hibits|=(line.x1>>8);
				numhibits++;
				if (numhibits==8)
				{
					data[lastgap]=hibits;
					hibits=0;
					numhibits=0;
				}

				data[datapoi++]=line.y2;
				data[datapoi++]=line.x2 & 0xff;
				if (numhibits==0)
				{
					lastgap=datapoi++;
				}

				hibits<<=1;
				hibits|=(line.x2>>8);
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

void Vectorizer::ShowResultData( void )
{
	static int poi=0;
	int val;
	int x1=-1,
		x2=-1,
		y1=-1,
		y2=-1;
	
	unsigned char hibits=0;
	int numhibits=8;

	while(poi<datapoi)
	{
		val=data[poi++];
		if (val==0xff)
			break;

		if (val==0xc8)
		{	
			y2=data[poi++];
			x2=data[poi++];
			if (numhibits==8)
			{
				hibits=data[poi++];
				numhibits=0;
			}
			x2+=((hibits&0x80)<<1);
			hibits<<=1;
			numhibits++;
			
			gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), 0xffffff);
			continue;
		}

		if (val==0xc9)
		{
			y1=data[poi++];
			x1=data[poi++];
			if (numhibits==8)
			{
				hibits=data[poi++];
				numhibits=0;
			}
			x1+=((hibits&0x80)<<1);
			hibits<<=1;
			numhibits++;
			
			gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), 0xffffff);
			continue;
		}

		y1=val;
		x1=data[poi++];			
		if (numhibits==8)
		{
			hibits=data[poi++];
			numhibits=0;
		}
		x1+=((hibits&0x80)<<1);
		hibits<<=1;
		numhibits++;
		
		y2=data[poi++];
		x2=data[poi++];
		if (numhibits==8)
		{
			hibits=data[poi++];
			numhibits=0;
		}
		x2+=((hibits&0x80)<<1);
		hibits<<=1;
		numhibits++;
		
		gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), 0xffffff);

		numlines++;
	}
}

void Vectorizer::DoLineScreen( int x1, int y1, int x2, int y2 )
{
	gfx->Line((float)(x1), (float)(y1), (float)(x2), (float)(y2), 0xffffff);
	//LineOverDraw((float)(x1), (float)(y1), (float)(x2), (float)(y2));
}

void Vectorizer::DoLineFill( int x1, int y1, int x2, int y2, unsigned char col )
{
#ifdef VECTORIZER_AMIGA
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
#else // VECTORIZER_AMIGA
	FillerBase::DoLine(x1, y1, x2, y2, col, false);
#endif // VECTORIZER_AMIGA
}

void Vectorizer::LineOverDraw( float x1, float y1, float x2, float y2 )
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

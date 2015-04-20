class VectorizerWire : public FillerBase
{
	private:
		typedef std::vector<Plane> Planes;

		struct Vertex
		{
			Vector3	pos,
					pos2;
			bool	transform;
			
			Vertex()
			{

			}

			Vertex( const Vector3& pos, bool transform )
			{
				this->pos=pos;
				this->transform=transform;
			}
		};
		typedef std::vector<Vertex*> Vertices;

		struct Line
		{
			Vector3 p1,
					p2;
			int		col;

			Line( Vector3& p1, Vector3& p2, int col )
			{
				this->p1=p1;
				this->p2=p2;
				this->col=col;
			}
		};
		typedef std::vector<Line> Lines;

		struct Poly
		{
			int				numids;
			int				ids[128];
			Vector3			vertices[128];
			bool			cull;
			bool			visible;
			bool			draw;
			unsigned char	col;
			Vector3			center;
			float			radius;

			Poly()
			{
				Clear();
			}	

			Poly( int numids, int* ids, unsigned char col, bool cull )
			{
				visible=false;

				this->cull=cull;
				this->col=col;
				
				this->numids=numids;

				for (int i=0 ; i<numids ; i++)
				{
					this->ids[i]=ids[i];
					this->vertices[i].Clear();
				}

				center.Clear();
				radius=0.0f;
			}

			void Clear( void )
			{
				visible=false;
				cull=false;
				col=0;

				numids=0;
				for (int i=0 ; i<4 ; i++)
				{
					ids[i]=-1;
					this->vertices[i].Clear();
				}

				center.Clear();
				radius=0.0f;
			}
		};
		typedef std::vector<Poly*> Polys;

		struct ClipPoly
		{
			int				numpoints;
			Vector2			points[12];
			unsigned char	col;
			Vector2			center;
			float			radius;

			ClipPoly()
			{
				Clear();
			}	

			ClipPoly( unsigned char col )
			{
				Clear();
				this->col=col;
			}

			void Clear( void )
			{
				numpoints=0;
				col=0;
				radius=0.0f;
			}

			void AddPoint( Vector2& point )
			{
				if (numpoints<12)
				{
					if (numpoints>0)
					{
						Vector2 delta(point-points[numpoints-1]);
						if (delta.ScalarSquared()<1.0f)
						{
							return;
						}
					}
					points[numpoints++]=point;
				}
			}

			void Reverse( void );
		};
		typedef std::vector<ClipPoly> ClipPolys;

		struct Point
		{
			float	x,
					y;

			Point()
			{
				x=0.0f;
				y=0.0f;
			}

			Point( float x, float y )
			{
				this->x=x;
				this->y=y;
			}
		};
		typedef std::vector<Point> Points;

		struct Edge
		{
			int				o1,
							o2;
			unsigned char	col;

			Edge()
			{
				col=0;
			}

			Edge( int o1, int o2, unsigned char col )
			{
				this->o1=o1;
				this->o2=o2;
				this->col=col;
			}
		};
		typedef std::vector<Edge> Edges;

		struct SortValue
		{
			int		polyid;
			float	z;

			SortValue()
			{
				polyid=-1;
				z=0.0f;
			}

			SortValue( int polyid, float z )
			{
				this->polyid=polyid;
				this->z=z;
			}
		};
		typedef std::vector<SortValue> SortValues;

		struct ResultLine
		{
			int x1,
				y1,
				x2,
				y2;
			int col;

			ResultLine()
			{
				x1=0;
				y1=0;
				x2=0;
				y2=0;
				col=0;
			}
			
			ResultLine( int x1, int y1, int x2, int y2, int col )
			{
				this->x1=x1;
				this->y1=y1;
				this->x2=x2;
				this->y2=y2;
				this->col=col;
			}

			bool Point1Shared( ResultLine& rhs )
			{
				if (x1==rhs.x1 && y1==rhs.y1)
				{
					return true;
				}
				return false;
			}

			bool Point2Shared( ResultLine& rhs )
			{
				if (x2==rhs.x2 && y2==rhs.y2)
				{
					return true;
				}
				return false;
			}
		};
		typedef std::vector<ResultLine> ResultLines;


		float			camrx;
		float			camry;
		float			camrz;
		Vector3			campos;

		int				maxframes;
		float			au,
						tf,
						centerx,
						centery,
						minx,
						maxx,
						miny,
						maxy,
						nearplane;
		Vertices		vertices;
		Polys			polys;
		ClipPolys		clippolys;
		SortValues		sortvalues;
		Points			drawpoints;
		Edges			drawedges;

		unsigned int	pal[256];

		ResultLines		resultlines;

		int				numlines;
		int				datapoi;
		unsigned char	data[0x200000];
		

	public:
		VectorizerWire();
		virtual ~VectorizerWire();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


	private:
		int			GetAccumFilledEdgeCost( Lines& lines, const std::vector<unsigned char>& cols );
		int			GetFilledEdgeCost( Line& line, unsigned char co );
		void		ShowObject( float time_diff, bool filled, unsigned char colswapflags, bool dostep );
		Vector3		TransformPoint( Vector3 pos, Matrix3x4& mat );
		void		DoPoly( ClipPoly& poly, int sortid, unsigned char colswapflags );
		unsigned char GetSwappedCol( unsigned char col, unsigned char colswapflags );
		void		DoLine( Vector3& p1, Vector3& p2, int sortid, int col );
		int			AddDrawPoint( Vector3& p1 );
		void		AddDrawEdge( Vector3 p1, Vector3 p2, unsigned char col );
		void		AddDrawEdgeClipped( Vector3 p1, Vector3 p2, unsigned char col );
		void		GatherClipPlanes( ClipPoly& clippoly, Poly* coverpoly, Planes& out_planes );
		void		Clip( ClipPoly& clippoly, Planes& planes, ClipPolys& out_polys );
		bool		SplitPolyOnPlane( ClipPoly& clippoly, Plane& plane, ClipPolys& out_polys, float epsilon );
		bool		SplitPolyOnPlane( ClipPoly& clippoly, Plane& plane, ClipPoly& out_poly, float epsilon, float scale );
		void		Clip( Line& line, Poly* poly, Lines& out_lines );
		bool		Clip( Vector3& p1, Vector3& p2, Vector3& p3, Vector3& p4, Vector3& out_cut, float epsilon=0.0f );
		void		AddLine( Lines& lines, Vector3& p1, Vector3& p2, int col );
		bool		IsInside( Vector3& point, Poly* poly, float epsilon );
		bool		IsInside( Vector2& point, ClipPoly& poly, float epsilon );
		bool		IsCovered( ClipPoly& clippoly, Poly* poly );
		bool		ClipScreen( Line& line );
		void		ClipScreenFill( Point& p1, Point& p2, Lines& out_lines );
		void		ClipValueMinBorderX( float& x1, float& y1, float& x2, float& y2, float minx, Lines& out_lines, int col );
		void		ClipValueMinBorderY( float& x1, float& y1, float& x2, float& y2, float miny, Lines& out_lines, int col );
		void		ClipValueMaxBorderX( float& x1, float& y1, float& x2, float& y2, float maxx, Lines& out_lines, int col );
		void		ClipValueMaxBorderY( float& x1, float& y1, float& x2, float& y2, float maxy, Lines& out_lines, int col );
		bool		ClipValueMin( float& x1, float& y1, float& x2, float& y2, float minx );
		bool		ClipValueMax( float& x1, float& y1, float& x2, float& y2, float maxx );
		void		UpdatePolyBounds( Poly* poly );
		bool		CheckPolyBounds( Poly* poly, Vector3& point );
		void		UpdateClipPolyBounds( ClipPoly& poly );
		bool		CheckClipPolyBounds( ClipPoly& poly2, Poly* poly );
		bool		CheckClipPolyBounds( ClipPoly& poly2, Vector3& point );
		void		Fill( void );
		void		AddVertex( float x, float y, float z, bool transform );
		void		AddPoly( int id1, int id2, int id3, unsigned char col, bool cull );
		void		AddPoly( int id1, int id2, int id3, int id4, unsigned char col, bool cull );
		bool		AddMesh( const char* filename, const char* materialfile, float scale, float rx, float ry, float rz, Vector3& offset, bool swapwind=false );

		void		DrawClipPoly( ClipPoly& poly, int offx, int offy );

		void		AddResultLine( int x1, int y1, int x2, int y2, int col );		
		unsigned char GetHiBit( int val );
		unsigned char GetLowByte( int val );
		int			FetchHiBit( unsigned char val );
		int			FetchLowByte( unsigned char val );
		void		BuildResultData( void );
		void		ShowResultData( void );
		void		DoLineScreen( int x1, int y1, int x2, int y2 );
		void		DoLineFill( int x1, int y1, int x2, int y2, unsigned char col );
		void		LineOverDraw( float x1, float y1, float x2, float y2 );

		DECLARE_CLASS(VectorizerWire);
};

class City : public FillerBase
{
	private:
		typedef std::vector<Vector3> Vertices;

		struct Poly
		{
			int	cv1, cv2, cv3, cv4;
			
			Poly()
			{
				cv1=-1;
				cv2=-1;
				cv3=-1;
				cv4=-1;
			}

			Poly( int cv1, int cv2, int cv3, int cv4 )
			{
				this->cv1=cv1;
				this->cv2=cv2;
				this->cv3=cv3;
				this->cv4=cv4;
			}
		};
		typedef std::vector<Poly> Polys;

		struct Body
		{
			Vertices	vertices;
			Polys		polys;
			float		z;
			Vector3		center;

			Body()
			{
				z=0.0f;
			}

			void AddVertex( float x, float y, float z )
			{
				vertices.push_back(Vector3(x, y, z));
			}
		
			void AddPoly( int cv1, int cv2, int cv3, int cv4 )
			{
				polys.push_back(Poly(cv1, cv2, cv3, cv4));
			}

			void Init( void )
			{
				int numvertices=vertices.size();
				
				float maxy=-999999.0f;

				for (int i=0 ; i<numvertices ; i++)
				{
					maxy=Max(maxy, vertices[i].y);
				}
	
				center.Clear();

				for (int i=0 ; i<numvertices ; i++)
				{
					vertices[i].y-=maxy;

					center+=vertices[i];
				}
			
				center/=(float)(numvertices);
			}
		};
		typedef std::vector<Body> Bodies;
		
		struct SortValue
		{
			int		bodyid;
			float	z;

			SortValue()
			{
				bodyid=-1;
				z=0.0f;
			}

			SortValue( int bodyid, float z )
			{
				this->bodyid=bodyid;
				this->z=z;
			}
		};
		typedef std::vector<SortValue> SortValues;
		
		Bodies			bodies;
		SortValues		sortvalues;
		unsigned char	texture[128][128];
		unsigned int	pal[16];

		float			linebuf[160][3];
		

	public:
		City();
		virtual ~City();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


	private:
		void	InitCity( void );
		void	AddCube( const Vector3& pos, const Vector3& size, float ry );
		void	CalcBodyZ( Body& body, float rx, float ry, Vector3& camerapos );
		void	ShowBody( Body& body, float rx, float ry, Vector3& camerapos, int sortid );
		void	DoLine( float x1, float y1, float u1, float x2, float y2, float u2 );
		void	FillPoly( int minx, int maxx );

		DECLARE_CLASS(City);
};

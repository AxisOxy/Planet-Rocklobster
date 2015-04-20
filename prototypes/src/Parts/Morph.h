class Morph : public Effect
{
	private:
		struct Point
		{
			short	x, 
					y;

			Point()
			{
				x=0;
				y=0;
			}

			Point( int x, int y )
			{
				this->x=x;
				this->y=y;
			}

		};
		typedef std::vector<Point> Points;

		Points	points1, 
				points2,
				points3;


	public:
		Morph();
		virtual ~Morph();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );

		
	private:
		void	ConvPoints( Points& points1, Points& points2 );
		void	Randomize( Points& points );
		void	ExtendArray( Points& points, int newsize );

		void	LoadMesh( const char* filename, Points& points );
		void	WriteMesh( const char* filename, Points& points );
		void	AddLine( int x1, int y1, int x2, int y2, Points& points );
		int		FetchBit( unsigned char& bit, unsigned char* data, int& off, int& bitcount );
		void	Display( Points& points1, Points& points2, int morphframe );


		DECLARE_CLASS(Morph);
};

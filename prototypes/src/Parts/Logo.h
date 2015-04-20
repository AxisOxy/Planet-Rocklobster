class Logo : public FillerBase
{
	private:
		struct Pixel
		{
			int	x,y;

			Pixel()
			{
				this->x=0;
				this->y=0;
			}

			Pixel( int x, int y)
			{
				this->x=x;
				this->y=y;
			}
		};
		typedef std::list<Pixel> Pixels;
		typedef Pixels::iterator PixelIter;

		struct Edge
		{
			Pixel p1;
			Pixel p2;

			Edge()
			{

			}

			Edge( Pixel& p1, Pixel& p2)
			{
				this->p1=p1;
				this->p2=p2;
			}
		};
		typedef std::vector<Edge> Edges;

		struct Outline
		{
			Edges edges;
		};
		typedef std::vector<Outline> Outlines;
		
		struct sLogo
		{
			Outlines outlines;
		};
		typedef std::vector<sLogo> sLogos;


		sLogos	logos;


	public:
		Logo();
		virtual ~Logo();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


	private:
		void	ScanLogo( const char* filename, sLogo& logo );
		bool	ScanEdges( Pixels& pixels, Outline& outline );
		float	GetError( Pixel& pixel1, Pixel& pixel2, Pixel& pixel3 );
		void	ExportLogo( const char* filename, sLogo& logo );
		int		ShowObject( sLogo& logo, int frame, unsigned char co );
		void	Fill( bool invcol );


		DECLARE_CLASS(Logo);
};

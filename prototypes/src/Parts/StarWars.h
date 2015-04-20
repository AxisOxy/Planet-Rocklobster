class StarWars : public Effect
{
	private:
		struct Letter
		{
			int				width,
							height;
			unsigned char	data[64][64];

			Letter()
			{
				Clear();
			}

			void Clear( void )
			{
				width=0;
				height=0;
				memset(data,0,sizeof(data));
			}
		};
		typedef std::vector<Letter> Letters;
			
		int				palsize;
		unsigned int	pal[256];
		unsigned char	logo[64][320];

		Letters			letters;

		unsigned short	shadetab[32][8];
		unsigned char	linewidths[256][256];
		unsigned char	linevs[256][256];


	public:
		StarWars();
		virtual ~StarWars();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


	private:
		void	BlitText( char* text, int posx, int posy );
		int		BlitChar( char chr, int posx, int posy );
		void	LoadFont( char* filename, int charwidth, int charheight, int marginleft, int marginright, int margintop, int marginbottom );
		

		DECLARE_CLASS(StarWars);
};

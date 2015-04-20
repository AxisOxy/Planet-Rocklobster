class Starfield : public FillerBase
{
	private:
		struct Letter
		{
			unsigned char pixels[32][16];
		};
		typedef std::vector<Letter> Letters;

		unsigned int	pal[16];
		Letters			letters;


	public:
		Starfield();
		virtual ~Starfield();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


		DECLARE_CLASS(Starfield);
};

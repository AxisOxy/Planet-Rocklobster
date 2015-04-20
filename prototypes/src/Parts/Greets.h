class Greets : public FillerBase
{
	private:
		Font	font;

		struct	Glyph
		{
			short	width;
			char	data[64][8];
		};
		typedef std::vector<Glyph> Glyphs;

		Glyphs	glyphs;


	public:
		Greets();
		virtual ~Greets();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );
				

		DECLARE_CLASS(Greets);
};

class Rotzoom : public Effect
{
	private:
		unsigned int	pal[16];
		unsigned char	textures[4][64][64];
		
		short			sintab[2560];
		

	public:
		Rotzoom();
		virtual ~Rotzoom();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


	private:
		void	PrepareTexture( void );


		DECLARE_CLASS(Rotzoom);
};

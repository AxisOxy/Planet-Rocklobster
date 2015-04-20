class MotionBlur : public Effect
{
	private:
		unsigned int	pal[256];
		unsigned char	texture[128*128*2];
		unsigned char	buffer[160*100];

		short			sintab[2560];
		

	public:
		MotionBlur();
		virtual ~MotionBlur();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );

	
		DECLARE_CLASS(MotionBlur);
};

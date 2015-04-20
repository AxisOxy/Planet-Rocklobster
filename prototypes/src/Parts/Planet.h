class Planet : public FillerBase
{
	private:
		unsigned short	spheretab[512];
		

	public:
		Planet();
		virtual ~Planet();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );
				

		DECLARE_CLASS(Planet);
};

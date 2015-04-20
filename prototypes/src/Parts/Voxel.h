class Voxel : public Effect
{
	private:
		int				numzs;
		unsigned short	pal[128];
		unsigned short	skypal[128];
		unsigned char	texture[0x10000];
		unsigned short	texture2[0x10000];
		unsigned short	shadetab[16][128];
		unsigned char	heightmap[0x10000];
		short			sintab[1280];
		unsigned short	persptab[128][128];
		unsigned short	offsets[480][64];
		unsigned char	scaletab[80][64];
		int				offsetspacked[480][4];
		int				persptabpacked[128][2];

		int				skyr,
						skyg,
						skyb;
		int				fogr,
						fogg,
						fogb;


	public:
		Voxel();
		virtual ~Voxel();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


		DECLARE_CLASS(Voxel);
};

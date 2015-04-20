class Frac : public Effect
{
	private:
		struct PicData
		{
			unsigned char basepic[224][224];
			unsigned char rowdata[128][4][224];

			PicData()
			{
				memset(basepic, 0, sizeof(basepic));
				memset(rowdata, 0, sizeof(rowdata));
			}
		};
		typedef std::vector<PicData> PicDatas;

		int				numpics;
		int				numsubframes;
		unsigned char	pics[16][512][512];
		unsigned char	buffer[512][512];
		unsigned char	us[512][512];
		unsigned char	vs[512][512];
		unsigned char	frames[512][512];
		unsigned int	pal[17];
		PicDatas		picdatas;
		short			zoomxs[128];
		short			zoomus[128];


	public:
		Frac();
		virtual ~Frac();

		virtual void Init( Gfx *_gfx, Input *_input );
		virtual void Update( float _rendertime );


	private:
		void	Blit( int srcx, int srcy, int dstx, int dsty, int xsize, int ysize, bool backwardx, bool backwardy );
		int		IteratePixel( double x, double y, int maxiter );


		DECLARE_CLASS(Frac);
};

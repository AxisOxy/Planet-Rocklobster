#ifndef _FILLER_BASE_H
#define _FILLER_BASE_H

// baseclass for filled vector effects. if you derive from this class instead of Effect, you can use basic filled vector functions like line-drawing with and without subpixel and clipping and eor-filling.
class FillerBase : public Effect
{
	protected:
		int	pixelbuffer[256][640];	

	public:
		// standard ctor
		FillerBase();

		// dtor
		virtual ~FillerBase();

		// virtual init function, derived classes can override this function to get called for their initialisation.
		virtual void Init( Gfx *_gfx, Input *_input );


	protected:
		// fill a rectangle of the fillbuffer with the given col. this is usually used to clear the screen.
		void FillRect( int x1, int y1, int x2, int y2, unsigned char col );

		// draw an eor-fill outline without subpixel accuracy.
		void DoLine( int x1, int y1, int x2, int y2, unsigned char col, bool clip=true );

		// draw an eor-fill outline with subpixel accuracy.
		void DoLineSubPixel( int x1, int y1, int x2, int y2, unsigned char col, bool clip=true );

		// set an eor-fill outline pixel.
		void DoPixel( int x, int y, unsigned char col, bool clip=true );

		// eor-fill and display the given area.
		void Fill( int x1, int y1, int x2, int y2, unsigned char *pal, bool clipcolor=true, bool hires=false );
};

#endif // _FILLER_BASE_H

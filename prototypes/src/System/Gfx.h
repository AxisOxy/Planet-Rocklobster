#ifndef _GFX_H
#define _GFX_H

// a class for simple drawing operations on the direct draw window
class Gfx
{
	private:
		Display2D		*display;		

		int				xsize,ysize;
		unsigned int	*buffer;
	
	public:
		// ctor with window and size
		Gfx( Display2D *_display, int _xsize, int _ysize );

		// dtor
		~Gfx( void );

		// return window width in pixels
		int	GetXSize( void );

		// return height width in pixels
		int	GetYSize( void );

		// return (A8R8G8B8) buffer
		unsigned int* GetBuffer();

		// clear the window to the given colors
		void Clear	( unsigned int color );

		// set a pixel with the given color
		void Plot	( int x, int y, unsigned int color );

		// return the color of the pixel
		unsigned int GetPixel( int x, int y );

		// draw a line with the given coordinates and color
		void Line	( float x1, float y1, float x2, float y2, unsigned int color );

		// draw a box with the given coordinates and color
		void Box	( int x1, int y1, int x2, int y2, unsigned int color, bool filled );

		// draw a circle with the given coordinates and color
		void Circle	( float x, float y, float radius, unsigned int color, bool filled );

		// finish drawing for this frame
		void End	( void );
};

#endif // _GFX_H

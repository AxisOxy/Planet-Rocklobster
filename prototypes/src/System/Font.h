#ifndef _FONT_H
#define _FONT_H

// a class for loading true-type fonts
class Font
{
	private:
		static bool			initialized;
		static FT_Library	fontlib;

		Image*				images[256];


	public:
		// standard ctor
		Font();

		// dtor
		~Font();

		// load the font with the requested size
		bool Load( char *filename, int fontsize );

		// return an image with the requested glyph (ascii code)
		Image* GetGlyph( unsigned char chr ) const;
		

	private:
		void LoadLib( void );
};

#endif // _FONT_H

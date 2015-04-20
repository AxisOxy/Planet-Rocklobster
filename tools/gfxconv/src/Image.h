#ifndef _IMAGE_H
#define _IMAGE_H

// Class to load and save image files.
class Image
{
	private:
		int				width,height;
		int				bitdepth;
		unsigned int	*buffer;
		bool			haspal;
		int				palsize;
		unsigned int	*pal;
		unsigned char	*indexdata;


	public:
		// ctors & dtors
		Image();
		~Image();

		// Load the image from a file
		bool Load( const char *filename );

		// Save the image to a file
		bool Save( const char *filename );

		// Return width of the image in pixels
		int GetWidth( void );

		// Return height of the image in pixels
		int GetHeight( void );

		// Return bitdepth of the image
		int GetBitDepth( void );

		// Create an empty image
		void CreateEmpty( int width, int height, int bitdepth );

		// Clear the image with the given color (A8R8G8B8)
		void Clear( unsigned int color );

		// Return the color of the pixel (A8R8G8B8)
		unsigned int GetPixel( int x, int y );

		// Set the color of the pixel (A8R8G8B8)
		void SetPixel( int x, int y, unsigned int color );

		// Return the palette color index of the pixel (only valid if a loaded image has palette information)
		unsigned char GetPixelIndex( int x, int y );

		// Return the pixel buffer (A8R8G8B8)
		unsigned int *GetBuffer( void );

		// Set the pixel buffer (A8R8G8B8)
		void SetData( unsigned int *pbuffer );

		// Return if the image has a palette
		bool HasPalette( void );

		// Return the size of the palette
		int GetPaletteSize( void );

		// Return the palette (A8R8G8B8)
		unsigned int* GetPalette( void );

		// Return the palette index buffer
		unsigned char* GetIndexData( void );


	private:
		bool IsValid( void );
};

#endif // _IMAGE_H

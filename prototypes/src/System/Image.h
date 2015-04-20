#ifndef _IMAGE_H
#define _IMAGE_H

// a class wrapping loading/saving of images
class Image
{
	private:
		int				width,height;
		int				bitdepth;
		unsigned int	*buffer;


	public:
		// standard ctor
		Image();

		// dtor
		~Image();

		// load the image from the given file
		bool Load( const char *filename );

		// save the image to the given file
		bool Save( const char *filename );

		// return image width in pixels
		int GetWidth( void );

		// return image height in pixels
		int GetHeight( void );

		// return image bit depth
		int GetBitDepth( void );

		// create an empty image
		void CreateEmpty( int width, int height, int bitdepth );

		// clear the image to the given color
		void Clear( unsigned int color );

		// return the pixel color at the given position
		unsigned int GetPixel( int x, int y );

		// set the pixel color at the given position
		void SetPixel( int x, int y, unsigned int color );

		// return the (A8R8G8B8) pixel buffer
		unsigned int *GetBuffer( void );

		// set the (A8R8G8B8) pixel buffer
		void SetData( unsigned int *pbuffer );


	private:
		bool IsValid( void );
};

#endif // _IMAGE_H

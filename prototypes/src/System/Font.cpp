#include "include.h"

bool Font::initialized=false;
FT_Library Font::fontlib=0;

Font::Font()
{
	for ( int i=0 ; i<256 ; i++ )
	{
		images[i]=0;
	}
}

Font::~Font()
{
	for ( int i=0 ; i<256 ; i++ )
	{
		delete images[i];
	}
}

bool Font::Load( char *filename, int fontsize )
{
	LoadLib();

	FileR* filer = new FileR( filename );

	int size = filer->GetSize();
	if ( size>0 )
	{
		FT_Byte* buffer = new FT_Byte[ size ];

		int loaded_size = filer->Read( buffer, 1, size );
		if ( loaded_size>0 )
		{
			FT_Face face;

			FT_Error error = FT_New_Memory_Face( fontlib, buffer, loaded_size, 0, &face );
			
			error = FT_Set_Pixel_Sizes( face, fontsize, 0 );


			FT_GlyphSlot  slot;

			slot = face->glyph;

			FT_Bitmap* bitmap = 0;

			int width,height,x,y,top,left,fullwidth,fullheight;
			unsigned int co=0;
			unsigned int col=0;

			int minwidth = fontsize/5;
			int minheight = fontsize/5;

			for ( int i=0 ; i<256 ; i++ )
			{
				error = FT_Load_Char( face, i, FT_LOAD_RENDER );
			
				bitmap = &slot->bitmap;

				top = slot->bitmap_top;
				left = slot->bitmap_left;
				width = bitmap->width;
				height = bitmap->rows;
				fullwidth = width+left;
				fullheight = height+fontsize-top;
				
				if ( fullwidth<minwidth )
				{
					fullwidth=minwidth;
				}
	
				if ( fullheight<minheight )
				{
					fullheight=minheight;
				}

				delete images[i];

				images[i]=new Image();
				images[i]->CreateEmpty( fullwidth, fullheight, 24 );

				for ( y=0 ; y<height ; y++ )
				{
					for ( x=0 ; x<width ; x++ )
					{
						co = bitmap->buffer[ y * width + x ];
						col = ( co << 16 ) | ( co << 8 ) | ( co );

						images[i]->SetPixel( x+left, y+fontsize-top, col );
					}
				}
			}
		}

		delete [] buffer;

		delete filer;

		return true;
	}
	return false;
}

Image* Font::GetGlyph( unsigned char chr ) const
{
	return images[ chr ];
}

void Font::LoadLib( void )
{
	if ( false==initialized )
	{
		FT_Error error = FT_Init_FreeType( &fontlib );

		initialized=true;
	}
}

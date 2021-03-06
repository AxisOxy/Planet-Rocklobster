#include "include.h"

Image::Image()
{
	ilInit();
  
	width=0;
	height=0;
	bitdepth=0;
	buffer=NULL;
	haspal=false;
	palsize=0;
	pal=NULL;
	indexdata=NULL;
}

Image::~Image()
{
	delete [] buffer;
}

bool Image::Load( const char *filename )
{
	delete [] buffer;
	delete [] pal;
	delete [] indexdata;

	buffer=NULL;
	width=0;
	height=0;
	haspal=false;
	palsize=0;
	pal=NULL;
	indexdata=NULL;
	
	ILuint	ImgId;

	ilGenImages(1, &ImgId);

	ilBindImage(ImgId);

	ILenum eType = ilTypeFromExt( filename );
	
	if (!ilLoadImage(filename))
	{
		ilDeleteImages(1, &ImgId);
		return false;
	}

	width=ilGetInteger(IL_IMAGE_WIDTH);
	height=ilGetInteger(IL_IMAGE_HEIGHT);

	ILenum format=ilGetInteger(IL_IMAGE_FORMAT);
	
	bitdepth=ilGetInteger(IL_IMAGE_BITS_PER_PIXEL);

	ilEnable( IL_ORIGIN_SET );
	ilOriginFunc( IL_ORIGIN_UPPER_LEFT );
	ilEnable( IL_ORIGIN_SET );

	int size=width*height;
	if (size<=0)
	{
		ilDeleteImages(1, &ImgId);
		return false;
	}

	buffer=new unsigned int[size];
	
	if (ilConvertPal(IL_PAL_BGRA32))
	{
		haspal=true;
		palsize=ilGetInteger(IL_PALETTE_NUM_COLS);

		ILubyte* palbuf=ilGetPalette();
		
		pal=new unsigned int[palsize];

		memcpy(pal, palbuf, sizeof(unsigned int)*palsize);

		unsigned char* ilData=ilGetData();
		if (0 == ilData)
		{
			delete [] buffer;
			buffer=NULL;
		
			ilDeleteImages(1, &ImgId);
			return false;
		}
	
		indexdata=new unsigned char[width*height];
		
		memcpy(indexdata, ilData, width*height);
	}

	if (!ilConvertImage(IL_BGRA, IL_UNSIGNED_BYTE))
	{
		delete [] buffer;
		buffer=NULL;
		
		ilDeleteImages(1, &ImgId);
		return false;
	}

	if (!ilCopyPixels(0, 0, 0, width, height, 1, IL_BGRA, IL_UNSIGNED_BYTE, buffer))
	{
		delete [] buffer;
		buffer=NULL;

		ilDeleteImages(1, &ImgId);
		return false;
	}

	ilDeleteImages(1, &ImgId);

	return true;
}

bool Image::Save( const char *filename )
{
	if (!IsValid())
		return false;

	ILuint	ImgId;

	ilGenImages(1, &ImgId);

	ilBindImage(ImgId);
	

	ilEnable( IL_ORIGIN_SET );
	ilOriginFunc( IL_ORIGIN_UPPER_LEFT );
	ilEnable( IL_ORIGIN_SET );

	if (!ilTexImage(width,height,1,4,IL_BGRA,IL_UNSIGNED_BYTE,buffer))
	{
		ilDeleteImages(1, &ImgId);
		return false;
	}
	
	if ( bitdepth < 24 )
	{
		ilConvertImage(IL_COLOR_INDEX, IL_UNSIGNED_BYTE);
	}
	
	ilSetInteger(IL_IMAGE_BPP, bitdepth);
	
	ilEnable(IL_FILE_OVERWRITE);

	if (!ilSaveImage(filename))
	{
		int iRet = ilGetError();

		ilDeleteImages(1, &ImgId);
		return false;
	}

	ilDeleteImages(1, &ImgId);

	return true;
}

int Image::GetWidth( void )
{
	return width;
}

int Image::GetHeight( void )
{
	return height;
}

int Image::GetBitDepth( void )
{
	return bitdepth;
}		

void Image::CreateEmpty( int width, int height, int bitdepth )
{
	delete [] buffer;
	buffer=NULL;
	delete [] pal;
	pal=NULL;
	delete [] indexdata;
	indexdata=NULL;

	if (width>0 && height>0)
	{
		this->width=width;
		this->height=height;
		this->bitdepth=bitdepth;
		buffer=new unsigned int[width*height];
		Clear(0);
	}
}

void Image::Clear( unsigned int color )
{
	if (!IsValid())
		return;

	for (int i=0 ; i<width*height ; i++)
		buffer[i]=color;
}

unsigned int Image::GetPixel( int x, int y )
{
	if (!IsValid())
		return 0;

	if (x<0 || x>=width)
		return 0;

	if (y<0 || y>=height)
		return 0;

	return buffer[x+y*width];
}

void Image::SetPixel( int x, int y, unsigned int pixel )
{
	if (!IsValid())
		return;

	if (x<0 || x>=width)
		return;

	if (y<0 || y>=height)
		return;

	buffer[x+y*width]=pixel;
}

unsigned char Image::GetPixelIndex( int x, int y )
{
	if (!IsValid())
		return 0;

	if (x<0 || x>=width)
		return 0;

	if (y<0 || y>=height)
		return 0;

	if (0==indexdata)
		return 0;

	return indexdata[x+y*width];
}

unsigned int *Image::GetBuffer( void )
{
	return buffer;
}

void Image::SetData( unsigned int *pbuffer )
{
	if (!IsValid())
		return;

	if (!pbuffer)
		return;

	memcpy(buffer,pbuffer,width*height*sizeof(unsigned int));
}

bool Image::IsValid( void )
{
	if (buffer && width>0 && height>0)
		return true;

	return false;
}

bool Image::HasPalette( void )
{
	return haspal;
}

int Image::GetPaletteSize( void )
{
	return palsize;
}

unsigned int* Image::GetPalette( void )
{
	return pal;
}

unsigned char* Image::GetIndexData( void )
{
	return indexdata;
}

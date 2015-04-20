/////////////////////////////////////////////////////////////////////////////
// Sprite-Converter by Michael "Axis" Hillebrandt.
// This tool converts any pc-image-fileformat to a simple amiga sprite-format 
// containing 12bit palette and sprite data in 68k-endianess.
/////////////////////////////////////////////////////////////////////////////


#include "include.h"

bool ConvertSprites(const string &strSourcePath, const string& strDestPath, bool sortpal, bool imagepal);
int GetNextPow2(int iValue);
int GetLog2(int iValue);
unsigned short ConvToEndianShort(int value);
unsigned long ConvToEndianLong(int value);

int main( int argc, const char* argv[] )
{
	// if we have too less commandline arguments, show usage info.
	if ( argc < 3 )
	{
		cout << "usage spriteconv.exe <infile> <outfile> [n <optional params>]\n";
		cout << "optional params:\n";
		cout << "sort - sort palette by brightness\n";
		cout << "imagepal - use the palette stored in the image instead of generating one from the pixels\n";

		return -1;
	}

	// get source and dest path from command line.
	string strSourcePath( argv[ 1 ] );
	string strDestPath( argv[ 2 ] );
	
	cout << "source path: " << strSourcePath.c_str() << endl;
	cout << "source ext: " << strDestPath.c_str() << endl;

	bool sortpal=false;
	bool imagepal=false;

	// get options from commandline.
	for (int i=2 ; i<argc ; i++)
	{
		// the palette is sorted by brightness
		if (!stricmp(argv[i], "sort"))
			sortpal=true;
		
		// store the palette in the order it is saved in the source image file. 
		if (!stricmp(argv[i], "imagepal"))
			imagepal=true;	
	}

	// convert sprites
	bool ret = ConvertSprites(strSourcePath, strDestPath, sortpal, imagepal);

	if (!ret)
	{		
		return -1;
	}

	return 0;
}

// convert sprites
bool ConvertSprites( const string &strSourcePath, const string& strDestPath, bool sortpal, bool imagepal )
{
	// load image
	Image image;

	if (!image.Load(strSourcePath.c_str()))
	{
		cout << "error! failed loading image: " << strSourcePath.c_str() << endl;
	
		return false;
	}

	int width = image.GetWidth();
	int height = image.GetHeight();
	
	// if size of image is 0 the image is not valid
	if (width < 1 ||
		height < 1)
	{
		cout << "error! image is too small (must have at least 1x1 pixel resolution): " << strSourcePath.c_str() << endl;
	
		return false;
	}
	
	// scan palette
	unsigned int* pal=NULL;
	int numcolors=0;

	if (imagepal)
	{
		//take the palette directly from the image
		if (!image.HasPalette())
		{
			cout << "error! image must have a palette: " << strSourcePath.c_str() << endl;

			return false;
		}

		pal=image.GetPalette();
		numcolors = image.GetPaletteSize();
	}
	else
	{
		// scan all pixels from the image and find all unique colors
		std::vector<unsigned int> usedcolors;

		for (int y=0 ; y<height ; y++)
		{
			for (int x=0 ; x<width ; x++)
			{
				unsigned int col=image.GetPixel(x, y);

				int numcols=usedcolors.size();

				bool found=false;

				for (int i=0 ; i<numcols ; i++)
				{
					if (col==usedcolors[i])
					{
						found=true;
						break;
					}
				}
				
				if (!found)
					usedcolors.push_back(col);
			}
		}

		numcolors=usedcolors.size();

		// copy color-set to the array
		pal=new unsigned int[numcolors];
		for (int i=0 ; i<numcolors ; i++)
		{
			pal[i]=usedcolors[i];
		}
	}

	bool attachmode=false;
	// sprites are only valid up to 16 colors
	if (numcolors>16)
	{
		cout << "error! image has too many colors (max 16): " << strSourcePath.c_str() << endl;

		return false;
	}

	if (numcolors>4)
	{
		// sprites with >4 colors use attach mode (2 sprites are combined to display 1 colorful sprite)
		attachmode=true;

		// attached sprites can only display up to 64 pixels width
		if (width>64)
		{
			cout << "error! image is too wide. attachmode sprites have max 64 pixels width: " << strSourcePath.c_str() << endl;

			return false;
		}
	}

	// sprites can only display up to 128 pixels width
	if (width>128)
	{
		cout << "error! image is too wide. sprites have max 128 pixels width: " << strSourcePath.c_str() << endl;

		return false;
	}

	if (sortpal)
	{
		// sort pal by brightness
		std::vector<int> brights;

		for (int i=0 ; i<numcolors ; i++)
		{
			unsigned int col=pal[i];
			
			int r=(col>>16) & 0xff;
			int g=(col>> 8) & 0xff;
			int b=(col    ) & 0xff;
			int bright=r+g+b;

			brights.push_back(bright);
		}

		for (int i=0 ; i<numcolors ; i++)
		{
			for (int j=0 ; j<i ; j++)
			{
				if (brights[i]<brights[j])
				{
					int tmpbright=brights[i];
					unsigned int tmpcolor=pal[i];
					brights[i]=brights[j];
					pal[i]=pal[j];
					brights[j]=tmpbright;
					pal[j]=tmpcolor;
				}
			}
		}
	}

	int numsprites = (width+15)/16;		// amount of sprites to display image width
	int datasize = numsprites*height*4;	// the datasize for the sprites

	if (attachmode)
		datasize*=2;					// in attachmode we need double size

	// dump stats
	cout << "num colors: " << numcolors << endl;
	cout << "numsprites: " << numsprites << endl;
	cout << "attachmode: " << attachmode << endl;
	cout << "height: " << height << endl;
	cout << "datasize: " << datasize << endl;
	

	// convert pal to amiga format (12 bit and 68k endianess)
	unsigned short* amipal = new unsigned short[numcolors];

	memset(amipal, 0, sizeof(unsigned short) * numcolors);

	for (int i=0 ; i<numcolors ; i++)
	{
		unsigned int col = pal[i];
		
		unsigned int r = (col>>16) & 0xff;
		unsigned int g = (col>> 8) & 0xff;
		unsigned int b = (col    ) & 0xff;

		r >>= 4;
		g >>= 4;
		b >>= 4;

		unsigned short amigacol = (r) | (g<<12) | (b<<8);

		amipal[i] = amigacol;
	}

	// extract sprite data
	unsigned char* sprdata = new unsigned char [datasize];

	memset(sprdata, 0, sizeof(unsigned char) * datasize);

	for (int y=0 ; y<height ; y++)
	{
		for (int x1=0 ; x1<numsprites ; x1++)
		{
			for (int x2=0 ; x2<16 ; x2++)
			{
				int x=x2+x1*16;

				unsigned char id=0;
				if (imagepal)
				{
					id=image.GetPixelIndex(x, y);
				}
				else
				{
					unsigned int col = image.GetPixel(x, y) & 0xffffff;
				
					for (int i=0 ; i<numcolors ; i++)
					{
						if (col==(pal[i] & 0xffffff))
						{
							id=i;
							break;
						}
					}
				}

				unsigned char bit = (0x01 << (7 - (x2 & 0x07)));
				
				if (attachmode)
				{
					int dataoff = x2/8 + x1*8 + y*numsprites*8;
					if (id & 1)
						sprdata[dataoff ] |= bit;
					if (id & 2)
						sprdata[dataoff+2] |= bit;
					if (id & 4)
						sprdata[dataoff+4] |= bit;
					if (id & 8)
						sprdata[dataoff+6] |= bit;
				}
				else
				{
					int dataoff = x2/8 + x1*4 + y*numsprites*4;
					if (id & 1)
						sprdata[dataoff ] |= bit;
					if (id & 2)
						sprdata[dataoff+2] |= bit;
				}
			}			
		}
	}

	// write data
	FILE* file = fopen(strDestPath.c_str(), "wb");
	if (file == 0)
	{
		cout << "error! failed writing file: " << strDestPath.c_str() << endl;

		return false;
	}

	// header
	unsigned short palsizeval = ConvToEndianShort(numcolors);
	unsigned short numspritesval = ConvToEndianShort(numsprites);
	unsigned short heightval = ConvToEndianShort(height);
	
	fwrite(&palsizeval, 1, sizeof(palsizeval), file);
	fwrite(&numspritesval, 1, sizeof(numspritesval), file);
	fwrite(&heightval, 1, sizeof(heightval), file);

	// palette
	fwrite(amipal, 2, numcolors, file);

	// sprite data
	fwrite(sprdata, 1, datasize, file);


	// free mem and close files
	fclose(file);

	delete [] amipal;
	delete [] sprdata;

	if (!imagepal)
	{
		delete [] pal;
	}

	return true;
}

////////////////////////////
// helper funtions
////////////////////////////

// get the next bigger integer pow2
int GetNextPow2(int iValue)
{
	int iCompare = 1;

	while( true )
	{
		if ( iValue <= iCompare )
		{
			return iCompare;
		}
		iCompare <<= 1;
	}
	return 0;
}

// get the next bigger integer log2
int GetLog2(int iValue)
{
	if ( 2 == iValue )
	{
		return 1;
	}
	if ( 4 == iValue )
	{
		return 2;
	}
	if ( 8 == iValue )
	{
		return 3;
	}
	if ( 16 == iValue )
	{
		return 4;
	}
	if ( 32 == iValue )
	{
		return 5;
	}
	if ( 64 == iValue )
	{
		return 6;
	}
	if ( 128 == iValue )
	{
		return 7;
	}
	if ( 256 == iValue )
	{
		return 8;
	}
	return 0;
}

// endianess swap a short
unsigned short ConvToEndianShort(int value)
{
	unsigned short res = ((value << 8) & 0xff00) | ((value >> 8) & 0xff);

	return res;
}

// endianess swap a long
unsigned long ConvToEndianLong(int value)
{
	unsigned long res = ((value << 24) & 0xff000000) | ((value << 8) & 0xff0000) | ((value >> 8) & 0xff00) | ((value >> 24) & 0xff);

	return res;
}

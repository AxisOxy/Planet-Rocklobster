/////////////////////////////////////////////////////////////////////////////
// Gfx-Converter by Michael "Axis" Hillebrandt.
// This tool converts any pc-image-fileformat to a simple amiga file-format 
// containing 12bit palette and bitplane data in 68k-endianess.
/////////////////////////////////////////////////////////////////////////////

#include "include.h"

bool ConvertImage(const string &strSourcePath, const string& strDestPath, bool sortpal, bool imagepal);
bool ConvertImageFli(const string &strSourcePath, const string& strDestPath);
int GetNextPow2(int iValue);
int GetLog2(int iValue);
unsigned short ConvToEndianShort(int value);
unsigned long ConvToEndianLong(int value);

int main( int argc, const char* argv[] )
{
	// if we have too less commandline arguments, show usage info.
	if ( argc < 3 )
	{
		cout << "usage gfxconv.exe <infile> <outfile> [n <optional params>]\n";
		cout << "optional params:\n";
		cout << "sort - sort palette by brightness\n";
		cout << "fli - store a palette per line of image\n";
		cout << "imagepal - use the palette stored in the image instead of generating one from the pixels\n";

		return -1;
	}

	// get source and dest path from command line.
	string strSourcePath( argv[ 1 ] );
	string strDestPath( argv[ 2 ] );
	
	cout << "source path: " << strSourcePath.c_str() << endl;
	cout << "source ext: " << strDestPath.c_str() << endl;

	// get options from commandline.
	bool sortpal=false;
	bool fli=false;
	bool imagepal=false;

	for (int i=2 ; i<argc ; i++)
	{
		// the palette is sorted by brightness
		if (!stricmp(argv[i], "sort"))
			sortpal=true;

		// fli-mode
		// this means a palette is stored for every single line of the image to allow more colors in a low bit depth. which can be easily displayed by amigas using a copperlist.
		// the term fli comes from the c-64 fli-image format which does something similar.
		if (!stricmp(argv[i], "fli"))
			fli=true;	
		
		// store the palette in the order it is saved in the source image file. 
		if (!stricmp(argv[i], "imagepal"))
			imagepal=true;	
	}
	
	bool ret;
	
	if (fli)	// convert as fli-image.
	{
        // sort & imagepal are not allowed in combination with fli
		if (sortpal || imagepal)
		{
			cout << "error! options sort & imagepal are not allowed in combination with fli: " << strSourcePath.c_str() << endl;
			return -1;
		}
	
		ret = ConvertImageFli(strSourcePath, strDestPath);
	}
	else	// convert as normal image
		ret = ConvertImage(strSourcePath, strDestPath, sortpal, imagepal);

	if (!ret)
	{		
		return -1;
	}

	return 0;
}

// convert image as normal-image (1 palette for the full image)
bool ConvertImage( const string &strSourcePath, const string& strDestPath, bool sortpal, bool imagepal )
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
	
	// if width<8 or height==0 the image is not valid
	if (width < 8 ||
		height < 1)
	{
		cout << "error! image is too small (must have at least 8x1 pixel resolution): " << strSourcePath.c_str() << endl;
	
		return false;
	}

	// image width must be multiple of 8
	if ((width & 0x07) != 0)
	{
		cout << "error! image width must be a multiple of 8: " << strSourcePath.c_str() << endl;
	
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

	int numbitplanes = GetLog2(GetNextPow2(numcolors)); // amount bitplanes
	int planewidth = width / 8;							// bitplane width in bytes
	int planesize = planewidth * height;				// bitplane size in bytes
	int imagesize = planesize * numbitplanes;			// image size in bytes

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

	// dump stats	
	cout << "num colors: " << numcolors << endl;
	cout << "num bitplanes: " << numbitplanes << endl;
	cout << "bitplane width: " << planewidth << endl;
	cout << "bitplane size: " << planesize << endl;
	cout << "image size: " << imagesize << endl;
	
	// for ocs we only support 1-5 bitplanes
	if (numbitplanes < 1 ||
		numbitplanes > 5)
	{
		cout << "error! num bitplanes must be between 1 and 5: " << strSourcePath.c_str() << endl;

		return false;
	}

	// convert pal to amiga format (12 bit and 68k endianess)
	unsigned short* amipal = new unsigned short[numcolors];
	unsigned char* bitplanes = new unsigned char [imagesize];

	memset(amipal, 0, sizeof(unsigned short) * numcolors);
	memset(bitplanes, 0, sizeof(unsigned char) * imagesize);

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

	// extract bitplanes
	for (int plane=0 ; plane<numbitplanes ; plane++)
	{
		for (int y=0 ; y<height ; y++)
		{
			for (int x1=0 ; x1<planewidth ; x1++)
			{
				for (int x2=0 ; x2<8 ; x2++)
				{
					int x=x2+x1*8;

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

					unsigned char bit = (id>>plane) & 0x01;

					bitplanes[x1 + y*planewidth + plane*planesize] |= (bit << (7 - x2));
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
	unsigned short bitplanewidthval = ConvToEndianShort(planewidth);
	unsigned short bitplanesizeval = ConvToEndianShort(planesize);
	unsigned long imagesizeval = ConvToEndianLong(imagesize);

	fwrite(&palsizeval, 1, sizeof(palsizeval), file);
	fwrite(&bitplanewidthval, 1, sizeof(bitplanewidthval), file);
	fwrite(&bitplanesizeval, 1, sizeof(bitplanesizeval), file);
	fwrite(&imagesizeval, 1, sizeof(imagesizeval), file);

	// palette
	fwrite(amipal, 2, numcolors, file);

	// bitplanes
	fwrite(bitplanes, 1, imagesize, file);

	// free mem and close files
	fclose(file);

	delete [] amipal;
	delete [] bitplanes;

	if (!imagepal)
	{
		delete [] pal;
	}

	return true;
}

// convert image as fli-image (1 palette per line of the image)
bool ConvertImageFli( const string &strSourcePath, const string& strDestPath )
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
	
	// if width<8 or height==0 the image is not valid
	if (width < 8 ||
		height < 1)
	{
		cout << "error! image is too small (must have at least 8x1 pixel resolution): " << strSourcePath.c_str() << endl;
	
		return false;
	}

	// image width must be multiple of 8
	if ((width & 0x07) != 0)
	{
		cout << "error! image width must be a multiple of 8: " << strSourcePath.c_str() << endl;
	
		return false;
	}

	// scan palettes
	typedef std::vector<unsigned int> ColorVec;
	
	int maxcolors=0;
	int maxcolorline=-1;
	std::vector<ColorVec> palettes;

	// global color state. This is used to store only the differences from line to line in the palette info.
	ColorVec colorlinebuffer;

	for (int y=0 ; y<height ; y++)
	{
		// for every line of the image collect the unique colors
		ColorVec newcolors;
		std::vector<bool> colorsused;

		for (int i=0 ; i<(int)(colorlinebuffer.size()) ; i++)
			colorsused.push_back(false);

		for (int x=0 ; x<width ; x++)
		{
			unsigned int col=image.GetPixel(x, y);

			bool found=false;

			for (int i=0 ; i<(int)(colorlinebuffer.size()) ; i++)
			{
				if (col==colorlinebuffer[i])
				{
					colorsused[i]=true;
					found=true;
					break;
				}
			}
			
			if (!found)
			{
				for (int i=0 ; i<(int)(newcolors.size()) ; i++)
				{
					if (col==newcolors[i])
					{
						found=true;
						break;
					}
				}
			}

			if (!found)
			{
				newcolors.push_back(col);
			}
		}

		for (int i=0 ; i<(int)(newcolors.size()) ; i++)
		{
			unsigned int col=newcolors[i];

			bool found=false;
			for (int j=0 ; j<(int)(colorsused.size()) ; j++)
			{
				if (!colorsused[j])
				{
					colorlinebuffer[j]=col;
					colorsused[j]=true;
					found=true;
					break;
				}
			}

			if (!found)
			{
				colorlinebuffer.push_back(col);
				colorsused.push_back(true);
			}
		}

		int numcolors = colorlinebuffer.size();
		
		if (numcolors>maxcolors)
		{
			maxcolors=numcolors;
			maxcolorline=y;
		}

		// store the palette for the line.
		palettes.push_back(colorlinebuffer);
	}
	
	int numbitplanes = GetLog2(GetNextPow2(maxcolors));	// num bitplanes
	int palsize = 1 << numbitplanes;					// size of palette
	int planewidth = width / 8;							// bitplane width in bytes
	int planesize = planewidth * height;				// bitplane size in bytes
	int imagesize = planesize * numbitplanes;			// image size in bytes

	// for ocs we only support 1-5 bitplanes
	if (numbitplanes < 1 ||
		numbitplanes > 5)
	{
		cout << "error! num bitplanes must be between 1 and 5: " << strSourcePath.c_str() << endl;

		return false;
	}

	// dump stats	
	cout << "max colors: " << maxcolors << " in line " << maxcolorline << endl;
	cout << "num bitplanes: " << numbitplanes << endl;
	cout << "palette size: " << palsize << endl;
	cout << "bitplane width: " << planewidth << endl;
	cout << "bitplane size: " << planesize << endl;
	cout << "image size: " << imagesize << endl;

	// convert palettes to amiga format (12 bit and 68k endianess)
	unsigned short* pal = new unsigned short[palsize*height];
	memset(pal, 0, sizeof(unsigned short) * palsize * height);

	colorlinebuffer.clear();
	
	for (int i=0 ; i<palsize ; i++)
		colorlinebuffer.push_back(0xffffffff);

	int palcount=0;

	for (int y=0 ; y<height ; y++)
	{
		int numusedcols=palettes[y].size();
		
		for (int i=0 ; i<numusedcols ; i++)
		{
			unsigned int col = palettes[y][i];

			if (col!=colorlinebuffer[i])
			{
				colorlinebuffer[i]=col;

				unsigned int r = (col>>16) & 0xff;
				unsigned int g = (col>> 8) & 0xff;
				unsigned int b = (col    ) & 0xff;

				r >>= 4;
				g >>= 4;
				b >>= 4;

				unsigned short amigacol = (r) | (g<<12) | (b<<8);

				pal[palcount++] = ConvToEndianShort(i);
				pal[palcount++] = amigacol;
			}			
		}
		pal[palcount++] = ConvToEndianShort(0xffff);
	}

	// extract bitplanes
	unsigned char* bitplanes = new unsigned char [imagesize];

	memset(bitplanes, 0, sizeof(unsigned char) * imagesize);

	for (int plane=0 ; plane<numbitplanes ; plane++)
	{
		for (int y=0 ; y<height ; y++)
		{
			int numusedcols=palettes[y].size();

			for (int x1=0 ; x1<planewidth ; x1++)
			{
				for (int x2=0 ; x2<8 ; x2++)
				{
					int x=x2+x1*8;

					unsigned int col = image.GetPixel(x, y);
					
					unsigned char id=0;

					for (int i=0 ; i<numusedcols ; i++)
					{
						if (col==palettes[y][i])
						{
							id=i;
							break;
						}
					}

					unsigned char bit = (id>>plane) & 0x01;

					bitplanes[x1 + y*planewidth + plane*planesize] |= (bit << (7 - x2));
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
	unsigned short palsizeval = ConvToEndianShort(palsize);
	unsigned short bitplanewidthval = ConvToEndianShort(planewidth);
	unsigned short bitplanesizeval = ConvToEndianShort(planesize);
	unsigned long imagesizeval = ConvToEndianLong(imagesize);

	fwrite(&palsizeval, 1, sizeof(palsizeval), file);
	fwrite(&bitplanewidthval, 1, sizeof(bitplanewidthval), file);
	fwrite(&bitplanesizeval, 1, sizeof(bitplanesizeval), file);
	fwrite(&imagesizeval, 1, sizeof(imagesizeval), file);

	// palettes
	fwrite(pal, 2, palcount, file);

	// bitplanes
	fwrite(bitplanes, 1, imagesize, file);

	// free mem and close files
	fclose(file);

	delete [] pal;
	delete [] bitplanes;

	return false;
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

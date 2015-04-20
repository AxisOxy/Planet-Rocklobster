//////////////////////////////////////////////////////////////////
// Amiga trackmo executable packer by Michael "Axis" Hillebrandt
// This packer parses and compresses Amiga executable hunks
// taking usage of the ultra fast (about 180 Kb/s on a stock A500)
// Doynamite68k raw data compressor by Johan "Doynax" Forslöf.
// The resulting executables are not runnable anymore from the
// amiga operating system, because the depacker is not included.
//////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <vector>
#include <process.h>
#include <windows.h>

// data structures and helper functions for 

// definitions for hunk header ids.
const unsigned int HUNK_HEADER=0x3F3;
const unsigned int HUNK_CODE=0x3E9;
const unsigned int HUNK_DATA=0x3EA;
const unsigned int HUNK_BSS=0x3EB;
const unsigned int HUNK_RELOC32=0x3EC;

// enum for amiga memory types.
enum MEM_TYPE
{
	MEM_GENERIC	= 0,	// generic memory, doesnt matter if fast or chipmem
	MEM_CHIP	= 1,	// chip mem
	MEM_FAST	= 2,	// fast mem
	MEM_STRANGE	= 3		// Indicates an additional following longword containing the specific flags, of which bit 30 gets cleared before use. Never happened in one of my files!
};

// struct defining a hunk
struct Hunk
{
	unsigned int	hunktype;	// hunk header id
	MEM_TYPE		memtype;	// memory type to load the hunk into
	unsigned int	numints;	// size of hunk in integers
	unsigned int*	buffer;		// the buffer containing the hunk data
};
typedef std::vector<Hunk> Hunks;	// definition for list of hunks

// struct defining a relocation entry
struct RelocEntry
{
	unsigned int	targethunk;	// the index of the target hunk
	unsigned int	numoffsets;	// the amount of offsets
	unsigned int*	offsets;	// list of offsets into the target hunk
};
typedef std::vector<RelocEntry> RelocEntries;	// definition for list of relocations

// struct defining a complete relocation hunk
struct RelocHunk
{
	unsigned int	sourcehunk;	// the index of the source hunk
	RelocEntries	entries;	// the list of relocations
};
typedef std::vector<RelocHunk> RelocHunks;	// definition for list of relocation hunks

// Helper function to endian swap an array of shorts 
void SwapArrayShort( unsigned short* data, int count )
{
	for (int i=0 ; i<count ; i++)
	{
		unsigned short val=data[i];

		data[i]=(val<<8) | (val>>8);
	}
}

// Helper function to endian swap an array of ints 
void SwapArrayInt( unsigned int* data, int count )
{
	for (int i=0 ; i<count ; i++)
	{
		unsigned int val=data[i];

		data[i]=(val<<24) | ((val & 0xff00)<<8) | ((val & 0xff0000)>>8) | (val>>24);
	}
}

// Wrapper for reading chars from a file
int ReadChars( void* buffer, int count, FILE* filer )
{
	return fread(buffer, sizeof(char), count, filer);
}

// Wrapper for reading shorts from a file including endian swap
int ReadShorts( void* buffer, int count, FILE* filer )
{
	int ret=fread(buffer, sizeof(short), count, filer);

	SwapArrayShort((unsigned short*)(buffer), count);

	return ret;
}

// Wrapper for reading ints from a file including endian swap
int ReadInts( void* buffer, int count, FILE* filer )
{
	int ret=fread(buffer, sizeof(int), count, filer);

	SwapArrayInt((unsigned int*)(buffer), count);

	return ret;
}

// Helper function to read a string with leading string length from a file
int ReadString( char* buffer, int bufsize, FILE* filer )
{
	int len=0;

	ReadInts(&len, 1, filer);

	memset(buffer, 0, bufsize);

	if (strlen>0)
	{
		ReadChars(buffer, len, filer);
		buffer[len]=0;
	}

	return len;
}

// Wrapper for writing chars to a file
int WriteChars( void* buffer, int count, FILE* filew )
{
	return fwrite(buffer, sizeof(char), count, filew);
}

// Wrapper for writing shorts to a file including endian swap
int WriteShorts( void* buffer, int count, FILE* filew )
{
	SwapArrayShort((unsigned short*)(buffer), count);

	int ret=fwrite(buffer, sizeof(short), count, filew);

	SwapArrayShort((unsigned short*)(buffer), count);

	return ret;
}

// Wrapper for writing ints to a file including endian swap
int WriteInts( void* buffer, int count, FILE* filew )
{
	SwapArrayInt((unsigned int*)(buffer), count);

	int ret=fwrite(buffer, sizeof(int), count, filew);

	SwapArrayInt((unsigned int*)(buffer), count);

	return ret;
}

// Helper function to write a string with leading string length to a file
int WriteString( char* buffer, FILE* filew )
{
	int len=strlen(buffer);

	WriteInts(&len, 1, filew);
	
	if (strlen>0)
	{
		WriteChars(buffer, len, filew);
	}

	return len;
}

// Compress one hunk raw data using the doynamite68k compressor. the lz.exe must be present in the working directory.
bool CompressHunk( void* srcdata, int srcsize, void* dstdata, int* dstsize, int maxsize )
{
	FILE* filew=fopen("tmp.dat", "wb");
	fwrite(srcdata, 1, srcsize, filew);
	fclose(filew);

	int ret=_spawnl(_P_WAIT, "lz.exe", "lz.exe", "-o tmp.doy tmp.dat", NULL);

	FILE* filer=fopen("tmp.doy", "rb");
	fseek(filer, 0, SEEK_END);
	int size=(ftell(filer)+3) & 0xfffffffc;
	if (size<4 || size>maxsize)
	{
		*dstsize=0;
		fclose(filer);
		return false;
	}

	*dstsize=size;

	fseek(filer, 0, SEEK_SET);
	fread(dstdata, 1, size, filew);
	fclose(filer);

	return true;
}


////////////////////////////////////////////////////
// main function
////////////////////////////////////////////////////
void main(int argc, char **argv)
{
	// if we have too less commandline arguments, show usage info.
	if(argc < 3) 
	{
    	printf("usage %s <infile> <outfile>\n", argv[0]);
        exit(-1);
	}

	// get input and output filenames from commandline.
	const char* filername=argv[1];
	const char* filewname=argv[2];

	// reserve 1mb of data for every single file, should be always enough for an ocs demo.
	const int TMP_DATA_SIZE=1024*1024;
	unsigned char* tmpdata=new unsigned char[TMP_DATA_SIZE];

	// open input file.
	FILE* filer=fopen(filername, "rb");
	if(!filer) 
	{
		printf("cannot open \"%s\"\n", filername);
		exit(-1);
	}

	// read header
	unsigned int hunk_id=0;
	ReadInts(&hunk_id, 1, filer);

	// if first hunk is not a header hunk, this is no valid amiga executable.
	if (hunk_id!=HUNK_HEADER)
	{
		printf("file \"%s\" is not a valid amiga executable\n", filername);
		exit(-1);
	}

	// open output file
	FILE* filew=fopen(filewname, "wb");
	if(!filew) 
	{
	 	printf("cannot open \"%s\"\n", filewname);
		exit(-1);
	}
	
	// write header hunk id
	WriteInts(&hunk_id, 1, filew);

	char line[256];

	// read and copy list of libraries used in this executable from source to destination file.
	while(true)
	{
		if (ReadString(line, 256, filer)==0)
			break;

		WriteString(line, filew);
	}
	WriteString(line, filew);

	// read and copy global hunk statistics from source to destination file.
	unsigned int tablesize=0;
	unsigned int firsthunk=0;
	unsigned int lasthunk=0;

	ReadInts(&tablesize, 1, filer);
	ReadInts(&firsthunk, 1, filer);
	ReadInts(&lasthunk, 1, filer);
	
	WriteInts(&tablesize, 1, filew);
	WriteInts(&firsthunk, 1, filew);
	WriteInts(&lasthunk, 1, filew);
	
	// if we have no hunks, this is not a valid amiga executable
	unsigned int numhunks=lasthunk+1-firsthunk;

	if (numhunks<1)
	{
		printf("file \"%s\" has no hunks\n", filername);
		exit(-1);
	}

	// read and copy hunk sizes from source to destination file.
	unsigned int* hunksizes=new unsigned int[numhunks];
	
	unsigned int fullsize=0;
	for (unsigned int i=firsthunk ; i<=lasthunk ; i++)
	{
		ReadInts(&hunksizes[i], 1, filer);
		WriteInts(&hunksizes[i], 1, filew);
		fullsize+=hunksizes[i]*4;
	}

	// loop through the hunks

	Hunks hunks;
	RelocHunks relochunks;
	unsigned int  hunkcount=0;

	while(true)
	{
		// read and copy hunk id
		if (!ReadInts(&hunk_id, 1, filer))
		{
			break;
		}
		WriteInts(&hunk_id, 1, filew);

		switch(hunk_id)
		{
			case HUNK_CODE:
			case HUNK_DATA:
			{
				// code and data hunks are basically the same for us
				Hunk hunk;

				// determine hunksize
				int hunksize=hunksizes[hunkcount++];

				// determine memtype
				hunk.hunktype=hunk_id;
				hunk.memtype=(MEM_TYPE)(hunksize>>30);

				// read and copy hunk size
				ReadInts(&hunk.numints, 1, filer);
				WriteInts(&hunk.numints, 1, filew);

				// show info about memtype
				if (hunk.memtype==MEM_CHIP)
					printf("hunk_data_chip: %d bytes\n", hunk.numints*4);
				else
					printf("hunk_data     : %d bytes\n", hunk.numints*4);
	
				// alloc hunk buffer and read hunk data
				hunk.buffer=new unsigned int[hunk.numints];
			
				ReadInts(hunk.buffer, hunk.numints, filer);

				int tmpsize=0;

				memset(tmpdata, 0, TMP_DATA_SIZE);

				// swap endianess on buffer
				SwapArrayInt((unsigned int*)(hunk.buffer), hunk.numints);

				// compress the hunk using doynamite68k
				if (!CompressHunk(hunk.buffer, hunk.numints*sizeof(int), tmpdata, &tmpsize, TMP_DATA_SIZE))
				{
					printf("error on compressing hunk in file \"%s\"\n", filername);
					exit(-1);
				}

				// wrtite the compressed hunk data
				WriteChars(tmpdata, tmpsize, filew);
				
				// swap endianess on buffer back to preserve original state
				SwapArrayInt((unsigned int*)(hunk.buffer), hunk.numints);

				// write the hunk to the list of hunks
				hunks.push_back(hunk);
			}
			break;

			case HUNK_BSS:
			{
				Hunk hunk;

				// determine hunksize
				int hunksize=hunksizes[hunkcount++];

				// determine memtype
				hunk.hunktype=hunk_id;
				hunk.memtype=(MEM_TYPE)(hunksize>>30);

				// read and copy hunk size
				ReadInts(&hunk.numints, 1, filer);
				WriteInts(&hunk.numints, 1, filew);

				// show info about memtype
				if (hunk.memtype==MEM_CHIP)
					printf("hunk_bss_chip : %d bytes\n", hunk.numints*4);
				else
					printf("hunk_bss      : %d bytes\n", hunk.numints*4);
				
				// alloc hunk buffer
				hunk.buffer=new unsigned int[hunk.numints];
			
				// write the hunk to the list of hunks
				hunks.push_back(hunk);
			}
			break;

			case HUNK_RELOC32:
			{
				RelocHunk relochunk;

				// determind source hunk id
				relochunk.sourcehunk=hunkcount-1;

				int chunksize=0;

				while (true)
				{
					RelocEntry relocentry;
					
					// read and copy targethunk and num offsets
					ReadInts(&relocentry.numoffsets, 1, filer);
					ReadInts(&relocentry.targethunk, 1, filer);
	
					WriteInts(&relocentry.numoffsets, 1, filew);
					WriteInts(&relocentry.targethunk, 1, filew);

					chunksize+=8;

					// if the hunk is empty, stop
					if (relocentry.numoffsets==0)
					{
						break;
					}

					// alloc mem for relocation offsets
					relocentry.offsets=new unsigned int[relocentry.numoffsets];
				
					// loop through offsets
					for (unsigned int i=0 ; i<relocentry.numoffsets ; i++)
					{
						// read relocation offset
						ReadInts(&relocentry.offsets[i], 1, filer);

						// if the offset is odd, this is not valid on 68000
						if (relocentry.offsets[i] & 1)
						{
							printf("relocation to odd adress is not valid!\n");
							exit(-1);
						}

						// divide offset by 2, so we can access 128kb max offset size with 16 bit. this saves some memory/disk-space, because relocation hunks are not compressed, yet.
						unsigned short offset=(unsigned short)(relocentry.offsets[i]/2);

						// error handling for too big relocation offsets
						if (offset>=0x10000)
						{
							printf("relocations to chunks bigger than 128KB is not valid!\n");
							exit(-1);
						}
					
						// write the patched offset
						WriteShorts(&offset, 1, filew);

						chunksize+=2;
					}
					
					// store relocation entry to list
					relochunk.entries.push_back(relocentry);
				}

				// show statistics about relocation hunk
				printf("hunk_reloc    : %d bytes\n", chunksize);

				// if we are not 32bit aligned, add some padding
				if (chunksize & 0x02)
				{
					unsigned short padding=0;
			
					WriteShorts(&padding, 1, filew);

					chunksize+=2;
				}

				// store relocation hunk in list
				relochunks.push_back(relochunk);
			}
			break;
		}
	}

	// remove temp-files
	remove("tmp.dat");
	remove("tmp.doy");

	// close files and free memory
	fclose(filer);
	fclose(filew);

	delete tmpdata;
	delete hunksizes;
}

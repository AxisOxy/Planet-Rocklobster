#include "include.h"

FileR::FileR( const char *_filename )
{
	filesize=0;
	fp=fopen(_filename,"rb");
	if (fp)
	{
		Seek(0, SeekEnd);
		filesize=Tell();
		Seek(0, SeekSet);
	}
}

FileR::~FileR( void )
{
	if (fp)		
		fclose(fp);
}

int FileR::GetSize( void )
{
	return filesize;
}

int FileR::Read( void *buffer, int size, int count )
{
	if (fp)
		return fread(buffer,size,count,fp);
	
	return 0;
}

bool FileR::ReadLine( char *string, int n )
{
	if (fp)
	{
		if (fgets(string,n,fp))
		{
			int len=strlen(string);

			for (int i=0 ; i<len ; i++)
			{
				if (string[i]=='\r' ||
					string[i]=='\n')
				{
					string[i]=0;
					break;
				}
			}

			return true;
		}
	}
	return false;
}

int FileR::Seek( int offset, SeekOrigin origin )
{
	if (fp)
		return fseek(fp,offset,origin);
	
	return -1;
}

int FileR::Tell( void )
{
	if (fp)
		return ftell(fp);
	
	return -1;
}

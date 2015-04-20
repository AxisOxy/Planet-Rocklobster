#include "include.h"

FileW::FileW( const char *_filename )
{
	fp=fopen(_filename,"wb");
}

FileW::~FileW( void )
{
	if (fp)		
		fclose(fp);
}

int FileW::Write( const void *buffer, int size, int count )
{
	if (fp)
	{
		return fwrite(buffer,size,count,fp);
	}
	return 0;
}

bool FileW::WriteLine( const char* line )
{
	if (fp)
	{
		fputs(line, fp);
		fputs("\r\n", fp);

		return true;
	}
	return false;
}

void FileW::Seek( int offset, SeekOrigin origin )
{
	if (fp)
	{
		fseek(fp, offset, origin);
	}
}

int FileW::Tell( void )
{
	if (fp)
	{
		return ftell(fp);
	}
	return 0;
}

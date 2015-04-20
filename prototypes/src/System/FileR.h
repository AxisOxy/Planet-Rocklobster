#ifndef _FILER_H
#define _FILER_H

// definition of seek modes
enum SeekOrigin
{
	SeekSet = SEEK_SET,	// seek absolute
	SeekCur = SEEK_CUR,	// seek relative
	SeekEnd = SEEK_END	// seek relative to eof
};

// wrapper class for reading file access
class FileR
{
private:
	FILE	*fp;
	int		filesize;
	
public:
	// ctor with filename. opens the given file.
	FileR ( const char *_filename );

	// dtor. closes the opened file
	~FileR( void );

	// return the size of the file
	int	 GetSize	( void );

	// read size*count bytes from the file into the buffer and return the read amount of bytes. just like fread
	int	 Read		( void *buffer, int size, int count );

	// read a line from a text-file until a line-feed is found
	bool ReadLine	( char *string, int n );

	// seek to the given file-position in bytes
	int  Seek		( int offset, SeekOrigin origin );

	// return the actual seek-position in bytes
	int  Tell		( void );
};

#endif // _FILER_H

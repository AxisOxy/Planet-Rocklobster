#ifndef _FILEW_H
#define _FILEW_H

// wrapper class for writing file access
class FileW
{
private:
	FILE	*fp;
	
public:
	// ctor with filename. opens the given file.
	FileW ( const char *_filename );

	// dtor. closes the opened file
	~FileW( void );

	// write size*count bytes from the buffer into the file and return the written amount of bytes. just like fwrite
	int		Write		( const void *buffer, int size, int count );

	// write a line to a text-file until and add a line-feed
	bool	WriteLine	( const char* line );

	// seek to the given file-position in bytes
	void	Seek		( int offset, SeekOrigin origin );

	// return the actual seek-position in bytes
	int		Tell		( void );
};

#endif // _FILEW_H

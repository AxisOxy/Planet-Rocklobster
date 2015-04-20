#ifndef _SRDISPLAY_H
#define _SRDISPLAY_H

// directx windowproc callback
LONG CALLBACK	WindowProc( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam );

// a class for wrapping a direct draw window
class Display2D
{
	private:
		HINSTANCE				hInst,hPrev;
		HWND					hwnd;
		BOOL					Ready;
		char					Appname[MAX_STRINGLENG];

		int						xsize,ysize,xpos,ypos,windowxoff,windowyoff,depth;
		BOOL					Fullscreen;
		
		BOOL					Quit;
		
		void					*buffer;
		int						realdepth,pitch;
		
		LPDIRECTDRAW7			DDraw;
		LPDIRECTDRAWSURFACE7	FrontBuffer,BackBuffer;
			
	public:
		// ctor with params (creates the window)
		Display2D ( HINSTANCE _hInst, HINSTANCE _hPrev, char *_Appname, int _xpos, int _ypos, int _xsize, int _ysize, int _depth, BOOL _Fullscreen );

		// standard dtor (destroys the window)
		~Display2D(void);
		
		// windowproc. will be called from the global windowproc
		LONG	WindowProc		( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam );

		// lock the window
		BOOL	Lock			( void );

		// unlock the window
		void	Unlock			( void );

		// blit the given (A8R8G8B8) buffer to the window. blitting is only allowed on a locked window.
		void	Blit			( unsigned int *pic, int xpos, int ypos, int xsize, int ysize );

		// flip the window (double-buffering)
		void	Flip			( void );

		// clear the window to 0
		void	ClearBuffers	( void );

		// return if the window is active
		BOOL	GetReadyFlag	( void );

		// return if the window was closed by the user
		BOOL	GetQuitMessage	( void );

		// return the 2d-position of the mouse-cursor
		void	GetCursorPos	( POINT* cursorpos );


	private:
		BOOL	RestoreBuffers	( void );
		BOOL	CreateMyWindow	( void );
		void	Move			( int x, int y );
		BOOL	CreateDirectDraw( void );
		BOOL	CreateBuffers	( void );
		void	Blit15			( unsigned int *pic, int xpos, int ypos, int xsize, int ysize );
		void	Blit16			( unsigned int *pic, int xpos, int ypos, int xsize, int ysize );
		void	Blit24			( unsigned int *pic, int xpos, int ypos, int xsize, int ysize );
		void	Blit32			( unsigned int *pic, int xpos, int ypos, int xsize, int ysize );
};	

#endif // _SRDISPLAY_H

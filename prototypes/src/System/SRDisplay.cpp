#include "include.h"

LONG CALLBACK WindowProc( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
	Display2D	*display;

	if (msg==WM_DESTROY)
		return 0;

	display=(Display2D*)GetWindowLong(hwnd,GWL_USERDATA);
	if (display)
		return display->WindowProc(hwnd,msg,wParam,lParam);

	return DefWindowProc(hwnd,msg,wParam,lParam);
}

LONG Display2D::WindowProc( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
	RECT	windowrect;

	switch (msg)
	{
		case WM_CLOSE:
			Quit=TRUE;
			return 0;
		break;

		case WM_SIZE:
		case WM_MOVE:
		case WM_DISPLAYCHANGE:
			if (!Fullscreen && Ready && !IsIconic(hwnd))
			{
				GetWindowRect(hwnd,&windowrect);
				Move((SHORT)LOWORD(lParam),(SHORT)HIWORD(lParam));
				return 0;
			}
		break;

		case WM_ERASEBKGND:
			return 1;

		case WM_ACTIVATEAPP:
			Ready=wParam;
			return 0;
		break;

		case WM_MOUSEMOVE:
		break;
	}
	return DefWindowProc(hwnd,msg,wParam,lParam);
}

Display2D::Display2D( HINSTANCE _hInst, HINSTANCE _hPrev, char *_Appname, int _xpos, int _ypos, int _xsize, int _ysize, int _depth, BOOL _Fullscreen )
{
	RECT	windowrect;

	Quit=FALSE;

	DDraw=NULL;
	FrontBuffer=BackBuffer=NULL;
	
	buffer=NULL;
	realdepth=0;
	pitch=0;

	hInst=_hInst;
	hPrev=_hPrev;
	hwnd=NULL;

	strcpy(Appname,_Appname);

	windowxoff=windowyoff=0;
	xpos=_xpos;
	ypos=_ypos;
	xsize=_xsize;
	ysize=_ysize;
	depth=_depth;
	Fullscreen=_Fullscreen;
	Ready=TRUE;

	CreateMyWindow();
	CreateDirectDraw();
	CreateBuffers();

	if(!Fullscreen)
	{
		GetWindowRect(hwnd,&windowrect);
		SetCursorPos(windowrect.left+(xsize>>1),windowrect.top+(ysize>>1));
	}
	else
		SetCursorPos(xsize>>1,ysize>>1);
}

Display2D::~Display2D(void)
{
	if(BackBuffer)
	{
		BackBuffer->Release();
		BackBuffer=NULL;
	}

	if (FrontBuffer)
	{
		FrontBuffer->Release();
		FrontBuffer=NULL;
	}

	DDraw->SetCooperativeLevel(hwnd,DDSCL_NORMAL);
	DDraw->Release();

	if(hwnd)
	{
		SetWindowLong(hwnd,GWL_USERDATA,NULL);
		DestroyWindow(hwnd);
		hwnd=NULL;
	}
}

BOOL Display2D::CreateMyWindow( void )
{
	WNDCLASSEX	cls;

	if (!hPrev)
	{
		cls.cbSize=sizeof(WNDCLASSEX);
		if (!GetClassInfoEx(hInst,Appname,&cls))
		{
 			cls.cbSize			= sizeof(WNDCLASSEX);
			cls.hCursor			= NULL;
			cls.hIcon			= NULL;
			cls.hIconSm			= NULL;
			cls.lpszMenuName	= NULL;
			cls.lpszClassName	= Appname;
			cls.hbrBackground	= (HBRUSH)GetStockObject(BLACK_BRUSH);
			cls.hInstance		= hInst;
			cls.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
			cls.lpfnWndProc		= (WNDPROC)::WindowProc;
			cls.cbClsExtra		= 0;
			cls.cbWndExtra		= 0;

			if (!RegisterClassEx(&cls))
				return FALSE;
		}
	}

	if (!Fullscreen)
	{
		int	borderxsize,borderysize,titleysize,fullxsize,fullysize;

		borderxsize=GetSystemMetrics(SM_CXFRAME)+GetSystemMetrics(SM_CXBORDER);
		borderysize=GetSystemMetrics(SM_CYFRAME)+GetSystemMetrics(SM_CYBORDER);
		titleysize =GetSystemMetrics(SM_CYCAPTION);
		fullxsize=xsize+(borderxsize<<1);
		fullysize=ysize+(borderysize<<1)+titleysize;

		windowxoff=borderxsize;
		windowyoff=(borderysize+titleysize);

		hwnd=CreateWindowEx(WS_EX_OVERLAPPEDWINDOW | WS_EX_APPWINDOW | WS_EX_DLGMODALFRAME,
							Appname,
							Appname,
							WS_OVERLAPPED | WS_SYSMENU | WS_CAPTION | WS_POPUP |
							WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
							xpos,ypos,
							fullxsize,fullysize,	// Size
							0,						// Parent window (no parent)
							0,						// use class menu
							0,						// hInstApp
							0						// no params to pass on
							);
	}
	else
	{
		hwnd=CreateWindowEx(  WS_EX_TOPMOST,
							  Appname,					// Class name
							  Appname,					// Caption
							  WS_POPUP | WS_VISIBLE,
							  0, 0,						// Position
							  xsize,
							  ysize,
							  0,						// Parent window (no parent)
							  0,						// use class menu
							  hInst,					// handle to window instance
							  0							// no params to pass on
							  );
	}

	if(!hwnd) 
		return FALSE;

	SetWindowLong(hwnd,GWL_USERDATA,LONG(this));
	ShowWindow(hwnd,SW_SHOW);
	UpdateWindow(hwnd);
	return TRUE;
}

void Display2D::Move( int x, int y )
{
	xpos=x-windowxoff;
	ypos=y-windowyoff;
}

BOOL Display2D::GetReadyFlag( void )
{
	return Ready;
}

BOOL Display2D::GetQuitMessage( void )
{
	MSG msg;

	if (!Ready)
		WaitMessage();
	
	while (PeekMessage(&msg,0,0,0,PM_REMOVE))
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}	
	return Quit;
}

void Display2D::GetCursorPos( POINT* cursorpos )
{
	::GetCursorPos( cursorpos );
	cursorpos->x -= xpos;
	cursorpos->y -= ypos;
}

BOOL Display2D::CreateDirectDraw( void )
{
	HRESULT	res;

	res=DirectDrawCreateEx(NULL,(void**)&DDraw,IID_IDirectDraw7,NULL);
	if (res!=DD_OK)
		return FALSE;

	if(Fullscreen)
		res=DDraw->SetCooperativeLevel(hwnd,DDSCL_ALLOWREBOOT|DDSCL_EXCLUSIVE|DDSCL_FULLSCREEN);
	else
		res=DDraw->SetCooperativeLevel(hwnd,DDSCL_NORMAL);

	if (res!=DD_OK)
        return FALSE;

	return TRUE;
}

BOOL Display2D::CreateBuffers( void )
{
	HRESULT				res;
	DDSURFACEDESC2		ddsd;
	DDSCAPS2			ddscaps;
	LPDIRECTDRAWCLIPPER	Clipper;
	
	if (Fullscreen)
	{
		res=DDraw->SetDisplayMode(xsize,ysize,depth,0,0);
		if (res!=DD_OK)
			return FALSE;

		ZeroMemory(&ddsd,sizeof(ddsd));
		ddsd.dwSize=sizeof(ddsd);
		ddsd.dwFlags=DDSD_CAPS|DDSD_BACKBUFFERCOUNT;
		ddsd.ddpfPixelFormat.dwSize=sizeof(DDPIXELFORMAT);
		ddsd.ddsCaps.dwCaps=DDSCAPS_PRIMARYSURFACE|DDSCAPS_VIDEOMEMORY|DDSCAPS_FLIP|DDSCAPS_COMPLEX;
		ddsd.dwBackBufferCount=1;

		res=DDraw->CreateSurface(&ddsd,&FrontBuffer,NULL);
		if (res!=DD_OK)
			return FALSE;
	
		memset(&ddscaps,0,sizeof(ddscaps));
		ddscaps.dwCaps=DDSCAPS_BACKBUFFER|DDSCAPS_VIDEOMEMORY;
		FrontBuffer->GetAttachedSurface(&ddscaps,&BackBuffer);
		if (res!=DD_OK)
			return FALSE;
	}
	else
	{
		ZeroMemory(&ddsd,sizeof(ddsd));
		ddsd.dwSize=sizeof(ddsd);
		ddsd.dwFlags=DDSD_CAPS;
		ddsd.ddpfPixelFormat.dwSize=sizeof(DDPIXELFORMAT);
		ddsd.ddsCaps.dwCaps=DDSCAPS_PRIMARYSURFACE;

		res=DDraw->CreateSurface(&ddsd,&FrontBuffer,NULL);
		if (res!=DD_OK)
			return FALSE;
		
		res=DDraw->CreateClipper(0,&Clipper,NULL);
		if (res!=DD_OK)
			return FALSE;
	
		Clipper->SetHWnd(0,hwnd);
		FrontBuffer->SetClipper(Clipper);
		Clipper->Release();

		ddsd.dwFlags=DDSD_WIDTH|DDSD_HEIGHT|DDSD_CAPS;
		ddsd.dwWidth=xsize;
		ddsd.dwHeight=ysize;
		ddsd.ddsCaps.dwCaps=DDSCAPS_SYSTEMMEMORY;

		res=DDraw->CreateSurface(&ddsd,&BackBuffer,NULL);
		if (res!=DD_OK)
			return FALSE;
	}

	ddsd.dwFlags=DDSD_WIDTH|DDSD_HEIGHT|DDSD_CAPS;
	ddsd.dwWidth=xsize;
	ddsd.dwHeight=ysize;
	ddsd.ddsCaps.dwCaps=DDSCAPS_SYSTEMMEMORY;

	ClearBuffers();

	return TRUE;
}

BOOL Display2D::Lock( void )
{
	unsigned int	rmask;
	HRESULT			res;
	DDSURFACEDESC2	ddsd;

	if (!RestoreBuffers())
		return FALSE;

	memset(&ddsd,0,sizeof(ddsd));
	ddsd.dwSize=sizeof(ddsd);
	res=BackBuffer->Lock(NULL,&ddsd,DDLOCK_WAIT,NULL);
	if(res!=DD_OK)
		return FALSE;

	switch(ddsd.ddpfPixelFormat.dwRGBBitCount)
	{
		case 16:
			rmask=ddsd.ddpfPixelFormat.dwRBitMask;
			if(rmask==0x0000f800)
				realdepth=16;
			else
				realdepth=15;
		break;

		case 24:
			realdepth=24;
		break;

		case 32:
			realdepth=32;
		break;
	}
	buffer=ddsd.lpSurface;
	pitch=ddsd.lPitch;

	return TRUE;
}

void Display2D::Unlock( void )
{
	if (!RestoreBuffers())
		return;

	BackBuffer->Unlock(NULL);
	buffer=NULL;
}

void Display2D::Blit( unsigned int *pic, int xpos, int ypos, int xsize, int ysize )
{
	if (!buffer || !pic)
		return;

	switch(realdepth)
	{
		case 15:
			Blit15(pic,xpos,ypos,xsize,ysize);
		break;

		case 16:
			Blit16(pic,xpos,ypos,xsize,ysize);
		break;
		
		case 24:
			Blit24(pic,xpos,ypos,xsize,ysize);
		break;
		
		case 32:
			Blit32(pic,xpos,ypos,xsize,ysize);
		break;
	}
}

void Display2D::Blit15( unsigned int *pic, int xpos, int ypos, int xsize, int ysize )
{
	int				x,y;
	unsigned int	co;
	unsigned char	*buf;
	unsigned short	*buf2;

	buf=(unsigned char*)(buffer)+(xpos<<1)+ypos*pitch;
	for (y=0 ; y<ysize ; y++)
	{
		buf2=(unsigned short*)buf;
		for (x=0 ; x<xsize ; x++)
		{
			co=*pic++;
			*buf2++=((co>>9) & 0x7c00) | ((co>>6) & 0x3e0) | ((co>>3) & 0x1f);
		}
		buf=buf+pitch;
	}
}

void Display2D::Blit16( unsigned int *pic, int xpos, int ypos, int xsize, int ysize )
{
	int				x,y;
	unsigned int	co;
	unsigned char	*buf;
	unsigned short	*buf2;

	buf=(unsigned char*)(buffer)+(xpos<<1)+ypos*pitch;
	for (y=0 ; y<ysize ; y++)
	{
		buf2=(unsigned short*)buf;
		for (x=0 ; x<xsize ; x++)
		{
			co=*pic++;
			*buf2++=((co>>8) & 0xf800) | ((co>>5) & 0x7e0) | ((co>>3) & 0x1f);
		}
		buf=buf+pitch;
	}
}

void Display2D::Blit24( unsigned int *pic, int xpos, int ypos, int xsize, int ysize )
{
	int				x,y;
	unsigned int	co;
	unsigned char	*buf,*buf2;

	buf=(unsigned char*)(buffer)+xpos*3+ypos*pitch;
	for (y=0 ; y<ysize ; y++)
	{
		buf2=buf;
		for (x=0 ; x<xsize ; x++)
		{
			co=*pic++;
			*buf2++=(co>>16) & 0xff;
			*buf2++=(co>> 8) & 0xff;
			*buf2++=(co    ) & 0xff;
		}
		buf=buf+pitch;
	}
}

void Display2D::Blit32( unsigned int *pic, int xpos, int ypos, int xsize, int ysize )
{
	int				x,y;
	unsigned char	*buf;
	unsigned int	*buf2;

	buf=(unsigned char*)(buffer)+(xpos<<2)+ypos*pitch;
	for (y=0 ; y<ysize ; y++)
	{
		buf2=(unsigned int*)buf;
		for (x=0 ; x<xsize ; x++)
			*buf2++=*pic++;

		buf=buf+pitch;
	}
}

void Display2D::Flip( void )
{
	RECT	sourcerect,destrect;

	if (RestoreBuffers())
	{
		if (Fullscreen)
		{
			sourcerect.left	 =0;
			sourcerect.top	 =0;
			sourcerect.right =xsize;
			sourcerect.bottom=ysize;
			destrect.left	 =0;
			destrect.top	 =0;
			destrect.right	 =xsize;
			destrect.bottom	 =ysize;
			FrontBuffer->Flip(NULL,DDFLIP_WAIT);
			BackBuffer->Blt(&destrect,FrontBuffer,&sourcerect,DDBLT_WAIT,NULL);
		}
		else
		{
			sourcerect.left	 =0;
			sourcerect.top	 =0;
			sourcerect.right =xsize;
			sourcerect.bottom=ysize;
			destrect.left	 =xpos+windowxoff;
			destrect.top	 =ypos+windowyoff;
			destrect.right	 =xpos+windowxoff+xsize;
			destrect.bottom	 =ypos+windowyoff+ysize;
			FrontBuffer->Blt(&destrect,BackBuffer,&sourcerect,DDBLT_WAIT,NULL);
		}
	}
}

void Display2D::ClearBuffers( void )
{
	DDBLTFX		bltfx;
	RECT		rect;

	if (RestoreBuffers())
	{
		rect.left  =xpos+windowxoff;
		rect.top   =ypos+windowyoff;
		rect.right =xpos+windowxoff+xsize;
		rect.bottom=ypos+windowyoff+ysize;

		memset(&bltfx,0,sizeof(bltfx));
		bltfx.dwSize=sizeof(bltfx);
		bltfx.dwFillColor=0;

		BackBuffer->Blt (&rect,NULL,&rect,DDBLT_COLORFILL,&bltfx);
		FrontBuffer->Blt(&rect,NULL,&rect,DDBLT_COLORFILL,&bltfx);
	}
}

BOOL Display2D::RestoreBuffers( void )
{
	if (!FrontBuffer || !BackBuffer)
		return FALSE;

	if(FrontBuffer->IsLost())
		FrontBuffer->Restore();

	if(BackBuffer->IsLost())
		BackBuffer->Restore();
	
	return TRUE;
}

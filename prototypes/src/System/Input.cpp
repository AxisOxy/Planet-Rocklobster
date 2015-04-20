#include "include.h"

void __cdecl KeyThread( void *data )
{
	int		i,va,hittime;
	short	keyarray[256];
	Input	*input;

	memset(keyarray,0,sizeof(keyarray));
	input=(Input*)data;
	hittime=0;
	do
	{
		input->ClearDownKeys();

		if (input->keythreadactive && input->mousecapture && display->GetReadyFlag())
		{
			for (i=0 ; i<256 ; i++)
			{
				va=GetAsyncKeyState(i);

				if (va & 0x8000)
				{
					input->AddKeyDown(i);
					if (input->keyrepeat && hittime>(input->repeatdelay/20) && (hittime % (50/input->repeatrate))==0)
						input->AddKeyTyped(i);
				}
			
				if ((va & 0x8000) && !(keyarray[i] & 0x8000))
				{
					input->AddKeyTyped(i);
					hittime=0;
				}
				keyarray[i]=va;
			}
		}
		hittime++;

		Sleep(20);
	}while(input->keythreadactive);
	
    _endthread();
}

void __cdecl MouseThread( void *data )
{
	POINT	p;
	Input	*input;

	input=(Input*)data;
	do
	{
		if (input->mousecapture && display->GetReadyFlag())
		{
			display->GetCursorPos(&p);
			input->SetMousePos(p.x,p.y);
//			SetCursorPos(input->scr_middle_x,input->scr_middle_y);
		}
		Sleep(10);
	}while(input->mousethreadactive);

    _endthread();
}

Input::Input( int scrsize_x, int scrsize_y )
{
	int	i;

	keythreadactive=mousethreadactive=FALSE;
	mousecapture=TRUE;

	scr_size_x=scrsize_x;
	scr_size_y=scrsize_y;
	scr_middle_x=scrsize_x>>1;
	scr_middle_y=scrsize_y>>1;

	mouse_x=mouse_y=0.0f;
	old_mouse_x=old_mouse_y=0.0f;
	mousespeed=1.0f;
	smoothmouse=FALSE;
	invertmouse=FALSE;
	clamptoscreen=FALSE;

	keyrepeat=FALSE;
	repeatrate=1;
	repeatdelay=1;

	for (i=0 ; i<4 ; i++)
		deltas_x[i]=deltas_y[i]=0.0f;

	ClearDownKeys();
	ClearTypedKeys();

	keythreadactive=TRUE;
	_beginthread(KeyThread,0,this);

	mousethreadactive=TRUE;
	_beginthread(MouseThread,0,this);
}

Input::~Input( void )
{
	keythreadactive=mousethreadactive=FALSE;
	Sleep(100);	//wichtig!!! Sonst können die Threads nicht sauber beendet werden!!
}

void Input::SetMouseProperties( float speed, BOOL smooth, BOOL invert, BOOL clamp )
{
	mousespeed=speed;
	smoothmouse=smooth;
	invertmouse=invert;
	clamptoscreen=clamp;
}

void Input::ClearDownKeys( void )
{
	int	i;

	numkeysdown=0;
	for (i=0 ; i<Max_PressedKeys ; i++)
		keysdown[i]=-1;
}

void Input::ClearTypedKeys( void )
{
	int	i;

	numtypedkeys=0;
	for (i=0 ; i<Max_PressedKeys ; i++)
		typedkeys[i]=-1;
}

void Input::DefragTypedKeys( void )
{
	int	i,count;

	count=0;
	for (i=0 ; i<Max_PressedKeys ; i++)
	{
		if (typedkeys[i]!=-1)
		{
			typedkeys[count]=typedkeys[i];
			count++;
		}
	}
	numtypedkeys=count;
}

void Input::AddKeyDown( int key )
{
	if (numkeysdown<Max_PressedKeys)
	{
		keysdown[numkeysdown]=key;
		numkeysdown++;
	}
}

void Input::AddKeyTyped( int key )
{
	if (numtypedkeys>=Max_PressedKeys)
		ClearTypedKeys();

	typedkeys[numtypedkeys]=key;
	numtypedkeys++;
}

void Input::SetMousePos( int x, int y )
{
	mouse_x=(float)(x);
	mouse_y=(float)(y);
	
	if (clamptoscreen)
	{
		if (mouse_x<0.0f)
			mouse_x=0.0f;
		if (mouse_x>(scr_size_x-1))
			mouse_x=(float)(scr_size_x-1);
		if (mouse_y<0.0f)
			mouse_y=0.0f;
		if (mouse_y>(scr_size_y-1))
			mouse_y=(float)(scr_size_y-1);
	}
}

BOOL Input::IsKeyDown( int key )
{
	int	i;

	for (i=0 ; i<numkeysdown ; i++)
	{
		if (keysdown[i]==key)
			return TRUE;
	}
	return FALSE;
}

BOOL Input::WasKeyHit( int key )
{
	int	i;

	for (i=0 ; i<numtypedkeys ; i++)
	{
		if (key==typedkeys[i])
		{
			typedkeys[i]=-1;
			DefragTypedKeys();
			return TRUE;
		}
	}
	return FALSE;
}

int Input::GetTypedKeys( char *_typedkeys )
{
	int	amount;

	amount=numtypedkeys;

	memcpy(_typedkeys,typedkeys,amount);
	ClearTypedKeys();

	return amount;
}

void Input::GetMousePos( float *mx, float *my )
{
	*mx=mouse_x;
	*my=mouse_y;
}

void Input::GetMouseDelta( float *mx, float *my )
{	
	*mx=mouse_x-old_mouse_x;
	*my=mouse_y-old_mouse_y;
	old_mouse_x=mouse_x;
	old_mouse_y=mouse_y;
}

BOOL Input::IsMouseKeyDown( Mouse_Button mousebutton )
{
	int	i,mousekey;

	mousekey=-2;
	switch(mousebutton)
	{
		case Mouse_Left:
			mousekey=VK_LBUTTON;
		break;

		case Mouse_Right:
			mousekey=VK_RBUTTON;
		break;
		
		case Mouse_Middle:
			mousekey=VK_MBUTTON;
		break;
	}

	for (i=0 ; i<numkeysdown ; i++)
	{
		if (keysdown[i]==mousekey)
			return TRUE;
	}
	return FALSE;
}

BOOL Input::WasMouseKeyHit( Mouse_Button mousebutton )
{
	BOOL	found;
	int		i,mousekey;

	mousekey=-2;
	switch(mousebutton)
	{
		case Mouse_Left:
			mousekey=VK_LBUTTON;
		break;

		case Mouse_Right:
			mousekey=VK_RBUTTON;
		break;
		
		case Mouse_Middle:
			mousekey=VK_MBUTTON;
		break;
	}

	found=FALSE;
	for (i=0 ; i<numtypedkeys ; i++)
	{
		if (mousekey==typedkeys[i])
		{
			typedkeys[i]=-1;
			found=TRUE;
		}
	}
	if (found)
		DefragTypedKeys();

	return found;
}

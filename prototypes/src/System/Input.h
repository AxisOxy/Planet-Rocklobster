#ifndef _INPUT_H
#define _INPUT_H

// class for basic mouse and keyboard input handling
class Input
{
public:
	BOOL	keythreadactive,mousethreadactive,mousecapture;
	BOOL	keyrepeat;
	int		repeatrate,repeatdelay;
	int		scr_middle_x,scr_middle_y;

private:
	int		scr_size_x,scr_size_y;
	float	mousespeed;
	BOOL	invertmouse,clamptoscreen,smoothmouse;

	float	mouse_x,mouse_y;
	float	old_mouse_x,old_mouse_y;
	float	deltas_x[4];
	float	deltas_y[4];
	
	int		numkeysdown,numtypedkeys;
	char	keysdown[Max_PressedKeys];
	char	typedkeys[Max_PressedKeys];

public:
	// ctor with windowsize
	Input ( int scrsize_x, int scrsize_y );

	// dtor
	~Input( void );
	
	// set the properties of the mouse grabbing
	void SetMouseProperties	( float speed, BOOL smooth, BOOL invert, BOOL clamp );
	
	// return if the given key is down
	BOOL IsKeyDown			( int key );

	// return if the given key was typed since last request
	BOOL WasKeyHit			( int key );

	// return all keycodes of the typed keys since last request
	int	 GetTypedKeys		( char *_typedkeys );

	// return the position of the mouse cursor in pixels
	void GetMousePos		( float *mx, float *my );

	// return the delta the mouse travelled since last request in pixels
	void GetMouseDelta		( float *mx, float *my );

	// return is the given mouse button is down
	BOOL IsMouseKeyDown		( Mouse_Button mousebutton );

	// return if the given mouse button was clicked since last request
	BOOL WasMouseKeyHit		( Mouse_Button mousebutton );


	//following functions are public, but should only be called by the input threads. so keep your fingers away.

	// clear all down keys (will be called from the key thread)
	void ClearDownKeys		( void );

	// add key down (will be called from the key thread)
	void AddKeyDown			( int key );

	// add typed key (will be called from the key thread)
	void AddKeyTyped		( int key );

	// set mouse pos (will be called from the mouse thread)
	void SetMousePos		( int x, int y );

private:
	void ClearTypedKeys		( void );
	void DefragTypedKeys	( void );
};

#endif // _INPUT_H
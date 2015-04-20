#include "include.h"

// define the class, so it can be constructed from the startup.ini
DEFINE_CLASS(Empty, Effect);
		
Empty::Empty()
{
	
	// initialize your class here

}

Empty::~Empty()
{
	
	// free up your class here

}

void Empty::Init( Gfx *_gfx, Input *_input )
{	
	Effect::Init(_gfx,_input);


	// put your effect init code here


}

void Empty::Update( float _rendertime )
{
	Effect::Update(_rendertime);

	gfx->Clear(0);


	// put your effect update code here


	Sleep(15);
}

void Empty::Exit( void )
{

	// put your effect shutdown code here


	Effect::Exit();
}

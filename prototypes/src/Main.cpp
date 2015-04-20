#include "include.h"

BOOL		quit;
Display2D	*display;
Gfx			*gfx;
Input		*input;
Timer		*timer;
Effect		*effect;
char		apppath[_MAX_PATH];

int effect_count=0;
std::string effect_name;
std::vector<std::string> effects;

BOOL CycleEffect( void );

int WINAPI WinMain( HINSTANCE hInst, HINSTANCE hPrev, LPSTR lpCmdLine, int nCmdShow )
{
	// get path
	char drive[_MAX_DRIVE];
	char dir[_MAX_DIR];
	char fname[_MAX_FNAME];
	char ext[_MAX_EXT];

	GetModuleFileName(0, apppath, _MAX_PATH);
	_splitpath( apppath, drive, dir, fname, ext );
	_makepath( apppath, drive, dir, 0, 0 );


	display=NULL;
	gfx=NULL;
	input=NULL;
	timer=NULL;
	effect=NULL;

	int width=320;
	int height=200;
	int depth=32;
	bool fullscreen=false;

	char line[1024];
	char lhs[1024];
	char rhs[1024];
	char *actual_buffer=NULL;
	int  actual_size=0;

	// parse startup.ini
	FileR *filer=new FileR("startup.ini");
	while(true)	
	{
		// skip empty lines
		if (!filer->ReadLine(line,1024))
			break;

		int len=strlen(line);
		if (len<=0)
			continue;

		lhs[0]=0;
		rhs[0]=0;

		actual_buffer=lhs;
		actual_size=0;

		for (int i=0 ; i<len ; i++)
		{
			// = is separator between key and value
			if (line[i]=='=')
			{
				actual_buffer[actual_size]=0;
				actual_buffer=rhs;
				actual_size=0;
			}

			// a line beginning with ; is a comment
			if (line[i]==';')
				break;

			// skip whitespaces
			if (line[i]!=0x20 && line[i]!=0x09 && line[i]!='=')
				actual_buffer[actual_size++]=line[i];
		}
		actual_buffer[actual_size]=0;

		// no key and no value, skip
		if (strlen(lhs)==0 || strlen(rhs)==0)
			continue;

		int value=atoi(rhs);

		// get bool fullscreen
		if (strcmp(lhs,"fullscreen")==0)
		{
			fullscreen=false;
			if (value!=0)
				fullscreen=true;
		}

		// get int xres
		if (strcmp(lhs,"xres")==0)
			width=value;

		// get int yres
		if (strcmp(lhs,"yres")==0)
			height=value;

		// get int depth
		if (strcmp(lhs,"depth")==0)
			depth=value;

		// store all effect names
		if (strcmp(lhs,"effect")==0)
		{
			effect_name=rhs;
			effects.push_back(effect_name);
		}
	};		

	delete filer;
	filer=NULL;


	quit=FALSE;

	// create window
	display=new Display2D(hInst,hPrev,"Amiga Stuff",0,0,width,height,depth,fullscreen);
	gfx=new Gfx(display,width,height);

	// create input handler
	input=new Input(width,height);
	input->SetMouseProperties(1.0f,TRUE,FALSE,FALSE);
	
	// create timer
	timer=new Timer();

	// start first effect
	if (!CycleEffect())
		return -1;

	float	time,rendertime;

	// mainloop
	rendertime=0.0f;
	do
	{
		// get time
		time=timer->GetTime();
		
		// call effect update
		effect->Update(rendertime);

		// end drawing and flip screen
		gfx->End();
		display->Flip();

		Sleep(0);

		// timediff
		rendertime=timer->GetTime()-time;

		// if escape was pressed, cycle to next effect
		if (input->IsKeyDown(KB_ESC))
		{
			// if there is none, end of program
			if (!CycleEffect())
				break;
		}

	}while(!display->GetQuitMessage());

	// free all mem and resources
	if (effect)		delete effect;
	if (timer)		delete timer;
	if (input)		delete input;
	if (gfx)		delete gfx;
	if (display)	delete display;
	
	return 0;
}

BOOL CycleEffect( void )
{
	// shutdown and delete old effect
	if (effect)
	{
		effect->Exit();
		delete effect;
	}

	effect=NULL;

	// is there another effect
	if (effect_count>=(int)(effects.size()))
		return FALSE;

	// then create it by name
	effect=(Effect*)CREATE_CLASS_BY_NAME(effects[effect_count++].c_str());
	if (!effect)
		return FALSE;

	// initialize it
	effect->Init(gfx,input);

	// wait 100 ms
	Sleep(100);

	return TRUE;
}

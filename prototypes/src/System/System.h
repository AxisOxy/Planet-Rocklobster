// include file for all system classes

//Defines
#define MAX_STRINGLENG		128
#define Max_PressedKeys		16

//Enums
#ifndef _SYSTEM_ENUMS_H
#define _SYSTEM_ENUMS_H

//Input
typedef enum
{
	Mouse_None			= 0,
	Mouse_Left			= 1,
	Mouse_Right			= 2,
	Mouse_Middle		= 3
}Mouse_Button;

#endif // _SYSTEM_ENUMS_H

//System Headers
#include "root.h"
#include "keyboard.h"
#include "filer.h"
#include "filew.h"
#include "input.h"
#include "timer.h"
#include "srdisplay.h"
#include "gfx.h"
#include "image.h"
#include "font.h"

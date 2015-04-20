#include "include.h"

Timer::Timer( void )
{
	QueryPerformanceFrequency(&frequency);
	QueryPerformanceCounter(&starttime);
}

Timer::~Timer( void )
{

}

float Timer::GetTime( void )
{
	LARGE_INTEGER   endtime;
	LONGLONG		diff,freq;

	QueryPerformanceCounter(&endtime);

	diff=endtime.QuadPart-starttime.QuadPart;
	freq=frequency.QuadPart;

	return((float)(diff)*1000.0f/(float)(freq));
}

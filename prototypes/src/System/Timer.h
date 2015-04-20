#ifndef _TIMER_H
#define _TIMER_H

// a class wrapping a high-precision timer
class Timer
{
	private:
		LARGE_INTEGER	starttime,frequency;

	public:
		// standard ctor
		Timer ( void );

		// dtor
		~Timer( void );

		// return the time in milliseconds since construction
		float GetTime( void );
};

#endif // _TIMER_H

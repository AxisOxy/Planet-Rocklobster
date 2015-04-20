#ifndef _FASTMATH_H
#define _FASTMATH_H

// file with lots of nice math definitions and helper functions.

///////////////////////////////
//constant definitions
///////////////////////////////

#define pi					3.141592654f
#define RadtoDeg			(180.0f/pi)
#define DegtoRad			(pi/180.0f)


///////////////////////////////
//helper functions
///////////////////////////////

// calc integer random between 0-max
inline int		randomi	( int max )					{ return (rand() % max); };

// calc integer random between min-max
inline int		randomi	( int min, int max )		{ return ((rand() % (max-min))+min); };

// calc float random between 0-max
inline float	randomf	( float max )				{ return ((float)(rand())*max/RAND_MAX); };

// calc float random between min-max
inline float	randomf	( float min, float max )	{ return (((float)(rand())*(max-min)/RAND_MAX)+min); };

// calc (value1 % value2) for a float
inline float FMod( float value1, float value2 )
{
	if (value1<0)
		return (value1-value2*(float)((int)((value1/value2)-1)));
	else
		return (value1-value2*(float)((int)(value1/value2)));
}

// swap the 2 given values
template< typename T >
void Swap( T& value1, T& value2 )
{
	T value3 = value1;
	value1 = value2;
	value2 = value3;
}

// return the minimum of the 2 values
template< typename T >
T Min( T value1, T value2 )
{
	if ( value1 < value2 )
	{
		return value1;
	}
	return value2;
}

// return the maximum of the 2 values
template< typename T >
T Max( T value1, T value2 )
{
	if ( value1 > value2 )
	{
		return value1;
	}
	return value2;
}

// clamp value between min and max
template< typename T >
void Clamp( T& value, T min, T max )
{
	if ( value < min )
	{
		value = min;
	}

	if ( value > max )
	{
		value = max;
	}
}	

// calc a value between value1 and value2 lerped with facrtor
template< typename T >
T Lerp( T value1, T value2, float factor )
{
	return (T)( (value1) + ( value2 - value1 ) * factor );
}

// return the integer value endianess swapped
inline unsigned int BSwapInt( unsigned int value )
{
	unsigned int value2=(value<<24) | ((value & 0xff00)<<8) | ((value & 0xff0000)>>8) | (value>>24);

	return value2;
};

// endianess swap the given integer array
inline void BSwapIntArray( unsigned int* values, int size )
{
	for (int i=0 ; i<size ; i++)
	{
		values[i]=BSwapInt(values[i]);
	}
};

// return the short value endianess swapped
inline unsigned short BSwapShort( unsigned short value )
{
	unsigned short value2=(value<<8) | (value>>8);

	return value2;
};

// endianess swap the given shrot array
inline void BSwapShortArray( unsigned short* values, int size )
{
	for (int i=0 ; i<size ; i++)
	{
		values[i]=BSwapShort(values[i]);
	}
};

///////////////////////////////
//math wrappers
///////////////////////////////

// float abs
inline float	OxyFabs		( float va )						{ return (float)fabs(va); };

// sqrt
inline float	OxySqrt		( float va )						{ return (float)sqrt(va); };

// sin
inline float	OxySin		( float va )						{ return (float)sin(va); };

// cos
inline float	OxyCos		( float va )						{ return (float)cos(va); };

// asin
inline float	OxyAsin		( float va )						{ return (float)asin(va); };

// acos
inline float	OxyAcos		( float va )						{ return (float)acos(va); };

// tan
inline float	OxyTan		( float va )						{ return (float)tan(va); };

// atan
inline float	OxyAtan		( float va )						{ return (float)atan(va); };

// atan2
inline float	OxyAtan2	( float y, float x )				{ return (float)atan2(y,x); };

// sin & cos
inline void		OxySinCos	( float va, float &s, float &c )	{ s=(float)sin(va); c=(float)cos(va); };


#endif // _FASTMATH_H

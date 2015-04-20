#include "include.h"

Matrix2x2::Matrix2x2()
{
	elements[0][0]=0.0f;
	elements[0][1]=0.0f;
	elements[1][0]=0.0f;
	elements[1][1]=0.0f;
}

Matrix2x2::Matrix2x2( float radians )
{
	float CosAngle=OxyCos(radians);
	float SinAngle=OxySin(radians);

	elements[0][0]= CosAngle; 
	elements[0][1]=-SinAngle;
	elements[1][0]= SinAngle; 
	elements[1][1]= CosAngle;
}

Matrix2x2::Matrix2x2( const Matrix2x2& rhs )
{
	elements[0][0]=rhs.elements[0][0];
	elements[0][1]=rhs.elements[0][1];
	elements[1][0]=rhs.elements[1][0];
	elements[1][1]=rhs.elements[1][1];
}

Matrix2x2::~Matrix2x2()
{

}


Vector2::Vector2() :	x( 0.0f ),
						y( 0.0f )
{

}

Vector2::Vector2( float x, float y ) :	x( x ),
										y( y )
{

}

Vector2::Vector2( const Vector2& rhs ) :	x( rhs.x ),
											y( rhs.y )
{

}

Vector2::~Vector2()
{

}

const Vector2& Vector2::operator+=( const Vector2& rhs )
{
	x+=rhs.x; 
	y+=rhs.y; 

	return *this;
}

const Vector2& Vector2::operator-=( const Vector2& rhs )
{
	x-=rhs.x; 
	y-=rhs.y; 

	return *this;
}

const Vector2& Vector2::operator*=( const Vector2& rhs )
{
	x*=rhs.x; 
	y*=rhs.y; 

	return *this;
}
	
const Vector2& Vector2::operator*=( float rhs )
{
	x*=rhs; 
	y*=rhs; 

	return *this;
}

Vector2 Vector2::operator+( const Vector2& rhs ) const
{
	return Vector2(  x + rhs.x, 
					 y + rhs.y ); 
}

Vector2 Vector2::operator-( const Vector2& rhs ) const
{
	return Vector2(  x - rhs.x, 
					 y - rhs.y ); 
}

Vector2 Vector2::operator*( const Vector2& rhs ) const
{
	return Vector2(  x * rhs.x, 
					 y * rhs.y ); 
}

Vector2 Vector2::operator*( float rhs ) const
{
	return Vector2(  x * rhs, 
					 y * rhs ); 
}

Vector2 Vector2::operator*( const Matrix2x2& rhs ) const
{
	return Vector2(	x*rhs.elements[0][0] + y*rhs.elements[0][1],
					x*rhs.elements[1][0] + y*rhs.elements[1][1] );
}

Vector2 Vector2::operator/( float rhs ) const
{
	return Vector2(  x / rhs, 
					 y / rhs ); 
}

float Vector2::Dot( const Vector2& rhs ) const
{
	return x*rhs.x + y*rhs.y;
}

float Vector2::PerpDot( const Vector2& rhs ) const
{
	return x*rhs.y - y*rhs.x;
}

Vector2 Vector2::GetPerp( void ) const
{
	return Vector2( -y,
					 x );
}

float Vector2::Scalar( void ) const
{
	return OxySqrt( x * x + 
					y * y );
}

float Vector2::ScalarSquared( void ) const
{
	return ( x * x + 
			 y * y );
}

void Vector2::Normalize( float new_length )
{
	float length = Scalar();
	
	//check to avoid zero divisions -> zero length vectors will remain zero
	if ( length>0.000001f )	
	{
		float factor = new_length / length; 

		x *= factor; 
		y *= factor; 
	}	
}

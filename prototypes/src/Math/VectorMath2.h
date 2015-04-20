// 2d-rotation matrix
class Matrix2x2
{
public:
	float	elements[2][2];

public:
	// standard ctor
	Matrix2x2();

	// construct rotation from radians
	Matrix2x2( float radians );

	// copy ctor
	Matrix2x2( const Matrix2x2& rhs );

	// dtor
	~Matrix2x2();
};


class Vector2
{
public:
	float	x,y;

public:
	// standard ctor
	Vector2();

	// ctor with 2 floats
	Vector2( float x, float y );

	// copy ctor
	Vector2( const Vector2& rhs );

	// dtor
	~Vector2();

	// add another vector to this
	const Vector2& operator+=( const Vector2& rhs );

	// subtract another vector from this
	const Vector2& operator-=( const Vector2& rhs );
	
	// multiply another vector to this (element wise)
	const Vector2& operator*=( const Vector2& rhs );
	
	// scale this vector by the given factor
	const Vector2& operator*=( float rhs );

	// return addition of this and the given vector
	Vector2 operator+( const Vector2& rhs ) const;

	// return subtraction of this minus the given vector
	Vector2 operator-( const Vector2& rhs ) const;

	// return multiplication of this and the given vector (element wise)
	Vector2 operator*( const Vector2& rhs ) const;

	// return a vector of this scaled by the given factor
	Vector2 operator*( float rhs ) const;

	// return a vector of this transformed with the given transform matrix
	Vector2 operator*( const Matrix2x2& rhs ) const;

	// return a vector of this divided by the given divisor
	Vector2 operator/( float rhs ) const;

	// return the dot-product of this and the given vector
	float Dot( const Vector2& rhs ) const;

	// return the perpendicular dot-product of this and the given vector (the dot product of the given vector and a vector perpendicular to this)
	float PerpDot( const Vector2& rhs ) const;

	// return the perpendicular vector of this (equivalent to a cross product in 3d)
	Vector2 GetPerp( void ) const;

	// return the length of this vector
	float Scalar( void ) const;

	// return the length^2 of this vector
	float ScalarSquared( void ) const;

	// normalize this vector to the given length (default is 1)
	void Normalize( float new_length=1.0f );
};

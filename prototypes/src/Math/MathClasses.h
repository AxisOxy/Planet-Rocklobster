#ifndef _MATHCLASSES_H
#define _MATHCLASSES_H

// forward declaration
class Matrix3x4;

// a vector with 3 float elements
class Vector3
{
	public:
		float	x;
		float 	y;
		float 	z;

	public:
		// standard ctor
		inline Vector3( void ) : x(0.0f), 
								 y(0.0f), 
								 z(0.0f)
		{ 

		}

		// ctor with 3 floats
		inline Vector3( float X, float Y, float Z ) : x(X), 
													  y(Y), 
													  z(Z)
		{ 

		}

		// copy ctor
		inline Vector3( const Vector3 &in_rVec ) : x(in_rVec.x), 
												   y(in_rVec.y), 
												   z(in_rVec.z)
		{

		}

		// dtor
		inline ~Vector3( void ) 
		{

		}

		// assign another vector to this
		inline const Vector3 &operator=( const Vector3 &in_rVec )	
		{ 
			x = in_rVec.x; 
			y = in_rVec.y;
			z = in_rVec.z; 

			return *this;
		}

		// add another vector to this
		inline const Vector3 &operator+=( const Vector3 &in_rVec )
		{ 
			x += in_rVec.x; 
			y += in_rVec.y; 
			z += in_rVec.z; 

			return *this;
		}

		// return addition of this and the given vector
		inline Vector3 operator+( const Vector3 &in_rVec ) const	
		{ 
			return Vector3(  x + in_rVec.x, 
							 y + in_rVec.y, 
							 z + in_rVec.z ); 
		}

		// subtract another vector from this
		inline const Vector3 &operator-=( const Vector3 &in_rVec )							
		{ 
			x -= in_rVec.x; 
			y -= in_rVec.y;
			z -= in_rVec.z; 

			return *this;
		}

		// return subtraction of this minus the given vector
		inline Vector3 operator-( const Vector3 &in_rVec ) const
		{ 
			return Vector3(  x - in_rVec.x, 
							 y - in_rVec.y, 
							 z - in_rVec.z ); 
		}

		// return the negate of this vector
		inline Vector3 operator-( void ) const
		{ 
			return Vector3(  -x, 
						 	 -y, 
							 -z ); 
		}

		// scale this vector by the given factor
		inline const Vector3 &operator*=( const float Factor )						
		{ 
			x *= Factor; 
			y *= Factor;
			z *= Factor; 

			return *this;
		}

		// return a vector of this scaled by the given factor
		inline Vector3 operator*( float Factor ) const
		{ 
			return Vector3(	x * Factor, 
							y * Factor, 
							z * Factor); 
		}

		// divide this vector by the given divisor
		inline const Vector3 &operator/=( const float Divisor )						
		{ 
			float Reziproc = 1.0f/Divisor; 

			x *= Reziproc; 
			y *= Reziproc; 
			z *= Reziproc; 

			return *this;
		}

		// return a vector of this divided by the given divisor
		inline Vector3 operator/( float Divisor ) const
		{ 
			float Reziproc = 1.0f/Divisor; 

			return Vector3(	x * Reziproc, 
							y * Reziproc, 
							z * Reziproc); 
		}

		// clear this vector to 0
		inline void	Clear( void )
		{ 
			x = y = z = 0.0f; 
		}

		// set this vector to the given values
		inline void	Set( float X, float Y, float Z )	
		{ 
			x = X; 
			y = Y; 
			z = Z; 
		}
		
		// return the dot-product of this and the given vector
		inline float Dot( const Vector3 &in_rVec ) const					
		{ 
			return(x * in_rVec.x + 
				   y * in_rVec.y + 
				   z * in_rVec.z); 
		}

		// return the length^2 of this vector
		inline float ScalarSquared( void ) const
		{
			return( x * x + 
					y * y + 
					z * z); 
		}

		// return the length of this vector
		float Scalar( void ) const;

		// normalize this vector to the given length (default is 1)
		void Normalize( float NewLength = 1.0f );

		// set this vector to the 2-element cross-product of the given vectors
		void Cross( const Vector3 &in_rVec1, const Vector3 &in_rVec2 );

		// set this vector to the 3-element cross-product of the given vectors (normal to the plane)
		void Cross( const Vector3 &in_rVec1, const Vector3 &in_rVec2, const Vector3 &in_rVec3 );

		// set this vector to a vector of this and the given vector lerped (elementwise) with InterpolationFactor
		void Lerp( const Vector3 &in_rVec, float InterpolationFactor );

		// rotate this vector around the x-axis (angle is in radians)
		void RotateX( float AngleX );

		// rotate this vector around the y-axis (angle is in radians)
		void RotateY( float AngleY );	

		// rotate this vector around the z-axis (angle is in radians)
		void RotateZ( float AngleZ );	

		// transform this vector by the given transformation matrix
		void MultiplyMatrix( const Matrix3x4 &in_rMatrix );

		// transform this vector by the given transformation matrix without translate
		void MultiplyMatrixNoTranslate( const Matrix3x4 &in_rMatrix );

		// clamp the elements of this vector to the given min and max
		void Clamp( float fMin, float fMax );
};
// definition for vector3 array
typedef std::vector<Vector3> Vectors3;

// definition for int array
typedef std::vector<int> Ints;


// a 3x4 element matrix (3x3 rotation + translation)
class Matrix3x4
{
	public:
		float	mat11, mat12, mat13;
		float	mat21, mat22, mat23;
		float	mat31, mat32, mat33;
		float	mat41, mat42, mat43;

	public:
		// standard ctor
		Matrix3x4( void );

		// dtor
		~Matrix3x4( void );

		// assign another matrix to this
		inline void operator = ( const Matrix3x4 &v )	
		{
			mat11=v.mat11;
			mat12=v.mat12;
			mat13=v.mat13;
			mat21=v.mat21;
			mat22=v.mat22;
			mat23=v.mat23;
			mat31=v.mat31;
			mat32=v.mat32;
			mat33=v.mat33;
			mat41=v.mat41;
			mat42=v.mat42;
			mat43=v.mat43;
		};

		// set this matrix to an unit/identity matrix
		void Unit( void );

		// translate this matrix by the given vector
		void Translate( const Vector3 &delta );

		// set the translation of this matrix to the given vector
		void SetTranslation( const Vector3 &delta );

		// return the translation of this matrix
		void GetTranslation( Vector3 &out_delta ) const;	

		// scale this matrix by the given vector
		void Scale( const Vector3 &scale );

		// rotate this matrix around the x-axis (angle is in radians)
		void RotateX( float rx );

		// rotate this matrix around the y-axis (angle is in radians)
		void RotateY( float ry );

		// rotate this matrix around the z-axis (angle is in radians)
		void RotateZ( float rz );

		// rotate this matrix around all 3 axes (angle is in radians) in xyz-order
		void RotateXYZ( const Vector3 &EulerAngles );	

		// transform this matrix by the given transformation matrix
		void MultiplyMatrix( const Matrix3x4 &matrix );

		// invert this matrix
		void Invert( void );
};

// 3d-plane equation
class Plane
{
	public:
		Vector3	normal;
		float	distance;
		
	public:
		// standard ctor
		Plane( void );

		// dtor
		~Plane( void );

		// contruct this plane from normal and distance
		Plane( const Vector3 &normal, float distance );

		// contruct this plane from 3 vertices
		Plane( const Vector3 &p1, const Vector3 &p2, const Vector3 &p3 );

		// copy ctor
		Plane( const Plane &rhs );

		// assign another plane to this
		const Plane &operator=( const Plane &rhs );

		// set this plane to this normal and distance
		void Set( const Vector3 &normal, float distance );

		// set this plane to a plane contructed from 3 vertices
		void Set( const Vector3 &p1, const Vector3 &p2, const Vector3 &p3 );

		// return the distance of the given point from this plane
		float GetDistance( const Vector3 &point ) const;
};

#endif // _MATHCLASSES_H

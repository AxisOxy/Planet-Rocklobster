#include "include.h"

float Vector3::Scalar( void ) const
{
	return( OxySqrt(x * x + 
					y * y + 
					z * z)); 
}

void Vector3::Normalize( float NewLength )
{ 
	float Length = Scalar();
	
	//check to avoid zero divisions -> zero length vectors will remain zero
	if (Length > 0.000001f)	
	{
		float Factor = NewLength / Length; 

		x *= Factor; 
		y *= Factor; 
		z *= Factor; 
	}
}

void Vector3::Cross( const Vector3 &in_rVec1, const Vector3 &in_rVec2 )
{
    x = in_rVec1.y * in_rVec2.z - in_rVec1.z * in_rVec2.y;
    y = in_rVec1.z * in_rVec2.x - in_rVec1.x * in_rVec2.z;
    z = in_rVec1.x * in_rVec2.y - in_rVec1.y * in_rVec2.x;
}

void Vector3::Cross( const Vector3 &in_rVec1, const Vector3 &in_rVec2, const Vector3 &in_rVec3 )
{
	x=	(in_rVec2.z - in_rVec1.z) * (in_rVec3.y - in_rVec1.y) - 
		(in_rVec3.z - in_rVec1.z) * (in_rVec2.y - in_rVec1.y);

	y=	(in_rVec2.x - in_rVec1.x) * (in_rVec3.z - in_rVec1.z) - 
		(in_rVec3.x - in_rVec1.x) * (in_rVec2.z - in_rVec1.z);

	z=	(in_rVec2.y - in_rVec1.y) * (in_rVec3.x - in_rVec1.x) - 
		(in_rVec3.y - in_rVec1.y) * (in_rVec2.x - in_rVec1.x);
}

void Vector3::Lerp( const Vector3 &in_rVec, float InterpolationFactor )		
{ 
	x += (in_rVec.x - x) * InterpolationFactor;
	y += (in_rVec.y - y) * InterpolationFactor;
	z += (in_rVec.z - z) * InterpolationFactor;
} 

void Vector3::RotateX( float AngleX )		
{ 
	float	SinX, CosX, TmpY;

	if (OxyFabs(AngleX) > 0.000001f)
	{
		OxySinCos(AngleX, SinX, CosX);

		TmpY = y * CosX - z * SinX;
		z  = y * SinX + z * CosX;

		y = TmpY;
	}
}

void Vector3::RotateY( float AngleY )		
{ 
	float	SinY, CosY, TmpX;

	if (OxyFabs(AngleY) > 0.000001f)
	{
		OxySinCos(AngleY, SinY, CosY);

		TmpX = x * CosY - z * SinY;
		z  = x * SinY + z * CosY;

		x = TmpX;
	}
}

void Vector3::RotateZ( float AngleZ )		
{ 
	float	SinZ, CosZ, TmpX;

	if (OxyFabs(AngleZ) > 0.000001f)
	{
		OxySinCos(AngleZ, SinZ, CosZ);

		TmpX = x * CosZ - y * SinZ;
		y  = x * SinZ + y * CosZ;

		x = TmpX;
	}
}

void Vector3::MultiplyMatrix( const Matrix3x4 &in_rMatrix )		
{ 
	Vector3 TmpVec(*this);

	x = TmpVec.x * in_rMatrix.mat11 + 
		TmpVec.y * in_rMatrix.mat21 + 
		TmpVec.z * in_rMatrix.mat31 + 
		           in_rMatrix.mat41;

	y = TmpVec.x * in_rMatrix.mat12 + 
		TmpVec.y * in_rMatrix.mat22 + 
		TmpVec.z * in_rMatrix.mat32 + 
		           in_rMatrix.mat42;

	z = TmpVec.x * in_rMatrix.mat13 + 
		TmpVec.y * in_rMatrix.mat23 + 
		TmpVec.z * in_rMatrix.mat33 + 
		           in_rMatrix.mat43;
}

void Vector3::MultiplyMatrixNoTranslate( const Matrix3x4 &in_rMatrix )
{ 
	Vector3 TmpVec(*this);

	x = TmpVec.x * in_rMatrix.mat11 + 
		TmpVec.y * in_rMatrix.mat21 + 
		TmpVec.z * in_rMatrix.mat31; 

	y = TmpVec.x * in_rMatrix.mat12 + 
		TmpVec.y * in_rMatrix.mat22 + 
		TmpVec.z * in_rMatrix.mat32;

	z = TmpVec.x * in_rMatrix.mat13 + 
		TmpVec.y * in_rMatrix.mat23 + 
		TmpVec.z * in_rMatrix.mat33; 
}

void Vector3::Clamp( float fMin, float fMax )
{
	x = min( x, fMax );
	x = max( x, fMin );

	y = min( y, fMax );
	y = max( y, fMin );
	
	z = min( z, fMax );
	z = max( z, fMin );
}


Matrix3x4::Matrix3x4( void )
{

}

Matrix3x4::~Matrix3x4( void )
{

}

void Matrix3x4::Unit( void )						
{
	mat12=mat13=0.0f;
	mat21=mat23=0.0f;
	mat31=mat32=0.0f;
	mat41=mat42=mat43=0.0f;
	mat11=mat22=mat33=1.0f;
}

void Matrix3x4::Translate( const Vector3 &delta )	
{ 
	mat41+=delta.x; 
	mat42+=delta.y; 
	mat43+=delta.z; 
}

void Matrix3x4::SetTranslation( const Vector3 &delta )	
{
	mat41=delta.x; 
	mat42=delta.y; 
	mat43=delta.z; 
}

void Matrix3x4::GetTranslation( Vector3 &out_delta ) const	
{
	out_delta.x=mat41; 
	out_delta.y=mat42; 
	out_delta.z=mat43; 
}

void Matrix3x4::Scale( const Vector3 &scale )	
{ 
	if (scale.x!=1.0f)
	{
		mat11*=scale.x;
		mat21*=scale.x;
		mat31*=scale.x;
		mat41*=scale.x;
	}

	if (scale.y!=1.0f)
	{
		mat12*=scale.y;
		mat22*=scale.y;
		mat32*=scale.y;
		mat42*=scale.y;
	}

	if (scale.z!=1.0f)
	{
		mat13*=scale.z;
		mat23*=scale.z;
		mat33*=scale.z;
		mat43*=scale.z;
	}
}

void Matrix3x4::RotateX( float rx )
{
	float			sx,cx;
	Matrix3x4	rotmatrix;

	if (rx)
	{
		OxySinCos(rx,sx,cx);
		rotmatrix.Unit();
		rotmatrix.mat22= cx;
		rotmatrix.mat23= sx;
		rotmatrix.mat32=-sx;
		rotmatrix.mat33= cx;
		MultiplyMatrix(rotmatrix);
	}
}

void Matrix3x4::RotateY( float ry )
{
	float			sy,cy;
	Matrix3x4	rotmatrix;

	if (ry)
	{
		OxySinCos(ry,sy,cy);
		rotmatrix.Unit();
		rotmatrix.mat11= cy;
		rotmatrix.mat13= sy;
		rotmatrix.mat31=-sy;
		rotmatrix.mat33= cy;
		MultiplyMatrix(rotmatrix);
	}
}

void Matrix3x4::RotateZ( float rz )
{
	float			sz,cz;
	Matrix3x4	rotmatrix;

	if (rz)
	{
		OxySinCos(rz,sz,cz);
		rotmatrix.Unit();
		rotmatrix.mat11= cz;
		rotmatrix.mat12= sz;
		rotmatrix.mat21=-sz;
		rotmatrix.mat22= cz;
		MultiplyMatrix(rotmatrix);
	}
}

void Matrix3x4::RotateXYZ( const Vector3 &EulerAngles )	
{
	RotateX(EulerAngles.x);
	RotateY(EulerAngles.y);
	RotateZ(EulerAngles.z);
}

void Matrix3x4::MultiplyMatrix( const Matrix3x4 &matrix )
{
	Matrix3x4	matrix2;
	
	matrix2.mat11=matrix.mat11*mat11+matrix.mat21*mat12+matrix.mat31*mat13;
	matrix2.mat12=matrix.mat12*mat11+matrix.mat22*mat12+matrix.mat32*mat13;
	matrix2.mat13=matrix.mat13*mat11+matrix.mat23*mat12+matrix.mat33*mat13;
	matrix2.mat21=matrix.mat11*mat21+matrix.mat21*mat22+matrix.mat31*mat23;
	matrix2.mat22=matrix.mat12*mat21+matrix.mat22*mat22+matrix.mat32*mat23;
	matrix2.mat23=matrix.mat13*mat21+matrix.mat23*mat22+matrix.mat33*mat23;
	matrix2.mat31=matrix.mat11*mat31+matrix.mat21*mat32+matrix.mat31*mat33;
	matrix2.mat32=matrix.mat12*mat31+matrix.mat22*mat32+matrix.mat32*mat33;
	matrix2.mat33=matrix.mat13*mat31+matrix.mat23*mat32+matrix.mat33*mat33;
	matrix2.mat41=matrix.mat11*mat41+matrix.mat21*mat42+matrix.mat31*mat43+matrix.mat41;
	matrix2.mat42=matrix.mat12*mat41+matrix.mat22*mat42+matrix.mat32*mat43+matrix.mat42;
	matrix2.mat43=matrix.mat13*mat41+matrix.mat23*mat42+matrix.mat33*mat43+matrix.mat43;
	*this=matrix2;
}

void Matrix3x4::Invert( void )
{
	Matrix3x4	dummy;
	float			invdet;

	invdet=1.0f/(mat11*(mat22*mat33-mat23*mat32)-
				 mat12*(mat21*mat33-mat23*mat31)+
				 mat13*(mat21*mat32-mat22*mat31));

	dummy.mat11= invdet*(mat22*mat33-mat23*mat32);
	dummy.mat12=-invdet*(mat12*mat33-mat13*mat32);
	dummy.mat13= invdet*(mat12*mat23-mat13*mat22);

	dummy.mat21=-invdet*(mat21*mat33-mat23*mat31);
	dummy.mat22= invdet*(mat11*mat33-mat13*mat31);
	dummy.mat23=-invdet*(mat11*mat23-mat13*mat21);

	dummy.mat31= invdet*(mat21*mat32-mat22*mat31);
	dummy.mat32=-invdet*(mat11*mat32-mat12*mat31);
	dummy.mat33= invdet*(mat11*mat22-mat12*mat21);

	dummy.mat41=-(mat41*dummy.mat11+mat42*dummy.mat21+mat43*dummy.mat31);
	dummy.mat42=-(mat41*dummy.mat12+mat42*dummy.mat22+mat43*dummy.mat32);
	dummy.mat43=-(mat41*dummy.mat13+mat42*dummy.mat23+mat43*dummy.mat33);
	*this=dummy;
}


Plane::Plane( void )
{
	normal.Clear();
	distance=0.0f;
}

Plane::~Plane( void )
{

}

Plane::Plane( const Vector3 &normal, float distance )
{
	Set(normal,distance);
}

Plane::Plane( const Vector3 &p1, const Vector3 &p2, const Vector3 &p3 )
{
	Set(p1,p2,p3);
}

Plane::Plane( const Plane &rhs )
{
	Set(rhs.normal,rhs.distance);
}

const Plane &Plane::operator=( const Plane &rhs )
{
	Set(rhs.normal,rhs.distance);

	return *this;
}

void Plane::Set( const Vector3 &normal, float distance )
{
	this->normal=normal;
	this->distance=distance;
}

void Plane::Set( const Vector3 &p1, const Vector3 &p2, const Vector3 &p3 )
{
	normal.Cross(p1,p2,p3);
	normal.Normalize();
	distance=-p1.Dot(normal);
}

float Plane::GetDistance( const Vector3 &point ) const
{
	return (point.Dot(normal)+distance);
}

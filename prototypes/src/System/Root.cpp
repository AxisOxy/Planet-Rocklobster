#include "include.h"

st_CreateStruct::st_CreateStruct( const char *class_name, const char *parent_class_name, CreateFunc create_func )
{
	this->class_name=class_name;
	this->parent_class=ClassRegistrar::GetInstance()->GetCreateStruct(parent_class_name);
	this->create_func=create_func;
	ClassRegistrar::GetInstance()->RegisterClass(class_name,this);
}


ClassRegistrar::ClassRegistrar()
{
	array_size=0;
}

ClassRegistrar::~ClassRegistrar()
{

}

ClassRegistrar *ClassRegistrar::GetInstance( void )
{
	static ClassRegistrar instance;

	return &instance;
}

void ClassRegistrar::RegisterClass( const char *name, st_CreateStruct *create_struct )
{
	if (GetCreateStruct(name))
		return;

	class_array[array_size++]=create_struct;
}

st_CreateStruct *ClassRegistrar::GetCreateStruct( const char *name )
{
	for (int i=0 ; i<array_size ; i++)
	{
		if (class_array[i]->class_name==name)
			return class_array[i];
	}

	return NULL;
}

Root *ClassRegistrar::CreateClassByName( const char *class_name )
{
	st_CreateStruct *cs=GetCreateStruct(class_name);
	if (cs)
		return cs->create_func();

	return NULL;
}

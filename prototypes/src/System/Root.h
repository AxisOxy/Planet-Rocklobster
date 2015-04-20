#ifndef _ROOT_H
#define _ROOT_H

// simple create object by classname mechanism
// to make your classes take advantage of this, derive them from Root and add the DECLARE_CLASS macro to your header and add the DEFINE_CLASS macro to your implementation

// baseclass for all other classes in the framework
class Root
{
	public:
		Root() {};		
		virtual ~Root() {};		
};

// createfunc to create a root object
typedef Root *(*CreateFunc)();

// structure to store info to create an object by classname string.
struct st_CreateStruct
{
	std::string		class_name;
	st_CreateStruct	*parent_class;
	CreateFunc		create_func;

	st_CreateStruct( const char *class_name, const char *parent_class_name, CreateFunc create_func );
};

// declare macro for classes with createbyname mechanics (add this behind your class body)
#define DECLARE_CLASS(class_name)			\
	static Root *CreateInstance( void )		\
	{										\
		return new class_name();			\
	}										\
											\
	static st_CreateStruct create_struct;	\

// define macro for classes for classes with createbyname mechanics (add this to your implementation)
#define DEFINE_CLASS(class_name,base_class_name)	\
st_CreateStruct class_name::create_struct(#class_name,#base_class_name,class_name::CreateInstance);	

// macro to create a class by name string
#define CREATE_CLASS_BY_NAME(class_name)\
	ClassRegistrar::GetInstance()->CreateClassByName(class_name);

// singleton class to register all createbyname compatible classes
class ClassRegistrar
{
	private:
		int				array_size;
		st_CreateStruct *class_array[1024];

		// private standard ctor to secure that there is only one instance of this
		ClassRegistrar();

	public:
		// dtor	
		~ClassRegistrar();

		// return the single instance of this
		static ClassRegistrar *GetInstance( void );

		// register the given class by name
		void RegisterClass( const char *name, st_CreateStruct *create_struct );

		// return the class by name
		st_CreateStruct *GetCreateStruct( const char *name );

		// create an object of the class by name
		Root *CreateClassByName( const char *class_name );
};

#endif // _ROOT_H
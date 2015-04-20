// An empty effect class as example or template to create new effects
class Empty : public FillerBase
{
	private:
		// put your class variables here


	public:
		// standard ctor, will be called on construction
		Empty();

		// dtor, will be called on destruction
		virtual ~Empty();

		// overridden init function, will be called on start of the effect
		virtual void Init( Gfx *_gfx, Input *_input );

		// overridden update function, will be called every frame
		virtual void Update( float _rendertime );

		// overridden exit function, will be called on shutdown of the effect
		virtual void Exit( void );
				

private:
		// put your internal functions here

		
		// declare the class, so it can be constructed from the startup.ini
		DECLARE_CLASS(Empty);
};

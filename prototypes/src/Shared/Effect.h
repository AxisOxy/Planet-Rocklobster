#ifndef _EFFECT_H
#define _EFFECT_H

// baseclass for all effects. for adding an effect derive from this class and override the virtual functions.
class Effect : public Root
{
	protected:
		Gfx				*gfx;
		Input			*input;

		float			time,rendertime;
		int				frame;
	
		unsigned int	palette[16];

		unsigned char	debug_char_set[512];
		

	public:
		// standard ctor
		Effect();

		// dtor
		virtual ~Effect();

		// virtual init function, derived classes can override this function to get called for their initialisation.
		virtual void Init( Gfx *_gfx, Input *_input );

		// virtual update function, derived classes can override this function to get their frame update.
		virtual void Update( float _rendertime );

		// virtual exit function, derived classes can override this function to get called for their shutdown.
		virtual void Exit( void );
		
		// returns the c64 color with the given index (0-15) as (A8R8G8B8).
		unsigned int GetColor( int index );

		// prints the given text on the screen.
		void Label( int x, int y, const char *text, unsigned char col );
};

#endif // _EFFECT_H

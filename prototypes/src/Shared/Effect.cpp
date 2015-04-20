#include "include.h"

Effect::Effect( )
{
	palette[ 0]=0x000000;
	palette[ 1]=0xffffff;
	palette[ 2]=0x6b392b;
	palette[ 3]=0x7baebc;
	palette[ 4]=0x75408b;
	palette[ 5]=0x60954a;
	palette[ 6]=0x35287b;
	palette[ 7]=0xc5d27d;
	palette[ 8]=0x755427;
	palette[ 9]=0x443a00;
	palette[10]=0xa26f61;
	palette[11]=0x474747;
	palette[12]=0x727272;
	palette[13]=0xa8de91;
	palette[14]=0x7264b9;
	palette[15]=0xa1a1a1;

	time=rendertime=0.0f;
	frame=0;

	FileR* filer=new FileR("data/basedata/chr.prg");
	filer->Seek(2,SeekSet);
	filer->Read(debug_char_set,1,512);
	delete filer;
}

Effect::~Effect()
{

}

void Effect::Init( Gfx *_gfx, Input *_input )
{ 
	gfx=_gfx;
	input=_input;
}

void Effect::Update( float _rendertime )
{
	rendertime=_rendertime;
	time+=rendertime;
	frame++;
}

void Effect::Exit( void )
{

}

unsigned int Effect::GetColor( int index )
{
	return palette[index & 0x0f];
}

void Effect::Label( int x, int y, const char *text, unsigned char col )
{
	int len=strlen(text);

	int i,xx,yy;
	unsigned char chr,va;

	unsigned int color=GetColor(col);

	for (i=0 ; i<len ; i++)
	{		
		chr=text[i];
		if (chr>='0' && chr<='9')
			chr=chr;

		if (chr>='a' && chr<='z')
			chr=chr-0x60;

		if (chr>='A' && chr<='Z')
			chr=chr-0x20;
	
		for (yy=0 ; yy<8 ; yy++)
		{
			va=debug_char_set[chr*8+yy];
			for (xx=0 ; xx<8 ; xx++)
			{
				if ((va<<xx) & 0x80)
					gfx->Plot(x+xx,y+yy,color);
			}
		}
		x+=8;
	}
}

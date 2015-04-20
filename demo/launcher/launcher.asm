disk1_start:
		bsr.w	init

		include "../launcher/script.asm"

		bra.w	shutdown
		
;--------------------------------------------------------------------
		
		include "../launcher/launcher_framework.asm"

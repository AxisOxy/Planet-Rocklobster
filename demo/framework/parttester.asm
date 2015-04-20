		bsr.w 	appinit
		
		lea		fw_jmptable,a6
		bsr.w	entrypoint
		
		bra.w	appshutdown			
		
;--------------------------------------------------------------------

		include "../framework/framework.asm"

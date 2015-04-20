/* example ARexx script */
options results
address POWERPACKER
ezrequest 'Testing PowerPacker ARexx EZRequest'
if rc = 5 then
	say "You pressed 'Ok'."
else
	say "You pressed 'Cancel'."
getfilename
say 'Name of file loaded:' result
autorecrunch read
if rc = 5 then
	say 'Auto Recrunch is on.'
else
	say 'Auto Recrunch is off.'
say 'End of example.'

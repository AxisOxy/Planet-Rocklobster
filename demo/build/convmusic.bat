REM delete all intermed files
del "..\data\maintune.p61"
del "..\winuae\hd0\tune.p61"
del "..\winuae\hd0\finished"

REM create a startup sequence to start the p61con with commandline options
@echo /|set /p =p61con.exe hd0:maintune.mod>"..\winuae\hd0\s\startup-sequence"

REM copy the mod-file to the winuae hd
REM its important that the file is called tune.mod there
REM the patched p61con has no real commandline interface, but hardcoded filenames
copy "..\music\maintune.mod" "..\winuae\hd0\tune.mod"

REM start winuae
start ..\winuae\winuae -config=configs\a500.uae -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

REM check if the finished file was written by p61con to signal that conversion is done
:file_check
IF EXIST "..\winuae\hd0\finished" (GOTO file_exists) ELSE timeout /T 1 > nul
GOTO file_check

:file_exists
REM kill winuae and copy the converted p61-file back to the data folder
REM again its important that the filename is tune.p61. see above
taskkill /IM winuae.exe
copy "..\winuae\hd0\tune.p61" "..\data\maintune.p61"
:eof

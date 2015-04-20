del p61con.exe
del "..\..\..\demo\winuae\hd0\p61con.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\..\..\demo\tools;%PATH%
:AlreadySet

copy "..\..\..\demo\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "p61con.exe" "p61con.asm"

copy p61con.exe "..\..\..\demo\winuae\hd0"
copy "..\..\..\demo\music\maintune.mod" "..\..\..\demo\winuae\hd0\tune.mod"

@echo /|set /p =p61con.exe hd0:maintune.mod>"..\..\..\demo\winuae\hd0\s\startup-sequence"

"..\..\..\demo\winuae\winuae" -config="configs\a500.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\..\..\demo\winuae\hd0,0

del vc.cfg

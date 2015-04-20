del pic.exe
del "..\winuae\hd0\pic.exe"

"..\tools\gfxconv" ../data/pic/rocklobster.gif ../data/pic/pic1.ami imagepal
"..\tools\gfxconv" ../data/pic/see.png ../data/pic/pic2.ami

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "pic.exe" "pic1.asm"

copy pic.exe "..\winuae\hd0"

@echo /|set /p =pic.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae" -config="configs\a500.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg

del spacecut.exe
del "..\winuae\hd0\spacecut.exe"

"..\tools\gfxconv" ../data/vector/logo.png ../data/vector/logo.ami

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "spacecut.exe" "spacecut.asm"

copy spacecut.exe "..\winuae\hd0"

@echo /|set /p =spacecut.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae" -config="configs\a500.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg

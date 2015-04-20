del vecplots.exe
del "..\winuae\hd0\vecplots.exe"

"..\tools\spriteconv" ../data/vecplots/overlay4.png ../data/vecplots/overlay4.spr

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "vecplots.exe" "vecplots.asm"

copy vecplots.exe "..\winuae\hd0"

@echo /|set /p =vecplots.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae" -config="configs\a500.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg

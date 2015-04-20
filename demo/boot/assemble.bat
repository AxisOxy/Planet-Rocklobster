del boot.exe
del "..\winuae\hd0\boot.exe"

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "boot.exe" "boot.asm"

copy boot.exe "..\winuae\hd0"

@echo /|set /p =boot.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae" -config="configs\a500.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg

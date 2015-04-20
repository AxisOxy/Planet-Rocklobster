del bootblock

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

..\tools\vasmm68k_mot -m68010 -Fbin -o bootblock -I"%~dp0/../includes" bootblock.asm

pause

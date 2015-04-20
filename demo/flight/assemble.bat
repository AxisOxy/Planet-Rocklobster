del flight.exe
del "..\winuae\hd0\flight.exe"

"..\tools\gfxconv" ../data/flight/screen.png ../data/flight/screen.ami sort

REM ..\tools\lz.exe -o ..\data\flight\pic_0.lz ..\data\flight\pic_0.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_1.lz ..\data\flight\pic_1.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_2.lz ..\data\flight\pic_2.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_3.lz ..\data\flight\pic_3.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_4.lz ..\data\flight\pic_4.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_5.lz ..\data\flight\pic_5.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_6.lz ..\data\flight\pic_6.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_7.lz ..\data\flight\pic_7.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_8.lz ..\data\flight\pic_8.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_9.lz ..\data\flight\pic_9.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_10.lz ..\data\flight\pic_10.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_11.lz ..\data\flight\pic_11.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_12.lz ..\data\flight\pic_12.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_13.lz ..\data\flight\pic_13.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_14.lz ..\data\flight\pic_14.dat
REM ..\tools\lz.exe -o ..\data\flight\pic_15.lz ..\data\flight\pic_15.dat

@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

copy "..\tools\vc.cfg" %~dp0

vc -O2 -notmpfile -nostdlib -o "flight.exe" "flight.asm"

copy flight.exe "..\winuae\hd0"

@echo /|set /p =flight.exe>"..\winuae\hd0\s\startup-sequence"

"..\winuae\winuae" -config="configs\a500.uae" -s use_gui=no -s filesystem2=rw,hd0:test:%~dp0\..\winuae\hd0,0

del vc.cfg

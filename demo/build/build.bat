rem ############ PREPARE BUILD ############
@if X%VBCC%==X%~dp0 goto AlreadySet
@set VBCC=%~dp0
@set PATH=%VBCC%\..\tools;%PATH%
:AlreadySet

rem copy demo config for vasm
copy "..\tools\demo.cfg" %~dp0vc.cfg

rem ############ ASSEMBLE PARTS ############
vc -O2 -notmpfile -nostdlib -o "..\version\boot.exe" "..\boot\boot.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\starfield.exe" "..\starfield\starfield.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\planet.exe" "..\planet\planet.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\voxel.exe" "..\voxel\voxel.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\pic1.exe" "..\pic\pic1.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\vectorizer.exe" "..\vectorizer\vectorizer.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\pic2.exe" "..\pic\pic2.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\vectorizerwire.exe" "..\vectorizerwire\vectorizer.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\vecfade1.exe" "..\vecplots\vecfade1.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\vecplots.exe" "..\vecplots\vecplots.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\vecfade2.exe" "..\vecplots\vecfade2.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\roto.exe" "..\rotzoom\rotzoom.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\crack.exe" "..\crack\crack.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\city.exe" "..\city\city.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\city_fade.exe" "..\city\city_fade.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\blur.exe" "..\blur\blur.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\vectrans1.exe" "..\vectrans\vectrans1.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\spacecut.exe" "..\spacecut\spacecut.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\vectrans2.exe" "..\vectrans\vectrans2.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\greets.exe" "..\greets\greets.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\flight.exe" "..\flight\flight.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\logo.exe" "..\logo\logo.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
vc -O2 -notmpfile -nostdlib -o "..\version\starwars.exe" "..\starwars\starwars.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

rem ############ PACK PARTS AND MUSIC ############
cd ..\tools
lz -o ..\version\music1.dat ..\data\maintune.p61
copy ..\data\dummy.dat ..\version\dummy.dat
if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\boot.exe ..\version\boot.dat
if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\starfield.exe ..\version\starfield.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\planet.exe ..\version\planet.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\voxel.exe ..\version\voxel.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\pic1.exe ..\version\pic1.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\vectorizer.exe ..\version\vectorizer.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\pic2.exe ..\version\pic2.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\vectorizerwire.exe ..\version\vectorizerwire.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\vecfade1.exe ..\version\vecfade1.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\vecplots.exe ..\version\vecplots.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\vecfade2.exe ..\version\vecfade2.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\roto.exe ..\version\roto.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\crack.exe ..\version\crack.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\city.exe ..\version\city.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\city_fade.exe ..\version\city_fade.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\blur.exe ..\version\blur.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\vectrans1.exe ..\version\vectrans1.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\spacecut.exe ..\version\spacecut.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\vectrans2.exe ..\version\vectrans2.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\greets.exe ..\version\greets.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\flight.exe ..\version\flight.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\logo.exe ..\version\logo.dat
@if %ERRORLEVEL% NEQ 0 goto failed
sectionlz ..\version\starwars.exe ..\version\starwars.dat
@if %ERRORLEVEL% NEQ 0 goto failed
cd ..\build

rem ############ ASSEMBLE FRAMEWORK AND BOOTBLOCK ############
copy "..\tools\vc.cfg" %~dp0

..\tools\vasmm68k_mot -m68010 -Fbin -phxass -o "..\version\launcher" -I"%~dp0\..\includes" "..\launcher\launcher.asm"
@if %ERRORLEVEL% NEQ 0 goto failed
..\tools\vasmm68k_mot -m68010 -Fbin -phxass -o "..\version\bootblock" -I"%~dp0\..\includes" "..\launcher\bootblock.asm"
@if %ERRORLEVEL% NEQ 0 goto failed

rem ############ BUILD DISK ############
cd ..\tools
adftrack ..\version\bootblock ..\version\demo.adf ..\version\launcher ..\version\boot.dat ..\version\music1.dat ..\version\dummy.dat ..\version\starfield.dat ..\version\planet.dat ..\version\voxel.dat ..\version\pic2.dat ..\version\vectorizer.dat ..\version\pic1.dat ..\version\vectorizerwire.dat ..\version\vecfade1.dat ..\version\vecplots.dat ..\version\vecfade2.dat ..\version\roto.dat ..\version\crack.dat ..\version\city.dat ..\version\city_fade.dat ..\version\blur.dat ..\version\vectrans1.dat ..\version\spacecut.dat ..\version\vectrans2.dat ..\version\greets.dat ..\version\flight.dat ..\data\flight\pic_0.lz ..\data\flight\pic_1.lz ..\data\flight\pic_2.lz ..\data\flight\pic_3.lz ..\data\flight\pic_4.lz ..\data\flight\pic_5.lz ..\data\flight\pic_6.lz ..\data\flight\pic_7.lz ..\data\flight\pic_8.lz ..\data\flight\pic_9.lz ..\data\flight\pic_10.lz ..\data\flight\pic_11.lz ..\data\flight\pic_12.lz ..\data\flight\pic_13.lz ..\version\logo.dat ..\version\starwars.dat
@if %ERRORLEVEL% NEQ 0 goto failed
cd ..\build

rem ############ START DEMO ############
"..\winuae\winuae" -config="configs\a500.uae" -s use_gui=no -s floppy0=%~dp0\..\version\demo.adf

rem ############ CLEANUP BUILD ############
del vc.cfg
@goto ok

rem ############ ERROR HANDLER ############
:failed
    @echo error in directory "%CD%"
	@cd ..
	@echo !!!!!!!!! fuck !!!!!!!!!!!!
	@pause
	del vc.cfg
:ok

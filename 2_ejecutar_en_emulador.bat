@echo off
REM ==========================================================
REM  GastoFacil - Enciende el emulador de Android y ejecuta la
REM  aplicacion (equivale a "flutter run" en Visual Studio Code).
REM  El registro queda en registro_ejecucion.txt
REM ==========================================================
cd /d "%~dp0"
set LOG=%~dp0registro_ejecucion.txt
echo ===== GastoFacil - ejecucion %date% %time% ===== > "%LOG%"
call flutter emulators >> "%LOG%" 2>&1
set EMU=
for /f "tokens=1" %%e in ('flutter emulators ^| findstr /i "android"') do if not defined EMU set EMU=%%e
echo Emulador elegido: %EMU% >> "%LOG%"
echo Encendiendo el emulador %EMU% ...
start "" /b cmd /c flutter emulators --launch %EMU%
echo Esperando a que el emulador inicie (60 s)...
timeout /t 60 /nobreak
call flutter devices >> "%LOG%" 2>&1
echo Compilando y ejecutando GastoFacil. La primera vez tarda varios minutos...
call flutter run -d emulator-5554 >> "%LOG%" 2>&1

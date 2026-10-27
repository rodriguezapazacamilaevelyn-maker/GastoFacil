@echo off
REM ==========================================================
REM  GastoFacil - Guarda una captura REAL de lo que muestra el
REM  emulador en la carpeta "capturas" (usa adb screencap).
REM ==========================================================
cd /d "%~dp0"
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if not exist "%ADB%" set ADB=adb
if not exist capturas mkdir capturas
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%i
"%ADB%" exec-out screencap -p > "capturas\captura_%TS%.png"
echo Captura guardada: capturas\captura_%TS%.png

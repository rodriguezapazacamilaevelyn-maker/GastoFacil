@echo off
REM ==========================================================
REM  GastoFacil - Ejecuta en el emulador los pasos del archivo
REM  pasos.txt (toques, texto y capturas con adb). Sirve para
REM  obtener las capturas reales de la aplicacion.
REM   CAPTURA nombre  -> guarda capturas\nombre.png
REM   ESPERA n        -> espera n segundos
REM   (otra linea)    -> se ejecuta como: adb <linea>
REM ==========================================================
cd /d "%~dp0"
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if not exist "%ADB%" set ADB=adb
if not exist capturas mkdir capturas
echo ===== pasos %date% %time% ===== > registro_pasos.txt
for /f "usebackq tokens=1,* delims= " %%A in ("pasos.txt") do (
  if /i "%%A"=="CAPTURA" (
    "%ADB%" exec-out screencap -p > "capturas\%%B.png"
    echo captura %%B >> registro_pasos.txt
  ) else if /i "%%A"=="ESPERA" (
    timeout /t %%B /nobreak > nul
  ) else (
    "%ADB%" %%A %%B >> registro_pasos.txt 2>&1
  )
)
echo ===== FIN ===== >> registro_pasos.txt

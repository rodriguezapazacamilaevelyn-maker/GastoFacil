@echo off
REM ==========================================================
REM  GastoFacil - Copia al emulador una copia de respaldo con
REM  datos de PRUEBA (ficticios). Luego, en la app: Inicio >
REM  icono de respaldo > Restaurar.
REM ==========================================================
cd /d "%~dp0"
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if not exist "%ADB%" set ADB=adb
set DESTINO=/sdcard/Android/data/com.itecagastofacil.gastofacil/files/GastoFacil_respaldos/
"%ADB%" push "..\base_de_datos\gastofacil_respaldo_20261006_100000_DEMO.json" %DESTINO% > registro_demo.txt 2>&1
type registro_demo.txt
timeout /t 5

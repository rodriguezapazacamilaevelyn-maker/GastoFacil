@echo off
REM ==========================================================
REM  GastoFacil - Recompila SOLO para el emulador (x86_64, mas
REM  rapido) y reinstala la app conservando los datos.
REM ==========================================================
cd /d "%~dp0"
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
echo ===== actualizar %date% %time% ===== > registro_actualizar.txt
call flutter build apk --release --target-platform android-x64 >> registro_actualizar.txt 2>&1
"%ADB%" install -r build\app\outputs\flutter-apk\app-release.apk >> registro_actualizar.txt 2>&1
"%ADB%" shell am start -n com.itecagastofacil.gastofacil/.MainActivity >> registro_actualizar.txt 2>&1
echo ===== FIN ===== >> registro_actualizar.txt

@echo off
REM ==========================================================
REM  GastoFacil - Inicia el emulador Medium_Phone (arranque rapido
REM  con graficos por software) e instala/abre la app release.
REM  Las pantallas se ven con capturas (5_ejecutar_pasos.bat).
REM ==========================================================
cd /d "%~dp0"
set SDK=%LOCALAPPDATA%\Android\Sdk
set ADB=%SDK%\platform-tools\adb.exe
echo ===== reinicio %date% %time% ===== > registro_reinicio.txt
"%ADB%" emu kill >> registro_reinicio.txt 2>&1
taskkill /f /im qemu-system-x86_64-headless.exe >> registro_reinicio.txt 2>&1
taskkill /f /im qemu-system-x86_64.exe >> registro_reinicio.txt 2>&1
timeout /t 5 /nobreak > nul
start "" "%SDK%\emulator\emulator.exe" -avd Medium_Phone -no-audio -no-boot-anim -gpu swiftshader_indirect
"%ADB%" wait-for-device >> registro_reinicio.txt 2>&1
:esperar
"%ADB%" shell getprop sys.boot_completed 2>nul | findstr "1" > nul
if errorlevel 1 (
  timeout /t 5 /nobreak > nul
  goto esperar
)
echo emulador listo %time% >> registro_reinicio.txt
"%ADB%" shell getprop ro.build.version.release >> registro_reinicio.txt 2>&1
"%ADB%" shell getprop ro.build.version.sdk >> registro_reinicio.txt 2>&1
"%ADB%" shell getprop ro.product.model >> registro_reinicio.txt 2>&1
"%ADB%" shell wm size >> registro_reinicio.txt 2>&1
"%ADB%" shell wm density >> registro_reinicio.txt 2>&1
"%ADB%" install -r build\app\outputs\flutter-apk\app-release.apk >> registro_reinicio.txt 2>&1
"%ADB%" shell am start -n com.itecagastofacil.gastofacil/.MainActivity >> registro_reinicio.txt 2>&1
echo ===== FIN %time% ===== >> registro_reinicio.txt

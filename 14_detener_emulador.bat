@echo off
cd /d "%~dp0"
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
echo ===== detener %date% %time% ===== > registro_detener.txt
"%ADB%" emu kill >> registro_detener.txt 2>&1
timeout /t 5 /nobreak > nul
taskkill /f /im qemu-system-x86_64-headless.exe >> registro_detener.txt 2>&1
taskkill /f /im qemu-system-x86_64.exe >> registro_detener.txt 2>&1
echo ===== FIN ===== >> registro_detener.txt

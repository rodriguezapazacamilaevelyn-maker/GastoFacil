@echo off
cd /d "%~dp0"
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
echo ===== estado %date% %time% ===== > registro_estado.txt
"%ADB%" devices >> registro_estado.txt 2>&1
tasklist | findstr /i "qemu emulator" >> registro_estado.txt 2>&1
"%ADB%" shell getprop sys.boot_completed >> registro_estado.txt 2>&1
"%ADB%" shell getprop ro.build.version.release >> registro_estado.txt 2>&1
"%ADB%" shell getprop ro.build.version.sdk >> registro_estado.txt 2>&1
echo ===== FIN ===== >> registro_estado.txt

@echo off
cd /d "%~dp0"
echo ===== avd %date% %time% ===== > registro_avd.txt
for /d %%D in ("%USERPROFILE%\.android\avd\*.avd") do (
  echo --- %%~nD --- >> registro_avd.txt
  findstr /i "image.sysdir hw.ramSize hw.lcd.width hw.lcd.height hw.lcd.density hw.gpu.mode disk.dataPartition" "%%D\config.ini" >> registro_avd.txt 2>&1
)
systeminfo | findstr /i "Memoria total" >> registro_avd.txt 2>&1
wmic OS get TotalVisibleMemorySize,FreePhysicalMemory >> registro_avd.txt 2>&1
echo ===== FIN ===== >> registro_avd.txt

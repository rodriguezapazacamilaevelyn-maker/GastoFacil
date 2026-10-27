@echo off
REM ==========================================================
REM  GastoFacil - Version para WINDOWS (multiplataforma).
REM  Requiere: Modo de desarrollador de Windows activado y
REM  Visual Studio con "Desarrollo para el escritorio con C++".
REM  El programa queda en build\windows\x64\runner\Release\gastofacil.exe
REM ==========================================================
cd /d "%~dp0"
echo ===== windows %date% %time% ===== > registro_windows.txt
echo --- Modo de desarrollador --- >> registro_windows.txt
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense >> registro_windows.txt 2>&1
call flutter doctor -v >> registro_windows.txt 2>&1
if not exist windows call flutter create --org com.itecagastofacil --project-name gastofacil --platforms windows . >> registro_windows.txt 2>&1
call flutter pub get >> registro_windows.txt 2>&1
call flutter build windows --release >> registro_windows.txt 2>&1
echo ===== FIN BUILD ===== >> registro_windows.txt
if exist build\windows\x64\runner\Release\gastofacil.exe start "" build\windows\x64\runner\Release\gastofacil.exe

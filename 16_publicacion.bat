@echo off
REM ==========================================================
REM  GastoFacil - Compilacion para publicar
REM  Revisa el codigo, corre las pruebas y genera:
REM   - APK universal (build\app\outputs\flutter-apk\app-release.apk)
REM   - APK por arquitectura (mas livianos)
REM   - AAB para Google Play (build\app\outputs\bundle\release\app-release.aab)
REM  Resultado en registro_publicacion.txt
REM ==========================================================
cd /d "%~dp0"
set LOG=%~dp0registro_publicacion.txt
echo ===== publicacion %date% %time% ===== > "%LOG%"
call flutter --version >> "%LOG%" 2>&1
call flutter pub get >> "%LOG%" 2>&1
echo --- analyze --- >> "%LOG%"
call flutter analyze >> "%LOG%" 2>&1
echo --- test --- >> "%LOG%"
call flutter test >> "%LOG%" 2>&1
echo --- apk universal %time% --- >> "%LOG%"
call flutter build apk --release >> "%LOG%" 2>&1
copy /y build\app\outputs\flutter-apk\app-release.apk build\app\outputs\flutter-apk\GastoFacil_v1.2_universal.apk >> "%LOG%" 2>&1
echo --- apk por arquitectura %time% --- >> "%LOG%"
call flutter build apk --release --split-per-abi >> "%LOG%" 2>&1
echo --- aab %time% --- >> "%LOG%"
call flutter build appbundle --release >> "%LOG%" 2>&1
echo --- datos del apk --- >> "%LOG%"
for /d %%B in ("%LOCALAPPDATA%\Android\Sdk\build-tools\*") do set AAPT=%%B\aapt.exe
"%AAPT%" dump badging build\app\outputs\flutter-apk\GastoFacil_v1.2_universal.apk | findstr /i "package sdkVersion targetSdkVersion application-label: native-code uses-permission" >> "%LOG%" 2>&1
echo --- tamanos --- >> "%LOG%"
dir build\app\outputs\flutter-apk\*.apk >> "%LOG%" 2>&1
dir build\app\outputs\bundle\release\*.aab >> "%LOG%" 2>&1
echo ===== FIN %date% %time% ===== >> "%LOG%"

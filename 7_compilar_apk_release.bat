@echo off
REM ==========================================================
REM  GastoFacil - Genera el APK de la version final (release),
REM  mas rapida, y lo instala en el emulador o celular conectado.
REM  El APK queda en build\app\outputs\flutter-apk\app-release.apk
REM ==========================================================
cd /d "%~dp0"
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
echo ===== apk %date% %time% ===== > registro_apk.txt
call flutter build apk --release >> registro_apk.txt 2>&1
"%ADB%" install -r build\app\outputs\flutter-apk\app-release.apk >> registro_apk.txt 2>&1
"%ADB%" shell am start -n com.itecagastofacil.gastofacil/.MainActivity >> registro_apk.txt 2>&1
echo ===== FIN ===== >> registro_apk.txt

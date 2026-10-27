@echo off
REM ==========================================================
REM  GastoFacil - Arma la carpeta de entrega para Google Drive:
REM  ..\..\ENTREGA_GastoFacil_v1.2 con 01 a 05 y un .zip
REM ==========================================================
cd /d "%~dp0"
set RAIZ=%~dp0..\..
set ENT=%RAIZ%\ENTREGA_GastoFacil_v1.2
set LOG=%~dp0registro_entrega_v12.txt
echo ===== entrega %date% %time% ===== > "%LOG%"
mkdir "%ENT%\01_Documentacion" 2>nul
mkdir "%ENT%\02_Codigo_Fuente" 2>nul
mkdir "%ENT%\03_Instalables_APK_AAB" 2>nul
mkdir "%ENT%\04_Pruebas_y_Calidad" 2>nul
mkdir "%ENT%\05_Publicacion" 2>nul
robocopy "%~dp0." "%ENT%\02_Codigo_Fuente\GastoFacil" /E /XD build .dart_tool .idea capturas .git .gradle .kotlin ephemeral /XF registro_*.txt pasos.txt *.iml local.properties key.properties *.jks /NFL /NDL /NJH /NJS >> "%LOG%" 2>&1
set APK=build\app\outputs\flutter-apk
copy /y %APK%\app-release.apk "%ENT%\03_Instalables_APK_AAB\GastoFacil_v1.2_universal.apk" >> "%LOG%" 2>&1
copy /y %APK%\app-arm64-v8a-release.apk "%ENT%\03_Instalables_APK_AAB\GastoFacil_v1.2_arm64-v8a.apk" >> "%LOG%" 2>&1
copy /y %APK%\app-armeabi-v7a-release.apk "%ENT%\03_Instalables_APK_AAB\GastoFacil_v1.2_armeabi-v7a.apk" >> "%LOG%" 2>&1
copy /y %APK%\app-x86_64-release.apk "%ENT%\03_Instalables_APK_AAB\GastoFacil_v1.2_x86_64.apk" >> "%LOG%" 2>&1
copy /y build\app\outputs\bundle\release\app-release.aab "%ENT%\03_Instalables_APK_AAB\GastoFacil_v1.2.aab" >> "%LOG%" 2>&1
copy /y registro_publicacion.txt "%ENT%\04_Pruebas_y_Calidad\registro_analisis_pruebas_y_compilacion.txt" >> "%LOG%" 2>&1
del "%RAIZ%\ENTREGA_GastoFacil_v1.2.zip" 2>nul
powershell -NoProfile -Command "Compress-Archive -Path '%ENT%\*' -DestinationPath '%RAIZ%\ENTREGA_GastoFacil_v1.2.zip' -Force" >> "%LOG%" 2>&1
dir /s "%ENT%" | findstr /i "apk aab docx pdf txt archivos" >> "%LOG%" 2>&1
dir "%RAIZ%" >> "%LOG%" 2>&1
echo ===== FIN %date% %time% ===== >> "%LOG%"

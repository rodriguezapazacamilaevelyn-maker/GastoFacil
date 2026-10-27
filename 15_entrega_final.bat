@echo off
REM ==========================================================
REM  GastoFacil - ENTREGA FINAL (Semana 8)
REM  1) analiza y prueba el codigo  2) compila el APK release
REM  3) arma la carpeta ENTREGA_FINAL_GastoFacil con el orden
REM     pedido (01 a 05)  4) la comprime en .rar (o .zip)
REM ==========================================================
cd /d "%~dp0"
set RAIZ=%~dp0..\..
set ENT=%RAIZ%\ENTREGA_FINAL_GastoFacil
set LOG=%~dp0registro_entrega.txt
echo ===== entrega %date% %time% ===== > "%LOG%"
call flutter pub get >> "%LOG%" 2>&1
echo --- analyze --- >> "%LOG%"
call flutter analyze >> "%LOG%" 2>&1
echo --- test --- >> "%LOG%"
call flutter test >> "%LOG%" 2>&1
echo --- apk --- >> "%LOG%"
call flutter build apk --release >> "%LOG%" 2>&1
echo --- carpetas --- >> "%LOG%"
mkdir "%ENT%\01_Documentacion" 2>nul
mkdir "%ENT%\02_CodigoFuente" 2>nul
mkdir "%ENT%\03_APK_o_Build" 2>nul
mkdir "%ENT%\04_Recursos" 2>nul
mkdir "%ENT%\05_Presentacion" 2>nul
robocopy "%~dp0." "%ENT%\02_CodigoFuente\gastofacil" /E /XD build .dart_tool .idea capturas /XF registro_*.txt pasos.txt *.iml /NFL /NDL /NJH /NJS >> "%LOG%" 2>&1
copy /y build\app\outputs\flutter-apk\app-release.apk "%ENT%\03_APK_o_Build\GastoFacil_v1.1.apk" >> "%LOG%" 2>&1
robocopy "%RAIZ%\GastoFacil\base_de_datos" "%ENT%\04_Recursos\base_de_datos" /E /NFL /NDL /NJH /NJS >> "%LOG%" 2>&1
robocopy "%RAIZ%\documentos\diagramas" "%ENT%\04_Recursos\diagramas_y_capturas" /E /NFL /NDL /NJH /NJS >> "%LOG%" 2>&1
robocopy "%~dp0capturas" "%ENT%\04_Recursos\capturas_emulador" s6_*.png 2*.png /NFL /NDL /NJH /NJS >> "%LOG%" 2>&1
echo --- comprimir --- >> "%LOG%"
del "%RAIZ%\ENTREGA_FINAL_GastoFacil.rar" 2>nul
del "%RAIZ%\ENTREGA_FINAL_GastoFacil.zip" 2>nul
set RAR=
if exist "%ProgramFiles%\WinRAR\Rar.exe" set RAR=%ProgramFiles%\WinRAR\Rar.exe
if exist "%ProgramFiles(x86)%\WinRAR\Rar.exe" set RAR=%ProgramFiles(x86)%\WinRAR\Rar.exe
if defined RAR (
  pushd "%RAIZ%"
  "%RAR%" a -r -ep1 ENTREGA_FINAL_GastoFacil.rar ENTREGA_FINAL_GastoFacil >> "%LOG%" 2>&1
  popd
  echo comprimido en .rar >> "%LOG%"
) else (
  powershell -NoProfile -Command "Compress-Archive -Path '%ENT%' -DestinationPath '%RAIZ%\ENTREGA_FINAL_GastoFacil.zip' -Force" >> "%LOG%" 2>&1
  echo WinRAR no instalado: comprimido en .zip >> "%LOG%"
)
dir "%RAIZ%" >> "%LOG%" 2>&1
echo ===== FIN %date% %time% ===== >> "%LOG%"

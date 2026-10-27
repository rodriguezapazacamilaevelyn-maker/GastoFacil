@echo off
REM ==========================================================
REM  GastoFacil - Prepara el proyecto, revisa el codigo y
REM  ejecuta las pruebas. El resultado se guarda en
REM  registro_compilacion.txt (en esta misma carpeta).
REM ==========================================================
cd /d "%~dp0"
set LOG=%~dp0registro_compilacion.txt
echo ===== GastoFacil - compilacion %date% %time% ===== > "%LOG%"
echo Preparando GastoFacil... espera, esto puede tardar unos minutos.
where flutter >> "%LOG%" 2>&1
call flutter --version >> "%LOG%" 2>&1
if not exist android (
  echo --- flutter create --- >> "%LOG%"
  call flutter create --org com.itecagastofacil --project-name gastofacil --platforms android,windows . >> "%LOG%" 2>&1
)
echo --- flutter pub get --- >> "%LOG%"
call flutter pub get >> "%LOG%" 2>&1
echo --- flutter analyze --- >> "%LOG%"
call flutter analyze >> "%LOG%" 2>&1
echo --- flutter test --- >> "%LOG%"
call flutter test >> "%LOG%" 2>&1
echo --- emuladores --- >> "%LOG%"
call flutter emulators >> "%LOG%" 2>&1
call flutter devices >> "%LOG%" 2>&1
echo ===== FIN ===== >> "%LOG%"
echo Listo. Revisa registro_compilacion.txt
timeout /t 5

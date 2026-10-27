@echo off
chcp 65001 > nul
REM ==========================================================
REM  GastoFacil - Sube el codigo a GitHub con su historial.
REM  Repositorio: rodriguezapazacamilaevelyn-maker/GastoFacil
REM ==========================================================
cd /d "%~dp0"
set REPO=https://github.com/rodriguezapazacamilaevelyn-maker/GastoFacil.git
set LOG=%~dp0registro_github.txt
echo ===== github %date% %time% ===== > "%LOG%"
echo --- analyze y test --- >> "%LOG%"
call flutter analyze >> "%LOG%" 2>&1
call flutter test >> "%LOG%" 2>&1
echo %REPO% >> "%LOG%"
if not exist .git git init -b main >> "%LOG%" 2>&1
git add pubspec.yaml pubspec.lock analysis_options.yaml README.md .gitignore .metadata android web windows >> "%LOG%" 2>&1
git commit -m "Estructura inicial del proyecto Flutter" >> "%LOG%" 2>&1
git add lib/models lib/db >> "%LOG%" 2>&1
git commit -m "Modelos y base de datos SQLite" >> "%LOG%" 2>&1
git add lib/services lib/utils >> "%LOG%" 2>&1
git commit -m "Lógica de finanzas, presupuesto y copias de respaldo" >> "%LOG%" 2>&1
git add lib/screens lib/widgets lib/main.dart >> "%LOG%" 2>&1
git commit -m "Pantallas y componentes de la interfaz" >> "%LOG%" 2>&1
git add test >> "%LOG%" 2>&1
git commit -m "Pruebas automáticas de lógica e interfaz" >> "%LOG%" 2>&1
git add *.bat >> "%LOG%" 2>&1
git commit -m "Scripts de compilación, pruebas y publicación" >> "%LOG%" 2>&1
git add -A >> "%LOG%" 2>&1
git commit -m "Ajustes finales" >> "%LOG%" 2>&1
git branch -M main >> "%LOG%" 2>&1
git remote remove origin > nul 2>&1
git remote add origin %REPO% >> "%LOG%" 2>&1
echo.
echo Subiendo a GitHub... si se abre una ventana, inicia sesion en GitHub y autoriza.
git push -u origin main >> "%LOG%" 2>&1
echo --- historial --- >> "%LOG%"
git log --oneline >> "%LOG%" 2>&1
git remote -v >> "%LOG%" 2>&1
echo ===== FIN %date% %time% ===== >> "%LOG%"
echo.
echo Listo. Revisa registro_github.txt
timeout /t 15

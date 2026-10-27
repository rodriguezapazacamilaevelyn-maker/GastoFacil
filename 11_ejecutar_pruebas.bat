@echo off
REM ==========================================================
REM  GastoFacil - PRUEBAS (Semana 7). Ejecuta todas las pruebas
REM  automaticas (unitarias + interfaz en distintos tamanos) y
REM  guarda el detalle en registro_pruebas.txt
REM ==========================================================
cd /d "%~dp0"
echo ===== pruebas %date% %time% ===== > registro_pruebas.txt
call flutter test --reporter expanded >> registro_pruebas.txt 2>&1
echo ===== FIN %date% %time% ===== >> registro_pruebas.txt

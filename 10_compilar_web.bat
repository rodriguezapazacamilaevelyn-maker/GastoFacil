@echo off
REM ==========================================================
REM  GastoFacil - Version WEB (multiplataforma, Semana 7).
REM  1) agrega la carpeta web\   2) descarga SQLite para el navegador
REM  3) compila la version web (queda en build\web) y la publica en
REM     http://localhost:8090 (abrir en Chrome o Edge).
REM ==========================================================
cd /d "%~dp0"
echo ===== web %date% %time% ===== > registro_web.txt
taskkill /f /im dart.exe >> registro_web.txt 2>&1
taskkill /f /im dartaotruntime.exe >> registro_web.txt 2>&1
if not exist web\index.html call flutter create --org com.itecagastofacil --project-name gastofacil --platforms web . >> registro_web.txt 2>&1
call flutter pub get >> registro_web.txt 2>&1
if not exist web\sqlite3.wasm call dart run sqflite_common_ffi_web:setup >> registro_web.txt 2>&1
echo ===== compilando y publicando (ver registro_web_ejecucion.txt) ===== >> registro_web.txt
start "GastoFacil Web" cmd /c "flutter run -d web-server --release --web-port 8090 > registro_web_ejecucion.txt 2>&1"

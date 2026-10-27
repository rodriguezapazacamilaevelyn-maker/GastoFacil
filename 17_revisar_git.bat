@echo off
cd /d "%~dp0"
echo ===== git %date% %time% ===== > registro_git.txt
where git >> registro_git.txt 2>&1
git --version >> registro_git.txt 2>&1
git config --global user.name >> registro_git.txt 2>&1
git config --global user.email >> registro_git.txt 2>&1
git credential-manager --version >> registro_git.txt 2>&1
echo ===== FIN ===== >> registro_git.txt

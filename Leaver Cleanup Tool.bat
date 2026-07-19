@echo off
title Leaver Cleanup Tool
cd /d "%~dp0"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Disable-RemoveLicenses.ps1"

REM Exit code 42 means the script relaunched itself as a normal user - close this window silently.
if "%errorlevel%"=="42" exit

echo.
pause

@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0START.ps1"
if %ERRORLEVEL% NEQ 0 pause

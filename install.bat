@echo off
REM --------------------------------------------
REM Self-elevating batch to install and launch init.ps1 with bypass
REM Place this file alongside init.ps1 and run it.
REM --------------------------------------------

:: Check for administrative rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: Run init.ps1 with ExecutionPolicy Bypass
echo Running install script with elevated privileges...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0init.ps1"

echo Installation complete. Press any key to exit...
pause >nul

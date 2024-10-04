@echo off
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "auto-attendance-powershell.ps1"
del .\auto-attendance-powershell.ps1
shutdown /s /t 5
del /F /Q "%~f0"
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0build_release_aab.ps1" %*
pause

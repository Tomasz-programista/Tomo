@echo off
rem Double-click me to start TOMO-TV. The first start sets everything up.
setlocal
cd /d "%~dp0"
title TOMO-TV

if exist ".venv\Scripts\pythonw.exe" goto check_update

echo.
echo   ***  TOMO-TV first-time setup  ***
echo   Downloading the video engine (about 300 MB). This only happens once.
echo.

set "PYEXE="
for %%v in (3.14 3.13 3.12 3.11 3.10) do (
    if not defined PYEXE (
        py -%%v -c "import sys" >nul 2>&1 && set "PYEXE=py -%%v"
    )
)
if not defined PYEXE (
    python -c "import sys; sys.exit(0 if (3, 10) <= sys.version_info[:2] <= (3, 14) else 1)" >nul 2>&1 && set "PYEXE=python"
)
if not defined PYEXE goto nopython

echo   Using %PYEXE%
%PYEXE% -m venv .venv
if errorlevel 1 goto failed
".venv\Scripts\python.exe" -m pip install --upgrade pip
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 goto failed
copy /y requirements.txt ".venv\requirements.txt" >nul
goto run

:check_update
fc /b requirements.txt ".venv\requirements.txt" >nul 2>&1
if not errorlevel 1 goto run
echo   Updating TOMO-TV's components...
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 goto failed
copy /y requirements.txt ".venv\requirements.txt" >nul

:run
start "" ".venv\Scripts\pythonw.exe" "%~dp0tomotv.py"
exit /b 0

:nopython
echo   Python 3.10 - 3.14 was not found on this computer.
echo.
echo   1. Go to https://www.python.org/downloads/windows/
echo   2. Download a "Python 3.14" Windows installer (64-bit).
echo      Not 3.15 or newer: the video engine doesn't support it yet.
echo   3. In the installer tick "Add python.exe to PATH", then click "Install Now".
echo   4. Double-click run_windows.bat again.
echo.
pause
exit /b 1

:failed
echo.
echo   Setup failed. Check your internet connection and try again.
echo   If it keeps failing, run debug_windows.bat to see what went wrong.
if exist ".venv" rmdir /s /q ".venv"
pause
exit /b 1

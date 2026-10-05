@echo off
rem Starts TOMO-TV with a console window, so you can see error messages.
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
    echo Run run_windows.bat first.
    pause
    exit /b 1
)
".venv\Scripts\python.exe" tomotv.py
echo.
echo TOMO-TV closed (exit code %errorlevel%).
pause

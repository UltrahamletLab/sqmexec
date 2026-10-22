@echo off
rem promptdb: double-click to start the search server and open the browser.
rem Requires Python 3.7+ (https://www.python.org/ - tick "Add python.exe to PATH").
setlocal
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  echo Python not found. Install Python 3 and tick "Add python.exe to PATH".
  pause
  exit /b 1
)

if not exist prompts.db (
  if exist 70000.txt (
    echo prompts.db not found - building it from 70000.txt ...
    python build_db.py 70000.txt prompts.db
  ) else (
    echo prompts.db not found. Put the source text here as 70000.txt and run again.
    pause
    exit /b 1
  )
)

start "" http://127.0.0.1:8700/
python server.py --port 8700
pause

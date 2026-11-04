@echo off
rem Starts the AI Computer bridge. Output goes to bridge.log next to this file.
cd /d "%~dp0"
python bridge.py >> bridge.log 2>&1

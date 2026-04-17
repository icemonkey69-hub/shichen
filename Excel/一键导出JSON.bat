@echo off
setlocal
pushd "%~dp0.."

echo.
echo Exporting Excel tables to JSON...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\export_excel_to_json.ps1"

if errorlevel 1 (
    echo.
    echo Export failed. Please send me a screenshot of this window.
    echo.
    pause
    popd
    exit /b 1
)

echo.
echo Export completed.
echo Runtime JSON updated in data\tables\
echo.
pause
popd

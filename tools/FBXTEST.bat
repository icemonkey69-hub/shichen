@echo off
setlocal EnableExtensions

set "TOOLS_DIR=%~dp0"
for %%I in ("%TOOLS_DIR%..") do set "PROJECT_ROOT=%%~fI"

set "INPUT_ROOT=E:\Godot\test"
set "OUTPUT_DIR=%PROJECT_ROOT%\combat_visual_editor\newmodel\characters"
set "PY_SCRIPT=%TOOLS_DIR%build_newmodel_pack.py"
set "MAX_TEXTURE_SIZE=1024"
set "TARGET_MAX_DIMENSION=0"

set "BLENDER_EXE="
if exist "E:\Blender\Blender.exe" set "BLENDER_EXE=E:\Blender\Blender.exe"
if not defined BLENDER_EXE for %%B in (blender.exe) do set "BLENDER_EXE=%%~$PATH:B"

if not exist "%PY_SCRIPT%" (
  echo [ERROR] Missing script: %PY_SCRIPT%
  exit /b 1
)

if not defined BLENDER_EXE (
  echo [ERROR] Blender not found. Expected E:\Blender\Blender.exe or blender.exe in PATH.
  exit /b 1
)

if not exist "%INPUT_ROOT%" (
  echo [ERROR] Input root not found: %INPUT_ROOT%
  exit /b 1
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [INFO] Blender: %BLENDER_EXE%
echo [INFO] Input : %INPUT_ROOT%
echo [INFO] Output: %OUTPUT_DIR%
echo [INFO] Max Texture Size: %MAX_TEXTURE_SIZE%
echo [INFO] Target Max Dimension: %TARGET_MAX_DIMENSION%
echo [INFO] Building NewModel pack...

"%BLENDER_EXE%" --background --python-exit-code 1 --python "%PY_SCRIPT%" -- --input-root "%INPUT_ROOT%" --output-dir "%OUTPUT_DIR%" --max-texture-size "%MAX_TEXTURE_SIZE%" --target-max-dimension "%TARGET_MAX_DIMENSION%"
if errorlevel 1 (
  echo [ERROR] Build failed.
  exit /b 1
)

echo [DONE] NewModel pack ready.
exit /b 0

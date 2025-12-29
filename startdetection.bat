@echo off
SETLOCAL EnableDelayedExpansion

REM ============================================================
REM MaskRCNN Detection Runner - Version 2.2
REM Fixed: Clears inherited Python environment variables
REM        that interfere with conda when run from Rhino/GH
REM ============================================================

SET "ENV_NAME=MaskRCNN_Detection"
SET "SCRIPT_DIR=%~dp0"
SET "CONDA_CONFIG=%SCRIPT_DIR%.conda_path"

REM ============================================================
REM CRITICAL FIX: Clear Python environment variables
REM These can be inherited from Rhino/Grasshopper and break conda
REM ============================================================
SET "PYTHONPATH="
SET "PYTHONHOME="
SET "CONDA_PREFIX="
SET "CONDA_DEFAULT_ENV="
SET "CONDA_SHLVL="
SET "_CONDA_ROOT="
SET "CONDA_PROMPT_MODIFIER="
SET "CONDA_EXE="
SET "CONDA_PYTHON_EXE="
SET "IRONPYTHONPATH="

echo ========================================================
echo   MaskRCNN Architectural Elements Detection v2.2
echo ========================================================
echo.
echo   Cleared inherited environment variables.
echo.

REM ============================================================
REM STEP 1: Find Conda
REM ============================================================

SET "CONDA_PATH="

echo [1/5] Finding Conda installation...

REM First check config file (fastest)
if exist "%CONDA_CONFIG%" (
    set /p CONDA_PATH=<"%CONDA_CONFIG%"
    if exist "!CONDA_PATH!\condabin\conda.bat" (
        echo   [OK] Found from config: !CONDA_PATH!
        goto :conda_found
    )
    SET "CONDA_PATH="
)

REM Check portable installation
if exist "%SCRIPT_DIR%miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=%SCRIPT_DIR%miniconda3"
    echo   [OK] Found portable: !CONDA_PATH!
    echo !CONDA_PATH!> "%CONDA_CONFIG%"
    goto :conda_found
)

REM Check common locations
for %%P in (
    "%USERPROFILE%\Miniconda3"
    "%USERPROFILE%\miniconda3"
    "%USERPROFILE%\Anaconda3"
    "%USERPROFILE%\anaconda3"
    "%LOCALAPPDATA%\anaconda3"
    "%LOCALAPPDATA%\miniconda3"
    "%LOCALAPPDATA%\Continuum\anaconda3"
    "%LOCALAPPDATA%\Continuum\miniconda3"
    "C:\ProgramData\Anaconda3"
    "C:\ProgramData\Miniconda3"
    "C:\Anaconda3"
    "C:\Miniconda3"
) do (
    if exist "%%~P\condabin\conda.bat" (
        SET "CONDA_PATH=%%~P"
        echo   [OK] Found: %%~P
        echo %%~P> "%CONDA_CONFIG%"
        goto :conda_found
    )
)

echo   [ERROR] Conda installation not found!
echo.
echo   Please run environmentsetup.bat first.
echo.
pause
exit /b 1

:conda_found
echo.

REM ============================================================
REM STEP 2: Setup Clean Environment
REM ============================================================

echo [2/5] Setting up clean environment...

REM Set minimal clean PATH
SET "PATH=%CONDA_PATH%\condabin;%CONDA_PATH%\Library\bin;%CONDA_PATH%\Scripts;%CONDA_PATH%;%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"

REM ============================================================
REM STEP 3: Check Environment Exists
REM ============================================================

echo [3/5] Checking %ENV_NAME% environment...

REM Use full path to conda.bat for reliability
CALL "%CONDA_PATH%\condabin\conda.bat" env list 2>nul | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   [ERROR] Environment '%ENV_NAME%' does not exist!
    echo.
    echo   Please run environment setup first:
    echo     %SCRIPT_DIR%environmentsetup.bat
    echo.
    pause
    exit /b 1
)

echo   [OK] Environment exists

REM ============================================================
REM STEP 4: Activate Environment
REM ============================================================

echo [4/5] Activating %ENV_NAME% environment...

CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%
if %errorlevel% neq 0 (
    echo   [WARNING] Activation returned error, using alternative method...
    REM Alternative: directly set paths for the environment
    SET "PATH=%CONDA_PATH%\envs\%ENV_NAME%;%CONDA_PATH%\envs\%ENV_NAME%\Scripts;%CONDA_PATH%\envs\%ENV_NAME%\Library\bin;%PATH%"
)

echo   [OK] Environment activated
echo.

REM ============================================================
REM STEP 5: Run Detection
REM ============================================================

echo [5/5] Running detection script...
echo.

REM Find Python script
SET "SCRIPT_PATH=%SCRIPT_DIR%StartMasksDetection.py"

if not exist "%SCRIPT_PATH%" (
    echo   [ERROR] StartMasksDetection.py not found!
    echo   Expected at: %SCRIPT_PATH%
    echo.
    pause
    exit /b 1
)

REM Create necessary directories
if not exist "%SCRIPT_DIR%SavedMasks" mkdir "%SCRIPT_DIR%SavedMasks"
if not exist "%SCRIPT_DIR%images" mkdir "%SCRIPT_DIR%images"
if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

REM Check for model file
SET "MODEL_FOUND=0"
for %%f in ("%SCRIPT_DIR%*.h5") do SET "MODEL_FOUND=1"
if %MODEL_FOUND% equ 0 (
    echo   [WARNING] No .h5 model file found in %SCRIPT_DIR%
    echo.
)

REM Count images
SET "IMAGE_COUNT=0"
for %%f in ("%SCRIPT_DIR%images\*.png" "%SCRIPT_DIR%images\*.jpg" "%SCRIPT_DIR%images\*.jpeg" "%SCRIPT_DIR%images\*.bmp" "%SCRIPT_DIR%images\*.tiff" "%SCRIPT_DIR%images\*.tif") do (
    SET /A IMAGE_COUNT+=1
)

echo ========================================================
echo   Detection Configuration
echo ========================================================
echo   Conda: %CONDA_PATH%
echo   Environment: %ENV_NAME%
echo   Script: %SCRIPT_PATH%
echo   Images found: %IMAGE_COUNT%
echo ========================================================
echo.

if %IMAGE_COUNT% equ 0 (
    echo   [WARNING] No images found in: %SCRIPT_DIR%images
    echo   Please add images before running detection.
    echo.
)

REM Show system info
echo System Information:
"%CONDA_PATH%\envs\%ENV_NAME%\python.exe" -c "import platform; print('  Python:', platform.python_version())" 2>nul
"%CONDA_PATH%\envs\%ENV_NAME%\python.exe" -c "import tensorflow as tf; print('  TensorFlow:', tf.__version__)" 2>nul
"%CONDA_PATH%\envs\%ENV_NAME%\python.exe" -c "import keras; print('  Keras:', keras.__version__)" 2>nul
"%CONDA_PATH%\envs\%ENV_NAME%\python.exe" -c "import cv2; print('  OpenCV:', cv2.__version__)" 2>nul
echo.

echo ========================================================
echo   Starting Detection Process...
echo ========================================================
echo.

SET "START_TIME=%time%"

REM Run using full path to python in environment
"%CONDA_PATH%\envs\%ENV_NAME%\python.exe" "%SCRIPT_PATH%"
SET "EXIT_CODE=%errorlevel%"

SET "END_TIME=%time%"

echo.
echo ========================================================
if %EXIT_CODE% equ 0 (
    echo   SUCCESS: Detection completed!
    echo ========================================================
    echo.
    echo   Results saved to: %SCRIPT_DIR%SavedMasks\
    echo   - detection_results.json
    echo   - detection_result_*.png
    echo.
) else (
    echo   ERROR: Detection failed with code %EXIT_CODE%
    echo ========================================================
    echo.
    echo   Common solutions:
    echo   1. Check if .h5 model file exists
    echo   2. Check if images folder has images
    echo   3. Check error messages above
    echo.
)

echo   Started: %START_TIME%
echo   Finished: %END_TIME%
echo.
echo ========================================================
pause

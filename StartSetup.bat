@echo off
SETLOCAL EnableDelayedExpansion

REM ============================================================
REM MaskRCNN Detection Runner - Version 2.1
REM Smart Conda detection with config file support
REM ============================================================

SET "ENV_NAME=MaskRCNN_Detection"
SET "SCRIPT_DIR=%~dp0"
SET "CONDA_CONFIG=%SCRIPT_DIR%.conda_path"

echo.
echo ========================================================
echo   MaskRCNN Architectural Elements Detection v2.1
echo ========================================================
echo.

REM ============================================================
REM STEP 1: Find Conda Installation
REM ============================================================

SET "CONDA_PATH="

echo [1/5] Finding Conda installation...

REM Strategy 1: Check saved config file (fastest)
if exist "%CONDA_CONFIG%" (
    set /p CONDA_PATH=<"%CONDA_CONFIG%"
    if exist "!CONDA_PATH!\condabin\conda.bat" (
        echo   [OK] Found from config: !CONDA_PATH!
        goto :conda_found
    ) else (
        echo   [!] Config path invalid, searching...
        SET "CONDA_PATH="
    )
)

REM Strategy 2: Check for portable Miniconda
if exist "%SCRIPT_DIR%miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=%SCRIPT_DIR%miniconda3"
    echo   [OK] Found portable: !CONDA_PATH!
    echo !CONDA_PATH!> "%CONDA_CONFIG%"
    goto :conda_found
)

REM Strategy 3: Search common locations
echo   Searching common paths...

for %%P in (
    "%USERPROFILE%\Anaconda3"
    "%USERPROFILE%\anaconda3"
    "%USERPROFILE%\Miniconda3"
    "%USERPROFILE%\miniconda3"
    "%LOCALAPPDATA%\anaconda3"
    "%LOCALAPPDATA%\miniconda3"
    "%LOCALAPPDATA%\Continuum\anaconda3"
    "C:\ProgramData\Anaconda3"
    "C:\ProgramData\anaconda3"
    "C:\ProgramData\Miniconda3"
    "C:\ProgramData\miniconda3"
    "C:\Anaconda3"
    "C:\anaconda3"
    "C:\Miniconda3"
    "C:\miniconda3"
) do (
    if exist "%%~P\condabin\conda.bat" (
        SET "CONDA_PATH=%%~P"
        echo   [OK] Found: %%~P
        echo %%~P> "%CONDA_CONFIG%"
        goto :conda_found
    )
)

REM Strategy 4: Try PATH
echo   Checking PATH...
where conda >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('conda info --base 2^>nul') do (
        if exist "%%i\condabin\conda.bat" (
            SET "CONDA_PATH=%%i"
            echo   [OK] Found in PATH: %%i
            echo %%i> "%CONDA_CONFIG%"
            goto :conda_found
        )
    )
)

REM Conda not found
echo.
echo ========================================================
echo   ERROR: Conda installation not found!
echo ========================================================
echo.
echo   Please run the installer first:
echo     1. Open Grasshopper
echo     2. Run the MaskRCNN Installer component
echo     3. Click "Full Auto Install"
echo.
echo   Or run: %SCRIPT_DIR%environmentsetup.bat
echo.
pause
exit /b 1

:conda_found
echo.

REM ============================================================
REM STEP 2: Activate Environment
REM ============================================================

echo [2/5] Activating %ENV_NAME% environment...

REM Set clean PATH
SET "PATH=%CONDA_PATH%\condabin;%CONDA_PATH%\Scripts;%CONDA_PATH%;%SystemRoot%\system32;%SystemRoot%"

REM Check if environment exists
CALL "%CONDA_PATH%\condabin\conda.bat" env list | findstr /C:"%ENV_NAME%" >nul 2>&1
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

REM Activate environment
CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%
if %errorlevel% neq 0 (
    echo   [ERROR] Failed to activate environment!
    pause
    exit /b 1
)

echo   [OK] Environment activated

REM ============================================================
REM STEP 3: Verify Requirements
REM ============================================================

echo.
echo [3/5] Verifying requirements...

REM Check TensorFlow
python -c "import tensorflow as tf; print('   TensorFlow:', tf.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] TensorFlow not installed!
    echo   Please run: %SCRIPT_DIR%environmentsetup.bat
    pause
    exit /b 1
)

REM Check Keras
python -c "import keras; print('   Keras:', keras.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] Keras not installed!
    pause
    exit /b 1
)

REM Check OpenCV
python -c "import cv2; print('   OpenCV:', cv2.__version__)" 2>nul

REM Check detection script
SET "SCRIPT_PATH=%SCRIPT_DIR%StartMasksDetection.py"
if not exist "%SCRIPT_PATH%" (
    echo.
    echo   [ERROR] StartMasksDetection.py not found!
    echo   Expected: %SCRIPT_PATH%
    echo.
    pause
    exit /b 1
)
echo   [OK] Detection script found

REM Check model file
SET "MODEL_FOUND=0"
if exist "%SCRIPT_DIR%mask_rcnn_food_0029.h5" (
    SET "MODEL_FOUND=1"
    echo   [OK] Model: mask_rcnn_food_0029.h5
)
if exist "%SCRIPT_DIR%mask_rcnn_food_0019.h5" (
    SET "MODEL_FOUND=1"
    echo   [OK] Model: mask_rcnn_food_0019.h5
)
if %MODEL_FOUND%==0 (
    echo   [WARNING] No model file found!
    echo   Please download the model using the installer.
)

REM ============================================================
REM STEP 4: Prepare Directories
REM ============================================================

echo.
echo [4/5] Preparing directories...

if not exist "%SCRIPT_DIR%SavedMasks" (
    mkdir "%SCRIPT_DIR%SavedMasks"
    echo   [OK] Created: SavedMasks
)

if not exist "%SCRIPT_DIR%images" (
    mkdir "%SCRIPT_DIR%images"
    echo   [OK] Created: images
    echo.
    echo   *** IMPORTANT ***
    echo   Please place your test images in the 'images' folder!
    echo   Supported: PNG, JPG, JPEG, BMP, TIFF
    echo.
)

if not exist "%SCRIPT_DIR%logs" (
    mkdir "%SCRIPT_DIR%logs"
    echo   [OK] Created: logs
)

REM Count images
SET "IMAGE_COUNT=0"
for %%f in ("%SCRIPT_DIR%images\*.png" "%SCRIPT_DIR%images\*.jpg" "%SCRIPT_DIR%images\*.jpeg" "%SCRIPT_DIR%images\*.bmp" "%SCRIPT_DIR%images\*.tiff") do (
    SET /A IMAGE_COUNT+=1
)
echo   Images found: %IMAGE_COUNT%

if %IMAGE_COUNT%==0 (
    echo.
    echo   [WARNING] No images found in the images folder!
    echo   Please add images before running detection.
    echo.
)

REM ============================================================
REM STEP 5: Run Detection
REM ============================================================

echo.
echo [5/5] Starting detection...
echo.
echo ========================================================
echo   System Information:
python -c "import platform; print('   Python:', platform.python_version())"

REM Check GPU
echo.
echo   GPU Status:
python -c "import os; os.environ['TF_CPP_MIN_LOG_LEVEL']='3'; import tensorflow as tf; gpu = tf.test.is_gpu_available(); print('   GPU Available:', gpu)" 2>nul

echo.
echo ========================================================
echo   Running MaskRCNN Detection...
echo   Started: %time%
echo ========================================================
echo.

REM Record start time
SET "START_TIME=%time%"

REM Change to script directory and run
cd /d "%SCRIPT_DIR%"
python "%SCRIPT_PATH%"

SET "EXIT_CODE=%errorlevel%"
SET "END_TIME=%time%"

echo.
echo ========================================================
echo   Detection Complete
echo   Started:  %START_TIME%
echo   Finished: %END_TIME%
echo   Exit code: %EXIT_CODE%
echo ========================================================

if %EXIT_CODE% neq 0 (
    echo.
    echo   [ERROR] Detection failed with code %EXIT_CODE%
    echo.
    echo   Common solutions:
    echo     1. Check if model file exists
    echo     2. Check if images folder has images
    echo     3. Review error messages above
    echo     4. GPU errors will auto-fallback to CPU
    echo.
) else (
    echo.
    echo   [SUCCESS] Detection completed!
    echo.
    echo   Results saved to:
    echo     %SCRIPT_DIR%SavedMasks\
    echo.
)

echo Press any key to exit...
pause >nul

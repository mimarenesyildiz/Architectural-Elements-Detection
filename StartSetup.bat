@echo off
SETLOCAL EnableDelayedExpansion
SET "ENV_NAME=MaskRCNN_Detection"

echo ====================================
echo MaskRCNN Architectural Elements Detection
echo ====================================
echo.

REM Get the directory where this bat file is located
SET "SCRIPT_DIR=%~dp0"

REM Find conda installation
SET "CONDA_PATH="

echo Searching for Conda installation...

REM Check common Conda locations
if exist "C:\Users\%USERNAME%\Anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\Anaconda3"
    echo FOUND: C:\Users\%USERNAME%\Anaconda3
    goto :conda_found
)

if exist "C:\Users\%USERNAME%\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\anaconda3"
    echo FOUND: C:\Users\%USERNAME%\anaconda3
    goto :conda_found
)

if exist "C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3"
    echo FOUND: C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3
    goto :conda_found
)

if exist "C:\Users\%USERNAME%\AppData\Local\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\AppData\Local\anaconda3"
    echo FOUND: C:\Users\%USERNAME%\AppData\Local\anaconda3
    goto :conda_found
)

if exist "C:\ProgramData\Anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\ProgramData\Anaconda3"
    echo FOUND: C:\ProgramData\Anaconda3
    goto :conda_found
)

if exist "C:\ProgramData\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\ProgramData\anaconda3"
    echo FOUND: C:\ProgramData\anaconda3
    goto :conda_found
)

if exist "C:\Anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Anaconda3"
    echo FOUND: C:\Anaconda3
    goto :conda_found
)

if exist "C:\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\anaconda3"
    echo FOUND: C:\anaconda3
    goto :conda_found
)

if exist "C:\Users\%USERNAME%\Miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\Miniconda3"
    echo FOUND: C:\Users\%USERNAME%\Miniconda3
    goto :conda_found
)

if exist "C:\Users\%USERNAME%\miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\miniconda3"
    echo FOUND: C:\Users\%USERNAME%\miniconda3
    goto :conda_found
)

if exist "C:\ProgramData\Miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\ProgramData\Miniconda3"
    echo FOUND: C:\ProgramData\Miniconda3
    goto :conda_found
)

if exist "C:\ProgramData\miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\ProgramData\miniconda3"
    echo FOUND: C:\ProgramData\miniconda3
    goto :conda_found
)

REM If not found in common locations, try PATH
echo Checking if conda is available in PATH...
where conda >nul 2>&1
if %errorlevel% equ 0 (
    echo Conda found in PATH, trying to get base path...
    for /f "tokens=*" %%i in ('conda info --base 2^>nul') do set "CONDA_PATH=%%i"
    if defined CONDA_PATH (
        echo FOUND: %CONDA_PATH%
        goto :conda_found
    )
)

echo ====================================
echo ERROR: Conda installation not found!
echo ====================================
echo Please ensure Anaconda or Miniconda is installed.
echo Download from: https://www.anaconda.com/products/distribution
echo.
pause
exit /b 1

:conda_found
echo ====================================
echo Using Conda at: %CONDA_PATH%
echo ====================================

REM Check if environment exists
echo Checking if %ENV_NAME% environment exists...
CALL "%CONDA_PATH%\condabin\conda.bat" env list | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo ====================================
    echo ERROR: Environment '%ENV_NAME%' does not exist!
    echo ====================================
    echo Please run the installer component first to create the environment.
    echo.
    pause
    exit /b 1
)

echo Environment %ENV_NAME% found!
echo.

REM Activate environment
echo Activating %ENV_NAME% environment...
CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%

if %errorlevel% neq 0 (
    echo ERROR: Failed to activate environment!
    pause
    exit /b 1
)

echo Environment activated successfully!
echo.

REM Verify critical packages before running
echo Verifying required packages...
python -c "import tensorflow as tf; print('TensorFlow version:', tf.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo ERROR: TensorFlow not properly installed!
    echo Please run the installer component to fix the environment.
    pause
    exit /b 1
)

python -c "import keras; print('Keras version:', keras.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Keras not properly installed!
    echo Please run the installer component to fix the environment.
    pause
    exit /b 1
)

REM Check for script
SET "SCRIPT_PATH=%SCRIPT_DIR%StartMasksDetection.py"
if not exist "%SCRIPT_PATH%" (
    echo ====================================
    echo ERROR: StartMasksDetection.py not found!
    echo ====================================
    echo Expected location: %SCRIPT_PATH%
    echo.
    pause
    exit /b 1
)

REM Create necessary directories
if not exist "%SCRIPT_DIR%SavedMasks" (
    mkdir "%SCRIPT_DIR%SavedMasks"
    echo Created SavedMasks directory
)

if not exist "%SCRIPT_DIR%images" (
    mkdir "%SCRIPT_DIR%images"
    echo Created images directory
    echo.
    echo *** IMPORTANT ***
    echo Please place your test images in the 'images' folder!
    echo Supported formats: PNG, JPG, JPEG, BMP, TIFF
    echo.
)

if not exist "%SCRIPT_DIR%logs" (
    mkdir "%SCRIPT_DIR%logs"
    echo Created logs directory
)

REM Check for model file
if not exist "%SCRIPT_DIR%mask_rcnn_food_0029.h5" (
    if not exist "%SCRIPT_DIR%mask_rcnn_food_0019.h5" (
        echo WARNING: Model weights file not found!
        echo Please ensure mask_rcnn_food_*.h5 file is in: %SCRIPT_DIR%
        echo.
    )
)

REM Count images
SET "IMAGE_COUNT=0"
for %%f in ("%SCRIPT_DIR%images\*.png" "%SCRIPT_DIR%images\*.jpg" "%SCRIPT_DIR%images\*.jpeg" "%SCRIPT_DIR%images\*.bmp" "%SCRIPT_DIR%images\*.tiff") do (
    SET /A IMAGE_COUNT+=1
)

echo.
echo Ready to run MaskRCNN detection...
echo - Environment: %ENV_NAME%
echo - Script: %SCRIPT_PATH%
echo - Images found: %IMAGE_COUNT%
echo.

REM Display system information
echo System Information:
python -c "import platform; print('Python:', platform.python_version())"
python -c "import cv2; print('OpenCV:', cv2.__version__)"

REM Check GPU availability with better error handling
echo.
echo Checking GPU availability...
python -c "import os; os.environ['TF_CPP_MIN_LOG_LEVEL']='3'; try: import tensorflow as tf; gpu = tf.test.is_gpu_available(cuda_only=False, min_cuda_compute_capability=None); print('GPU Available:', gpu); except: print('GPU Available: False (CUDA not properly configured)')" 2>nul

echo.
echo ====================================
echo Starting detection process...
echo ====================================

REM Record start time
SET "START_TIME=%time%"

REM Change to script directory and run
cd /d "%SCRIPT_DIR%"
python "%SCRIPT_PATH%"

SET "EXIT_CODE=%errorlevel%"

REM Record end time
SET "END_TIME=%time%"

echo.
echo ====================================
echo Process completed at: %END_TIME%
echo Started at: %START_TIME%
echo Exit code: %EXIT_CODE%
echo ====================================

if %EXIT_CODE% neq 0 (
    echo.
    echo ERROR: Script execution failed with error code %EXIT_CODE%
    echo.
    echo Common solutions:
    echo 1. Check if model file exists in: %SCRIPT_DIR%
    echo 2. Check if images folder contains test images
    echo 3. Check if all required packages are installed
    echo 4. If GPU errors occur, the script will automatically use CPU
    echo 5. Review the error messages above
) else (
    echo.
    echo SUCCESS: Script executed successfully!
    echo.
    echo Results have been saved to:
    echo - %SCRIPT_DIR%SavedMasks\
)

echo.
echo ====================================
echo Process finished. Press any key to exit.
echo ====================================
pause >nul

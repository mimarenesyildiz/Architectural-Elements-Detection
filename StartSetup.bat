@echo off
echo ====================================
echo MaskRCNN Architectural Elements Detection
echo ====================================
echo.

REM Get the directory where this bat file is located
SET "SCRIPT_DIR=%~dp0"
SET "ENV_NAME=MaskRCNN_Detection"

REM Find conda installation
SET "CONDA_PATH="

echo Searching for Conda installation...

REM Check common Conda locations
if exist "C:\Users\%USERNAME%\Anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\Users\%USERNAME%\Anaconda3"
if exist "C:\Users\%USERNAME%\anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\Users\%USERNAME%\anaconda3"
if exist "C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3"
if exist "C:\Users\%USERNAME%\AppData\Local\anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\Users\%USERNAME%\AppData\Local\anaconda3"
if exist "C:\ProgramData\Anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\ProgramData\Anaconda3"
if exist "C:\ProgramData\anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\ProgramData\anaconda3"
if exist "C:\Anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\Anaconda3"
if exist "C:\anaconda3\condabin\conda.bat" SET "CONDA_PATH=C:\anaconda3"
if exist "C:\Users\%USERNAME%\Miniconda3\condabin\conda.bat" SET "CONDA_PATH=C:\Users\%USERNAME%\Miniconda3"
if exist "C:\Users\%USERNAME%\miniconda3\condabin\conda.bat" SET "CONDA_PATH=C:\Users\%USERNAME%\miniconda3"
if exist "C:\ProgramData\Miniconda3\condabin\conda.bat" SET "CONDA_PATH=C:\ProgramData\Miniconda3"
if exist "C:\ProgramData\miniconda3\condabin\conda.bat" SET "CONDA_PATH=C:\ProgramData\miniconda3"

if not defined CONDA_PATH (
    echo ====================================
    echo ERROR: Conda installation not found!
    echo ====================================
    echo Please ensure Anaconda or Miniconda is installed.
    echo Download from: https://www.anaconda.com/products/distribution
    echo.
    pause
    exit /b 1
)

echo Found Conda at: %CONDA_PATH%
echo.

REM Activate environment
echo Activating %ENV_NAME% environment...
CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%

if %errorlevel% neq 0 (
    echo ====================================
    echo ERROR: Failed to activate environment!
    echo ====================================
    echo The environment '%ENV_NAME%' does not exist.
    echo Please run the installer component first.
    echo.
    pause
    exit /b 1
)

echo Environment activated successfully!
echo.

REM Verify Python version
echo Checking Python version...
python --version

REM Check for required script
if not exist "%SCRIPT_DIR%StartMasksDetection.py" (
    echo ====================================
    echo ERROR: StartMasksDetection.py not found!
    echo ====================================
    echo Expected location: %SCRIPT_DIR%StartMasksDetection.py
    echo.
    pause
    exit /b 1
)

REM Create necessary directories
if not exist "%SCRIPT_DIR%SavedMasks" mkdir "%SCRIPT_DIR%SavedMasks"
if not exist "%SCRIPT_DIR%images" (
    mkdir "%SCRIPT_DIR%images"
    echo.
    echo *** IMPORTANT ***
    echo Please place your test images in the 'images' folder!
    echo Supported formats: PNG, JPG, JPEG, BMP, TIFF
    echo.
)
if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

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
echo - Script: %SCRIPT_DIR%StartMasksDetection.py
echo - Images found: %IMAGE_COUNT%
echo.

REM Display system information
echo System Information:
python -c "import platform; print('Python:', platform.python_version())"
python -c "import tensorflow as tf; print('TensorFlow:', tf.__version__)" 2>nul
python -c "import keras; print('Keras:', keras.__version__)" 2>nul

REM Check GPU
echo.
python -c "import tensorflow as tf; gpu = tf.test.is_gpu_available(); print('GPU Available:', gpu)" 2>nul

echo.
echo ====================================
echo Starting detection process...
echo ====================================

REM Record start time
SET "START_TIME=%time%"

REM Change to script directory and run
cd /d "%SCRIPT_DIR%"
python StartMasksDetection.py

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
    echo 4. Review the error messages above
) else (
    echo.
    echo SUCCESS: Script executed successfully!
    echo.
    echo Results have been saved to:
    echo - %SCRIPT_DIR%SavedMasks\
)

REM Deactivate environment
echo.
echo Deactivating environment...
CALL "%CONDA_PATH%\condabin\conda.bat" deactivate

echo.
echo ====================================
echo Process finished. Press any key to exit.
echo ====================================
pause >nul

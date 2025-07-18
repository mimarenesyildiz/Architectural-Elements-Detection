@echo off
SETLOCAL EnableDelayedExpansion
SET "ENV_NAME=MaskRCNN_Detection"

echo ====================================
echo MaskRCNN Detection Runner
echo ====================================
echo.

echo Searching for Conda installation...

REM Try to find conda in common locations
SET "CONDA_PATH="

echo Checking: C:\Users\%USERNAME%\Anaconda3
if exist "C:\Users\%USERNAME%\Anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\Anaconda3"
    echo FOUND: C:\Users\%USERNAME%\Anaconda3
    goto :conda_found
)

echo Checking: C:\Users\%USERNAME%\anaconda3
if exist "C:\Users\%USERNAME%\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\anaconda3"
    echo FOUND: C:\Users\%USERNAME%\anaconda3
    goto :conda_found
)

echo Checking: C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3
if exist "C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3"
    echo FOUND: C:\Users\%USERNAME%\AppData\Local\Continuum\anaconda3
    goto :conda_found
)

echo Checking: C:\Users\%USERNAME%\AppData\Local\anaconda3
if exist "C:\Users\%USERNAME%\AppData\Local\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\AppData\Local\anaconda3"
    echo FOUND: C:\Users\%USERNAME%\AppData\Local\anaconda3
    goto :conda_found
)

echo Checking: C:\ProgramData\Anaconda3
if exist "C:\ProgramData\Anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\ProgramData\Anaconda3"
    echo FOUND: C:\ProgramData\Anaconda3
    goto :conda_found
)

echo Checking: C:\ProgramData\anaconda3
if exist "C:\ProgramData\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\ProgramData\anaconda3"
    echo FOUND: C:\ProgramData\anaconda3
    goto :conda_found
)

echo Checking: C:\Anaconda3
if exist "C:\Anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Anaconda3"
    echo FOUND: C:\Anaconda3
    goto :conda_found
)

echo Checking: C:\anaconda3
if exist "C:\anaconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\anaconda3"
    echo FOUND: C:\anaconda3
    goto :conda_found
)

echo Checking: C:\Users\%USERNAME%\Miniconda3
if exist "C:\Users\%USERNAME%\Miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\Miniconda3"
    echo FOUND: C:\Users\%USERNAME%\Miniconda3
    goto :conda_found
)

echo Checking: C:\Users\%USERNAME%\miniconda3
if exist "C:\Users\%USERNAME%\miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\Users\%USERNAME%\miniconda3"
    echo FOUND: C:\Users\%USERNAME%\miniconda3
    goto :conda_found
)

echo Checking: C:\ProgramData\Miniconda3
if exist "C:\ProgramData\Miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=C:\ProgramData\Miniconda3"
    echo FOUND: C:\ProgramData\Miniconda3
    goto :conda_found
)

echo Checking: C:\ProgramData\miniconda3
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
echo Please run environmentsetup.bat first.
echo.
pause
exit /b 1

:conda_found
echo ====================================
echo Using Conda installation at: %CONDA_PATH%
echo ====================================

REM Check if environment already exists
echo Checking if %ENV_NAME% environment exists...
CALL "%CONDA_PATH%\condabin\conda.bat" env list | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo ====================================
    echo ERROR: Environment %ENV_NAME% not found!
    echo ====================================
    echo Please run environmentsetup.bat first to create the environment.
    echo.
    pause
    exit /b 1
)

echo ====================================
echo Activating %ENV_NAME% environment and running script...
echo ====================================

REM Activate environment
CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%

REM Find StartMasksDetection.py script in the same directory as batch file
SET "SCRIPT_PATH="

echo Searching for StartMasksDetection.py...

REM Get the directory where this batch file is located
SET "BATCH_DIR=%~dp0"
echo Checking batch file directory: %BATCH_DIR%

REM Check in the same directory as the batch file
if exist "%BATCH_DIR%StartMasksDetection.py" (
    SET "SCRIPT_PATH=%BATCH_DIR%StartMasksDetection.py"
    echo FOUND: %SCRIPT_PATH%
    goto :run_script
)

echo ====================================
echo ERROR: StartMasksDetection.py not found!
echo ====================================
echo Searched location:
echo - Batch file directory: %BATCH_DIR%
echo.
echo Please place the StartMasksDetection.py file in the same directory as this batch file.
echo.
pause
exit /b 1

:run_script
echo ====================================
echo Running StartMasksDetection.py from: %SCRIPT_PATH%
echo ====================================

REM Create necessary output directories
if not exist "%BATCH_DIR%SavedMasks" (
    mkdir "%BATCH_DIR%SavedMasks"
    echo Created SavedMasks directory: %BATCH_DIR%SavedMasks
)

if not exist "%BATCH_DIR%images" (
    mkdir "%BATCH_DIR%images"
    echo Created images directory: %BATCH_DIR%images
    echo.
    echo *** IMPORTANT ***
    echo Please place your test images in the 'images' folder!
    echo Supported formats: PNG, JPG, JPEG, BMP, TIFF
    echo.
)

if not exist "%BATCH_DIR%logs" (
    mkdir "%BATCH_DIR%logs"
    echo Created logs directory: %BATCH_DIR%logs
)

REM Check for required files
echo.
echo Checking for required files...

if not exist "%BATCH_DIR%mask_rcnn_food_0029.h5" (
    echo WARNING: Model weights file 'mask_rcnn_food_0029.h5' not found!
    echo Please ensure this file is in: %BATCH_DIR%
    echo.
)

if not exist "%BATCH_DIR%food.py" (
    echo WARNING: Configuration file 'food.py' not found!
    echo Please ensure this file is in: %BATCH_DIR%
    echo.
)

REM Count images in the images directory
SET "IMAGE_COUNT=0"
for %%f in ("%BATCH_DIR%images\*.png" "%BATCH_DIR%images\*.jpg" "%BATCH_DIR%images\*.jpeg" "%BATCH_DIR%images\*.bmp" "%BATCH_DIR%images\*.tiff") do (
    SET /A IMAGE_COUNT+=1
)

if %IMAGE_COUNT% equ 0 (
    echo WARNING: No images found in the 'images' directory!
    echo Please add some test images before running.
    echo.
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
python -c "import tensorflow as tf; print('TensorFlow:', tf.__version__)"
python -c "import keras; print('Keras:', keras.__version__)"
python -c "import cv2; print('OpenCV:', cv2.__version__)"

REM Check GPU availability
echo.
python -c "import tensorflow as tf; gpu = tf.test.is_gpu_available(); print('GPU Available:', gpu); print('GPU Devices:', tf.config.experimental.list_physical_devices('GPU') if hasattr(tf.config, 'experimental') else [])" 2>nul

echo.
echo ====================================
echo Starting detection process...
echo ====================================

REM Record start time
SET "START_TIME=%time%"

REM Run the Python script
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
    echo 1. Check if mask_rcnn_food_0029.h5 file exists in: %BATCH_DIR%
    echo 2. Check if images folder contains test images
    echo 3. Check if food.py configuration file exists
    echo 4. Check if mrcnn module is accessible
    echo 5. Review the error messages above for specific issues
    echo.
    echo For detailed error information, check:
    echo - Python error messages above
) else (
    echo.
    echo SUCCESS: Script executed successfully!
    echo.
    echo Results have been saved to:
    echo - Masks: %BATCH_DIR%SavedMasks\
    echo - Detection results: %BATCH_DIR%SavedMasks\detection_results.json
    echo - Visualizations: %BATCH_DIR%SavedMasks\detection_result_*.png
    echo.
    
    REM Count output files
    SET "MASK_COUNT=0"
    for %%f in ("%BATCH_DIR%SavedMasks\*.jpg") do SET /A MASK_COUNT+=1
    
    echo Output summary:
    echo - Images processed: %IMAGE_COUNT%
    echo - Masks generated: %MASK_COUNT%
)

echo.
echo ====================================
echo Process finished. Press any key to exit.
echo ====================================
pause >nul

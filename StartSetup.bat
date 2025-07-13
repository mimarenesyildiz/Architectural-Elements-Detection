@echo off
SETLOCAL EnableDelayedExpansion
SET "ENV_NAME=MaskRCNN_Detection"
SET "PYTHON_VERSION=3.6"
SET "LOG_FILE=%~dp0setup_log.txt"
REM Script path will be determined automatically

echo ====================================== > "%LOG_FILE%"
echo MaskRCNN Environment Setup Log >> "%LOG_FILE%"
echo Started at: %date% %time% >> "%LOG_FILE%"
echo ====================================== >> "%LOG_FILE%"

echo ====================================
echo MaskRCNN Fixed Environment Setup
echo ====================================
echo [Setup log will be saved to: %LOG_FILE%]
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
echo Conda was not found in any common locations.
echo Please ensure Anaconda or Miniconda is installed.
echo.
echo You can download Anaconda from: https://www.anaconda.com/products/distribution
echo Or Miniconda from: https://docs.conda.io/en/latest/miniconda.html
echo.
echo Error: Conda not found >> "%LOG_FILE%"
pause
exit /b 1

:conda_found
echo ====================================
echo Using Conda installation at: %CONDA_PATH%
echo ====================================
echo Conda found at: %CONDA_PATH% >> "%LOG_FILE%"

REM Check if environment already exists
echo Checking if %ENV_NAME% environment exists...
CALL "%CONDA_PATH%\condabin\conda.bat" env list | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo Environment %ENV_NAME% already exists!
    echo Using existing environment...
    echo.
    CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%

    REM >>> BURAYA pip installları EKLE! <<<
    echo Installing/Updating required packages in existing environment...
    pip install numpy==1.16.4
    pip install h5py==2.8.0
    pip install tensorflow==1.10.0
    pip install keras==2.0.8
    pip install scikit-image==0.16.2
    pip install opencv-python==4.1.0.25
    pip install imgaug==0.2.9
    pip install pillow==6.2.1
    pip install matplotlib==3.0.3
    pip install scipy==1.2.3
    pip install IPython==7.2.0
    pip install pycocotools-windows
    pip install numba==0.48.0
    pip install tqdm==4.45.0
    pip install psutil==5.7.0

    goto :activate_and_run
)


echo ====================================
echo Creating NEW %ENV_NAME% environment with Python %PYTHON_VERSION%
echo ====================================

REM Create conda environment with Python 3.6
CALL "%CONDA_PATH%\condabin\conda.bat" create -n %ENV_NAME% python=%PYTHON_VERSION% -y >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to create conda environment
    echo Check the log file for details: %LOG_FILE%
    pause
    exit /b 1
)

echo Environment created successfully!

echo ====================================
echo Installing COMPATIBLE packages...
echo ====================================

REM Activate environment and install packages
CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%

echo Installing specific compatible versions for MaskRCNN...
echo This may take several minutes. Please be patient...
echo.

REM Function to install package with retry
:install_package
SET "PACKAGE=%~1"
SET "RETRY_COUNT=0"

:retry_install
echo Installing %PACKAGE%...
pip install %PACKAGE% --no-cache-dir >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    SET /A RETRY_COUNT+=1
    if !RETRY_COUNT! lss 3 (
        echo Retry !RETRY_COUNT! for %PACKAGE%...
        timeout /t 2 /nobreak >nul
        goto :retry_install
    ) else (
        echo WARNING: Failed to install %PACKAGE% after 3 attempts
        echo Failed to install %PACKAGE% >> "%LOG_FILE%"
    )
) else (
    echo Successfully installed %PACKAGE%
)
goto :eof

REM Install exact compatible versions in correct order with optimization flags
echo [1/14] Installing NumPy 1.16.4...
call :install_package "numpy==1.16.4"

echo [2/14] Installing h5py 2.8.0...
call :install_package "h5py==2.8.0"

echo [3/14] Installing TensorFlow 1.10.0...
echo Note: This is a large package and may take several minutes...
call :install_package "tensorflow==1.10.0"

REM Check for GPU support
echo.
echo Checking for NVIDIA GPU...
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    echo NVIDIA GPU detected! Installing GPU support...
    echo [3a/14] Installing TensorFlow GPU 1.10.0...
    call :install_package "tensorflow-gpu==1.10.0"
    echo GPU support installed.
) else (
    echo No NVIDIA GPU detected. Using CPU version.
)

echo [4/14] Installing Keras 2.0.8...
call :install_package "keras==2.0.8"

echo [5/14] Installing scikit-image 0.16.2...
call :install_package "scikit-image==0.16.2"

echo [6/14] Installing OpenCV-Python 4.1.0.25...
call :install_package "opencv-python==4.1.0.25"

echo [7/14] Installing imgaug 0.2.9...
call :install_package "imgaug==0.2.9"

echo [8/14] Installing Pillow 6.2.1...
call :install_package "pillow==6.2.1"

echo [9/14] Installing matplotlib 3.0.3...
call :install_package "matplotlib==3.0.3"

echo [10/14] Installing scipy 1.2.3...
call :install_package "scipy==1.2.3"

echo [11/14] Installing IPython 7.2.0...
call :install_package "IPython==7.2.0"

echo [12/14] Installing pycocotools for Windows...
call :install_package "pycocotools-windows"

echo [13/14] Installing performance optimization packages...
call :install_package "numba==0.48.0"

echo [14/14] Installing monitoring tools...
call :install_package "tqdm==4.45.0"
call :install_package "psutil==5.7.0"

echo.
echo ====================================
echo Package installation complete!
echo ====================================

REM Verify critical packages
echo.
echo Verifying installation...
python -c "import tensorflow as tf; print('TensorFlow version:', tf.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo ERROR: TensorFlow installation verification failed!
    echo Please check the log file: %LOG_FILE%
    pause
    exit /b 1
)

python -c "import keras; print('Keras version:', keras.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Keras installation verification failed!
    echo Please check the log file: %LOG_FILE%
    pause
    exit /b 1
)

echo Installation verified successfully!

:activate_and_run
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
    echo - Setup log: %LOG_FILE%
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

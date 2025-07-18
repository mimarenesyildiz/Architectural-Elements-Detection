@echo off
SETLOCAL EnableDelayedExpansion
SET "ENV_NAME=MaskRCNN_Detection"
SET "PYTHON_VERSION=3.6"
SET "LOG_FILE=%~dp0setup_log.txt"

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

    goto :verify_installation
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

:verify_installation
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

echo.
echo ====================================
echo Environment setup completed successfully!
echo ====================================
echo.
echo Environment name: %ENV_NAME%
echo Python version: %PYTHON_VERSION%
echo.
echo Installed packages:
echo - TensorFlow 1.10.0
echo - Keras 2.0.8
echo - NumPy 1.16.4
echo - OpenCV 4.1.0.25
echo - And other compatible versions
echo.
echo To activate this environment manually:
echo   conda activate %ENV_NAME%
echo.
echo To run the detection:
echo   Run startdetection.bat
echo.
echo Setup completed at: %date% %time% >> "%LOG_FILE%"

pause

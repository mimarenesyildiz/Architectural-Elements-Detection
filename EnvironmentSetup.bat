@echo off
SETLOCAL EnableDelayedExpansion

REM ============================================================
REM MaskRCNN Environment Setup - Version 2.3
REM Exact versions as specified
REM ============================================================

SET "ENV_NAME=MaskRCNN_Detection"
SET "PYTHON_VERSION=3.6"
SET "SCRIPT_DIR=%~dp0"
SET "LOG_FILE=%SCRIPT_DIR%setup_log.txt"
SET "CONDA_CONFIG=%SCRIPT_DIR%.conda_path"

echo ====================================================== > "%LOG_FILE%"
echo MaskRCNN Environment Setup Log >> "%LOG_FILE%"
echo Started at: %date% %time% >> "%LOG_FILE%"
echo ====================================================== >> "%LOG_FILE%"

echo.
echo ========================================================
echo   MaskRCNN Environment Setup v2.3
echo ========================================================
echo.
echo   Target Configuration:
echo     Python 3.6
echo     TensorFlow 1.10.0
echo     Keras 2.0.8
echo     NumPy 1.16.4
echo.
echo   [Log: %LOG_FILE%]
echo.

REM ============================================================
REM STEP 1: Find Conda
REM ============================================================

SET "CONDA_PATH="

echo [Step 1/5] Finding Conda...

if exist "%CONDA_CONFIG%" (
    set /p CONDA_PATH=<"%CONDA_CONFIG%"
    if exist "!CONDA_PATH!\condabin\conda.bat" (
        echo   [OK] Found: !CONDA_PATH!
        goto :conda_found
    )
    SET "CONDA_PATH="
)

if exist "%SCRIPT_DIR%miniconda3\condabin\conda.bat" (
    SET "CONDA_PATH=%SCRIPT_DIR%miniconda3"
    echo   [OK] Found portable: !CONDA_PATH!
    echo !CONDA_PATH!> "%CONDA_CONFIG%"
    goto :conda_found
)

for %%P in (
    "%USERPROFILE%\Miniconda3"
    "%USERPROFILE%\miniconda3"
    "%USERPROFILE%\Anaconda3"
    "%USERPROFILE%\anaconda3"
    "%LOCALAPPDATA%\anaconda3"
    "%LOCALAPPDATA%\miniconda3"
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

echo   [ERROR] Conda not found!
pause
exit /b 1

:conda_found
echo.

REM ============================================================
REM STEP 2: Setup Environment
REM ============================================================

echo [Step 2/5] Setting up environment...

SET "PATH=%CONDA_PATH%\condabin;%CONDA_PATH%\Scripts;%CONDA_PATH%;%SystemRoot%\system32;%SystemRoot%"

CALL "%CONDA_PATH%\condabin\conda.bat" activate base >nul 2>&1

REM Check existing environment
CALL "%CONDA_PATH%\condabin\conda.bat" env list | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   Environment exists. Removing for clean install...
    CALL "%CONDA_PATH%\condabin\conda.bat" env remove -n %ENV_NAME% -y >> "%LOG_FILE%" 2>&1
    echo   [OK] Old environment removed
)

echo   Creating %ENV_NAME% with Python %PYTHON_VERSION%...
CALL "%CONDA_PATH%\condabin\conda.bat" create -n %ENV_NAME% python=%PYTHON_VERSION% -y >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Failed to create environment
    pause
    exit /b 1
)

echo   [OK] Environment created
echo.

CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%

REM ============================================================
REM STEP 3: Install Packages
REM Order is critical to avoid dependency conflicts
REM ============================================================

echo [Step 3/5] Installing packages...
echo.
echo   Installation order optimized for compatibility.
echo   This will take 10-15 minutes.
echo.

REM ----------------------------------------
REM PHASE 1: TensorFlow first (sets up dependencies)
REM ----------------------------------------
echo   --- Phase 1: TensorFlow (installs first) ---
echo.

echo   [1/16] Installing TensorFlow==1.10.0
pip install tensorflow==1.10.0 >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 echo   [!] TensorFlow had warnings

REM Check for GPU
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    echo   [2/16] Installing TensorFlow-GPU==1.10.0 (GPU detected)
    pip install tensorflow-gpu==1.10.0 >> "%LOG_FILE%" 2>&1
) else (
    echo   [2/16] Skipping GPU (no NVIDIA GPU detected)
)

echo   [3/16] Installing Keras==2.0.8
pip install keras==2.0.8 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 2: Core scientific packages
REM ----------------------------------------
echo.
echo   --- Phase 2: Core packages ---
echo.

echo   [4/16] Installing H5py==2.8.0
pip install h5py==2.8.0 >> "%LOG_FILE%" 2>&1

echo   [5/16] Installing SciPy==1.2.3
pip install scipy==1.2.3 >> "%LOG_FILE%" 2>&1

echo   [6/16] Installing Pillow==6.2.1
pip install pillow==6.2.1 >> "%LOG_FILE%" 2>&1

echo   [7/16] Installing Matplotlib==3.0.3
pip install matplotlib==3.0.3 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 3: Image processing
REM ----------------------------------------
echo.
echo   --- Phase 3: Image processing ---
echo.

echo   [8/16] Installing OpenCV-Python==4.1.0.25
pip install opencv-python==4.1.0.25 >> "%LOG_FILE%" 2>&1

echo   [9/16] Installing Scikit-image==0.16.2
pip install scikit-image==0.16.2 >> "%LOG_FILE%" 2>&1

echo   [10/16] Installing Imgaug==0.2.9
pip install imgaug==0.2.9 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 4: Utilities
REM ----------------------------------------
echo.
echo   --- Phase 4: Utilities ---
echo.

echo   [11/16] Installing IPython==7.2.0
pip install IPython==7.2.0 >> "%LOG_FILE%" 2>&1

echo   [12/16] Installing Pycocotools-windows
pip install pycocotools-windows >> "%LOG_FILE%" 2>&1

echo   [13/16] Installing Numba==0.48.0
pip install numba==0.48.0 >> "%LOG_FILE%" 2>&1

echo   [14/16] Installing Tqdm==4.45.0
pip install tqdm==4.45.0 >> "%LOG_FILE%" 2>&1

echo   [15/16] Installing Psutil==5.7.0
pip install psutil==5.7.0 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 5: Force correct NumPy version LAST
REM This overrides any version pip installed
REM ----------------------------------------
echo.
echo   --- Phase 5: Locking NumPy version ---
echo.

echo   [16/16] Forcing NumPy==1.16.4
pip install numpy==1.16.4 --force-reinstall --no-deps >> "%LOG_FILE%" 2>&1

echo.
echo   [OK] Package installation complete

REM ============================================================
REM STEP 4: Verify Installation
REM ============================================================

echo.
echo [Step 4/5] Verifying installation...
echo.

SET "VERIFY_FAILED=0"

REM Check NumPy
python -c "import numpy; print('   NumPy:', numpy.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] NumPy failed
    SET "VERIFY_FAILED=1"
)

REM Check TensorFlow
python -c "import tensorflow as tf; print('   TensorFlow:', tf.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] TensorFlow failed
    SET "VERIFY_FAILED=1"
)

REM Check Keras
python -c "import keras; print('   Keras:', keras.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] Keras failed
    SET "VERIFY_FAILED=1"
)

REM Check other packages
python -c "import cv2; print('   OpenCV:', cv2.__version__)" 2>nul
python -c "import scipy; print('   SciPy:', scipy.__version__)" 2>nul
python -c "import skimage; print('   Scikit-image:', skimage.__version__)" 2>nul
python -c "import imgaug; print('   Imgaug:', imgaug.__version__)" 2>nul
python -c "import h5py; print('   H5py:', h5py.__version__)" 2>nul

if %VERIFY_FAILED%==1 (
    echo.
    echo   [!] Some packages failed verification.
    echo   Attempting automatic fix...
    goto :attempt_fix
)

echo.
echo   [OK] All packages verified!
goto :create_helpers

:attempt_fix
echo.
echo   Reinstalling TensorFlow with correct numpy...
pip uninstall tensorflow -y >nul 2>&1
pip install numpy==1.16.4 --force-reinstall --no-deps >nul 2>&1
pip install tensorflow==1.10.0 --no-deps >nul 2>&1

python -c "import tensorflow; print('   TensorFlow fix:', tensorflow.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] Fix failed. See troubleshooting below.
    goto :show_troubleshoot
)
echo   [OK] Fix successful!

REM ============================================================
REM STEP 5: Create Helper Scripts
REM ============================================================

:create_helpers
echo.
echo [Step 5/5] Creating helper scripts...

REM Fix script
(
echo @echo off
echo echo Fixing NumPy for TensorFlow compatibility...
echo CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%
echo pip install numpy==1.16.4 --force-reinstall --no-deps
echo python -c "import tensorflow; print('TensorFlow:', tensorflow.__version__)"
echo pause
) > "%SCRIPT_DIR%fix_numpy.bat"
echo   [OK] Created fix_numpy.bat

REM Quick test script
(
echo @echo off
echo CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%
echo echo.
echo echo === Package Versions ===
echo python -c "import numpy; print('NumPy:', numpy.__version__)"
echo python -c "import tensorflow; print('TensorFlow:', tensorflow.__version__)"
echo python -c "import keras; print('Keras:', keras.__version__)"
echo python -c "import cv2; print('OpenCV:', cv2.__version__)"
echo python -c "import scipy; print('SciPy:', scipy.__version__)"
echo echo.
echo pause
) > "%SCRIPT_DIR%check_versions.bat"
echo   [OK] Created check_versions.bat

echo.
echo ========================================================
echo   SETUP COMPLETE!
echo ========================================================
echo.
echo   Environment: %ENV_NAME%
echo   Location: %CONDA_PATH%\envs\%ENV_NAME%
echo.
echo   Installed Packages:
echo     - Python 3.6
echo     - TensorFlow 1.10.0
echo     - Keras 2.0.8
echo     - NumPy 1.16.4
echo     - H5py 2.8.0
echo     - Scikit-image 0.16.2
echo     - OpenCV 4.1.0.25
echo     - Imgaug 0.2.9
echo     - Pillow 6.2.1
echo     - Matplotlib 3.0.3
echo     - SciPy 1.2.3
echo     - IPython 7.2.0
echo     - Pycocotools-windows
echo     - Numba 0.48.0
echo     - Tqdm 4.45.0
echo     - Psutil 5.7.0
echo.
echo   To run detection:
echo     %SCRIPT_DIR%startdetection.bat
echo.
echo   To check versions:
echo     %SCRIPT_DIR%check_versions.bat
echo.
echo   If numpy errors occur:
echo     %SCRIPT_DIR%fix_numpy.bat
echo.
echo ========================================================
echo Setup completed at: %date% %time% >> "%LOG_FILE%"
pause
exit /b 0

:show_troubleshoot
echo.
echo ========================================================
echo   TROUBLESHOOTING
echo ========================================================
echo.
echo   Manual fix steps:
echo.
echo   1. Open Anaconda Prompt
echo   2. conda activate %ENV_NAME%
echo   3. pip uninstall numpy tensorflow tensorflow-gpu -y
echo   4. pip install numpy==1.16.4
echo   5. pip install tensorflow==1.10.0 --no-deps
echo   6. python -c "import tensorflow"
echo.
echo   If still failing, delete and recreate:
echo   conda env remove -n %ENV_NAME% -y
echo   Then run this script again.
echo.
echo ========================================================
pause
exit /b 1

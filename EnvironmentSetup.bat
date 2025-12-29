@echo off
SETLOCAL EnableDelayedExpansion

REM ============================================================
REM MaskRCNN Environment Setup - Version 2.4
REM Fixed: Clears inherited Python environment variables
REM        that interfere with conda when run from Rhino/GH
REM ============================================================

SET "ENV_NAME=MaskRCNN_Detection"
SET "PYTHON_VERSION=3.6"
SET "SCRIPT_DIR=%~dp0"
SET "LOG_FILE=%SCRIPT_DIR%setup_log.txt"
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

echo ====================================================== > "%LOG_FILE%"
echo MaskRCNN Environment Setup Log >> "%LOG_FILE%"
echo Started at: %date% %time% >> "%LOG_FILE%"
echo Cleared Python env vars for clean conda execution >> "%LOG_FILE%"
echo ====================================================== >> "%LOG_FILE%"

echo.
echo ========================================================
echo   MaskRCNN Environment Setup v2.4
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
    REM Remove any trailing whitespace/newlines
    SET "CONDA_PATH=!CONDA_PATH: =!"
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
echo   Please install Miniconda or Anaconda first.
pause
exit /b 1

:conda_found
echo.

REM ============================================================
REM STEP 2: Setup Environment
REM ============================================================

echo [Step 2/5] Setting up environment...

REM Set minimal clean PATH - only conda and system essentials
SET "PATH=%CONDA_PATH%\condabin;%CONDA_PATH%\Library\bin;%CONDA_PATH%\Scripts;%CONDA_PATH%;%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"

REM Debug: Show we're using correct conda
echo   Using conda at: %CONDA_PATH%\condabin\conda.bat >> "%LOG_FILE%"

REM Activate base environment using full path
echo   Activating conda base...
CALL "%CONDA_PATH%\condabin\conda.bat" activate base
if %errorlevel% neq 0 (
    echo   [WARNING] Base activation returned error, continuing anyway...
    echo   Base activation error >> "%LOG_FILE%"
)

REM Check existing environment
echo   Checking for existing environment...
CALL "%CONDA_PATH%\condabin\conda.bat" env list 2>> "%LOG_FILE%" | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   Environment exists. Removing for clean install...
    CALL "%CONDA_PATH%\condabin\conda.bat" env remove -n %ENV_NAME% -y >> "%LOG_FILE%" 2>&1
    if %errorlevel% equ 0 (
        echo   [OK] Old environment removed
    ) else (
        echo   [WARNING] Could not remove old environment, will try to recreate
    )
)

echo   Creating %ENV_NAME% with Python %PYTHON_VERSION%...
CALL "%CONDA_PATH%\condabin\conda.bat" create -n %ENV_NAME% python=%PYTHON_VERSION% -y >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Failed to create environment
    echo   Check the log file for details: %LOG_FILE%
    echo.
    echo   Possible causes:
    echo     - Network connection issues
    echo     - Corrupted conda installation
    echo     - Disk space issues
    echo.
    echo   Try running this command manually:
    echo     "%CONDA_PATH%\condabin\conda.bat" create -n %ENV_NAME% python=%PYTHON_VERSION% -y
    pause
    exit /b 1
)

echo   [OK] Environment created
echo.

echo   Activating %ENV_NAME%...
CALL "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%
if %errorlevel% neq 0 (
    echo   [WARNING] Activation returned error, attempting alternative method...
    REM Alternative: directly set paths for the new environment
    SET "PATH=%CONDA_PATH%\envs\%ENV_NAME%;%CONDA_PATH%\envs\%ENV_NAME%\Scripts;%CONDA_PATH%\envs\%ENV_NAME%\Library\bin;%PATH%"
)

REM ============================================================
REM STEP 3: Install Packages
REM Order is critical to avoid dependency conflicts
REM ============================================================

echo [Step 3/5] Installing packages...
echo.
echo   Installation order optimized for compatibility.
echo   This will take 10-15 minutes.
echo.

REM Get the pip from our environment explicitly
SET "PIP_CMD=%CONDA_PATH%\envs\%ENV_NAME%\Scripts\pip.exe"
if not exist "%PIP_CMD%" (
    SET "PIP_CMD=pip"
    echo   [WARNING] Using system pip
)

REM ----------------------------------------
REM PHASE 1: TensorFlow first (sets up dependencies)
REM ----------------------------------------
echo   --- Phase 1: TensorFlow (installs first) ---
echo.

echo   [1/16] Installing TensorFlow==1.10.0
"%PIP_CMD%" install tensorflow==1.10.0 >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 echo   [!] TensorFlow had warnings

REM Check for GPU
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    echo   [2/16] Installing TensorFlow-GPU==1.10.0 (GPU detected)
    "%PIP_CMD%" install tensorflow-gpu==1.10.0 >> "%LOG_FILE%" 2>&1
) else (
    echo   [2/16] Skipping GPU (no NVIDIA GPU detected)
)

echo   [3/16] Installing Keras==2.0.8
"%PIP_CMD%" install keras==2.0.8 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 2: Core scientific packages
REM ----------------------------------------
echo.
echo   --- Phase 2: Core packages ---
echo.

echo   [4/16] Installing H5py==2.8.0
"%PIP_CMD%" install h5py==2.8.0 >> "%LOG_FILE%" 2>&1

echo   [5/16] Installing SciPy==1.2.3
"%PIP_CMD%" install scipy==1.2.3 >> "%LOG_FILE%" 2>&1

echo   [6/16] Installing Pillow==6.2.1
"%PIP_CMD%" install pillow==6.2.1 >> "%LOG_FILE%" 2>&1

echo   [7/16] Installing Matplotlib==3.0.3
"%PIP_CMD%" install matplotlib==3.0.3 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 3: Image processing
REM ----------------------------------------
echo.
echo   --- Phase 3: Image processing ---
echo.

echo   [8/16] Installing OpenCV-Python==4.1.0.25
"%PIP_CMD%" install opencv-python==4.1.0.25 >> "%LOG_FILE%" 2>&1

echo   [9/16] Installing Scikit-image==0.16.2
"%PIP_CMD%" install scikit-image==0.16.2 >> "%LOG_FILE%" 2>&1

echo   [10/16] Installing Imgaug==0.2.9
"%PIP_CMD%" install imgaug==0.2.9 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 4: Utilities
REM ----------------------------------------
echo.
echo   --- Phase 4: Utilities ---
echo.

echo   [11/16] Installing IPython==7.2.0
"%PIP_CMD%" install IPython==7.2.0 >> "%LOG_FILE%" 2>&1

echo   [12/16] Installing Pycocotools-windows
"%PIP_CMD%" install pycocotools-windows >> "%LOG_FILE%" 2>&1

echo   [13/16] Installing Numba==0.48.0
"%PIP_CMD%" install numba==0.48.0 >> "%LOG_FILE%" 2>&1

echo   [14/16] Installing Tqdm==4.45.0
"%PIP_CMD%" install tqdm==4.45.0 >> "%LOG_FILE%" 2>&1

echo   [15/16] Installing Psutil==5.7.0
"%PIP_CMD%" install psutil==5.7.0 >> "%LOG_FILE%" 2>&1

REM ----------------------------------------
REM PHASE 5: Force correct NumPy version LAST
REM This overrides any version pip installed
REM ----------------------------------------
echo.
echo   --- Phase 5: Locking NumPy version ---
echo.

echo   [16/16] Forcing NumPy==1.16.4
"%PIP_CMD%" install numpy==1.16.4 --force-reinstall --no-deps >> "%LOG_FILE%" 2>&1

echo.
echo   [OK] Package installation complete

REM ============================================================
REM STEP 4: Verify Installation
REM ============================================================

echo.
echo [Step 4/5] Verifying installation...
echo.

SET "VERIFY_FAILED=0"
SET "PYTHON_CMD=%CONDA_PATH%\envs\%ENV_NAME%\python.exe"

REM Check NumPy
"%PYTHON_CMD%" -c "import numpy; print('   NumPy:', numpy.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] NumPy failed
    SET "VERIFY_FAILED=1"
)

REM Check TensorFlow
"%PYTHON_CMD%" -c "import tensorflow as tf; print('   TensorFlow:', tf.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] TensorFlow failed
    SET "VERIFY_FAILED=1"
)

REM Check Keras
"%PYTHON_CMD%" -c "import keras; print('   Keras:', keras.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] Keras failed
    SET "VERIFY_FAILED=1"
)

REM Check other packages
"%PYTHON_CMD%" -c "import cv2; print('   OpenCV:', cv2.__version__)" 2>nul
"%PYTHON_CMD%" -c "import scipy; print('   SciPy:', scipy.__version__)" 2>nul
"%PYTHON_CMD%" -c "import skimage; print('   Scikit-image:', skimage.__version__)" 2>nul
"%PYTHON_CMD%" -c "import imgaug; print('   Imgaug:', imgaug.__version__)" 2>nul
"%PYTHON_CMD%" -c "import h5py; print('   H5py:', h5py.__version__)" 2>nul

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
"%PIP_CMD%" uninstall tensorflow -y >nul 2>&1
"%PIP_CMD%" install numpy==1.16.4 --force-reinstall --no-deps >nul 2>&1
"%PIP_CMD%" install tensorflow==1.10.0 --no-deps >nul 2>&1

"%PYTHON_CMD%" -c "import tensorflow; print('   TensorFlow fix:', tensorflow.__version__)" 2>nul
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

REM Fix script - using escaped CONDA_PATH for delayed expansion in output
(
echo @echo off
echo SETLOCAL
echo REM Clear any interfering environment variables
echo SET "PYTHONPATH="
echo SET "PYTHONHOME="
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
echo SETLOCAL
echo REM Clear any interfering environment variables
echo SET "PYTHONPATH="
echo SET "PYTHONHOME="
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
echo   1. Open a NEW Command Prompt (not Anaconda Prompt)
echo   2. Run: SET PYTHONPATH=
echo   3. Run: SET PYTHONHOME=
echo   4. Run: "%CONDA_PATH%\condabin\conda.bat" activate %ENV_NAME%
echo   5. Run: pip uninstall numpy tensorflow tensorflow-gpu -y
echo   6. Run: pip install numpy==1.16.4
echo   7. Run: pip install tensorflow==1.10.0 --no-deps
echo   8. Run: python -c "import tensorflow"
echo.
echo   If still failing, delete and recreate:
echo   "%CONDA_PATH%\condabin\conda.bat" env remove -n %ENV_NAME% -y
echo   Then run this script again.
echo.
echo ========================================================
pause
exit /b 1

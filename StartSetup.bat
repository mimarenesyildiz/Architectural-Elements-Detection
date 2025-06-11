@echo off
echo ========================================
echo MaskRCNN Architectural Elements Detection
echo ========================================
echo.

REM Get the directory where this bat file is located
SET "SCRIPT_DIR=%~dp0"
echo Script directory: %SCRIPT_DIR%

REM Set the virtual environment path (relative to script directory)
SET "VENV_PATH=%SCRIPT_DIR%venv"
echo Virtual environment path: %VENV_PATH%

REM Check if virtual environment exists
IF NOT EXIST "%VENV_PATH%\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Expected location: %VENV_PATH%
    echo Please make sure the virtual environment is properly installed.
    echo.
    pause
    exit /b 1
)

REM Check if StartMasksDetection.py exists
IF NOT EXIST "%SCRIPT_DIR%StartMasksDetection.py" (
    echo ERROR: StartMasksDetection.py not found!
    echo Expected location: %SCRIPT_DIR%StartMasksDetection.py
    echo Please make sure the Python script is in the same directory as this bat file.
    echo.
    pause
    exit /b 1
)

echo.
echo Activating virtual environment...
CALL "%VENV_PATH%\Scripts\activate.bat"

REM Check if activation was successful
IF ERRORLEVEL 1 (
    echo ERROR: Failed to activate virtual environment!
    echo.
    pause
    exit /b 1
)

echo Virtual environment activated successfully!
echo.

echo Checking Python and required packages...
python --version
echo.

echo Starting MaskRCNN detection...
echo Running: python "%SCRIPT_DIR%StartMasksDetection.py"
echo.

REM Change to script directory and run the Python script
cd /d "%SCRIPT_DIR%"
python StartMasksDetection.py

REM Check if Python script ran successfully
IF ERRORLEVEL 1 (
    echo.
    echo ERROR: Python script execution failed!
    echo Please check the error messages above.
) ELSE (
    echo.
    echo ========================================
    echo MaskRCNN detection completed successfully!
    echo ========================================
)

echo.
echo Deactivating virtual environment...
deactivate

echo.
pause
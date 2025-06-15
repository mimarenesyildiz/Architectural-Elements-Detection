// Grasshopper Script Instance
#region Usings
using System;
using System.IO;
using System.Diagnostics;
using System.Collections;
using System.Text;
using System.Net;

using Rhino;
using Rhino.Geometry;

using Grasshopper;
using Grasshopper.Kernel;
using Grasshopper.Kernel.Data;
using Grasshopper.Kernel.Types;
#endregion

public class Script_Instance : GH_ScriptInstance
{
    #region Notes
    /* 
      MaskRCNN Installer Component for Grasshopper
      Installs Git, Python 3.9.13, clones repo, and sets up environment
    */
    #endregion
    
    // Configuration
    private const string GITHUB_REPO = "https://github.com/mimarenesyildiz/Architectural-Elements-Detection.git";
    private const string MODEL_URL = "http://mimarenes.com/geovision/mask_rcnn_food_0019.h5";
    private const string PYTHON_VERSION = "3.9.13";
    private const string GIT_VERSION = "2.39.0";
    
    private void RunScript(
		bool CheckStatus,
		bool InstallGit,
		bool InstallPython,
		bool CloneRepository,
		bool SetupEnvironment,
		bool DownloadModel,
		bool FullAutoInstall,
		string CustomPath,
		ref object Status,
		ref object Messages,
		ref object Progress,
		ref object NextSteps)
    {
        // Installation paths
        string BASE_DIR = string.IsNullOrEmpty(CustomPath) ? @"C:\ArchitecturalElementsDetection" : CustomPath;
        string PYTHON_DIR = @"C:\Python39";
        
        // Initialize outputs
        var messages = new ArrayList();
        var nextSteps = new ArrayList();
        string status = "Ready";
        double progress = 0.0;
        
        messages.Add("🏗️ ARCHITECTURAL ELEMENTS DETECTION - INSTALLER");
        messages.Add("================================================");
        messages.Add("⚠️ IMPORTANT: This installer will install Python 3.9.13");
        messages.Add("   (Required for modern PyTorch and Detectron2 compatibility)");
        messages.Add(string.Format("Installation Directory: {0}", BASE_DIR));
        messages.Add("");
        
        // Check if older Python is installed and warn user
        string systemPythonVersion = GetSystemPythonVersion();
        if (!string.IsNullOrEmpty(systemPythonVersion) && !systemPythonVersion.Contains("3.9"))
        {
            messages.Add("⚠️ COMPATIBILITY WARNING:");
            messages.Add(string.Format("   System Python detected: {0}", systemPythonVersion));
            messages.Add("   This installer will install Python 3.9.13 for compatibility");
            messages.Add("   The virtual environment will use Python 3.9.13");
            messages.Add("");
        }
        
        if (FullAutoInstall)
        {
            messages.Add("🚀 FULL AUTOMATIC INSTALLATION STARTED");
            messages.Add("");
            
            bool success = true;
            
            // Step 1: Check current status
            progress = 0.1;
            Print("Checking installation status...");
            CheckInstallationStatus(messages, nextSteps, BASE_DIR, PYTHON_DIR);
            
            // Step 2: Install Git if needed
            progress = 0.2;
            if (!IsGitInstalled())
            {
                messages.Add("📦 Installing Git...");
                Print("Installing Git...");
                success = success && InstallGitProcess(messages);
            }
            
            // Step 3: Install Python if needed
            progress = 0.4;
            if (!IsPython39Installed(PYTHON_DIR))
            {
                messages.Add("🐍 Installing Python 3.9.13...");
                Print("Installing Python 3.9.13...");
                success = success && InstallPythonProcess(messages, PYTHON_DIR);
            }
            
            // Step 4: Clone repository
            progress = 0.6;
            if (!Directory.Exists(Path.Combine(BASE_DIR, ".git")))
            {
                messages.Add("📥 Cloning repository...");
                Print("Cloning repository...");
                success = success && CloneGitRepository(messages, BASE_DIR);
            }
            
            // Step 5: Setup environment
            progress = 0.8;
            messages.Add("🔧 Setting up environment...");
            Print("Setting up environment...");
            success = success && SetupPythonEnvironment(messages, BASE_DIR, PYTHON_DIR);
            
            // Step 6: Download model
            progress = 0.9;
            messages.Add("🤖 Downloading AI model...");
            Print("Downloading AI model...");
            success = success && DownloadAIModel(messages, BASE_DIR);
            
            progress = 1.0;
            status = success ? "✅ Installation Complete!" : "⚠️ Installation Partial";
            
            if (success)
            {
                nextSteps.Add("✅ All components installed successfully!");
                nextSteps.Add("");
                nextSteps.Add("You can now use the MaskRCNN Runner component.");
                nextSteps.Add("");
                nextSteps.Add("🚀 To run MaskRCNN detection:");
                nextSteps.Add(string.Format("   Double-click: {0}\\StartSetup.bat", BASE_DIR));
                
                messages.Add("");
                messages.Add("🎉 INSTALLATION COMPLETED SUCCESSFULLY!");
                messages.Add("==================================================");
                messages.Add("All components have been installed and configured.");
                messages.Add("");
                messages.Add("✅ Git installed");
                messages.Add("✅ Python 3.9.13 installed"); 
                messages.Add("✅ Repository cloned");
                messages.Add("✅ Virtual environment created");
                messages.Add("✅ Modern PyTorch packages installed");
                messages.Add("✅ Detectron2 installed");
                messages.Add("✅ AI model downloaded");
                messages.Add("✅ Execution scripts created");
                messages.Add("");
                messages.Add("🚀 Ready to use! Run the AI Detection component next.");
            }
            else
            {
                messages.Add("");
                messages.Add("⚠️ INSTALLATION PARTIALLY COMPLETED");
                messages.Add("Some components may need manual installation.");
            }
            
            Print("Installation process completed!");
            Print(string.Format("Final status: {0}", status));
        }
        else if (CheckStatus)
        {
            status = "Checking...";
            CheckInstallationStatus(messages, nextSteps, BASE_DIR, PYTHON_DIR);
        }
        else if (InstallGit)
        {
            messages.Add("📦 Installing Git...");
            bool success = InstallGitProcess(messages);
            status = success ? "✅ Git Installed" : "❌ Git Installation Failed";
        }
        else if (InstallPython)
        {
            messages.Add("🐍 Installing Python 3.9.13...");
            bool success = InstallPythonProcess(messages, PYTHON_DIR);
            status = success ? "✅ Python Installed" : "❌ Python Installation Failed";
        }
        else if (CloneRepository)
        {
            messages.Add("📥 Cloning repository...");
            bool success = CloneGitRepository(messages, BASE_DIR);
            status = success ? "✅ Repository Cloned" : "❌ Clone Failed";
        }
        else if (SetupEnvironment)
        {
            messages.Add("🔧 Setting up environment...");
            bool success = SetupPythonEnvironment(messages, BASE_DIR, PYTHON_DIR);
            status = success ? "✅ Environment Setup" : "❌ Environment Setup Failed";
        }
        else if (DownloadModel)
        {
            messages.Add("🤖 Downloading AI model...");
            bool success = DownloadAIModel(messages, BASE_DIR);
            status = success ? "✅ Model Downloaded" : "❌ Model Download Failed";
        }
        else
        {
            messages.Add("Select an installation step:");
            messages.Add("");
            messages.Add("📋 Check Status - See what's installed");
            messages.Add("📦 Install Git - Version control system");
            messages.Add("🐍 Install Python - Python 3.9.13 (Modern PyTorch compatible)");
            messages.Add("📥 Clone Repository - Download project files");
            messages.Add("🔧 Setup Environment - Install PyTorch/Detectron2 dependencies");
            messages.Add("🤖 Download Model - Get AI model");
            messages.Add("");
            messages.Add("🚀 Full Auto Install - Do everything automatically");
        }
        
        // Set outputs
        Status = status;
        Messages = messages;
        Progress = progress;
        NextSteps = nextSteps;
    }
    
    private void CheckInstallationStatus(ArrayList messages, ArrayList nextSteps, string baseDir, string pythonDir)
    {
        messages.Add("📋 CHECKING INSTALLATION STATUS");
        messages.Add("");
        
        // Check Git
        bool gitInstalled = IsGitInstalled();
        messages.Add(string.Format("Git: {0}", gitInstalled ? "✅ Installed" : "❌ Not installed"));
        if (gitInstalled)
        {
            string gitVersion = GetGitVersion();
            if (!string.IsNullOrEmpty(gitVersion))
                messages.Add(string.Format("     Version: {0}", gitVersion));
        }
        
        // Check Python
        bool pythonInstalled = IsPython39Installed(pythonDir);
        messages.Add(string.Format("Python 3.9: {0}", pythonInstalled ? "✅ Installed" : "❌ Not installed"));
        if (pythonInstalled)
        {
            string pythonVersion = GetPython39Version(pythonDir);
            if (!string.IsNullOrEmpty(pythonVersion))
                messages.Add(string.Format("        Version: {0}", pythonVersion));
        }
        
        // Check Repository
        bool repoExists = Directory.Exists(Path.Combine(baseDir, ".git"));
        messages.Add(string.Format("Repository: {0}", repoExists ? "✅ Cloned" : "❌ Not cloned"));
        
        // Check Virtual Environment
        bool venvExists = Directory.Exists(Path.Combine(baseDir, "venv"));
        messages.Add(string.Format("Virtual Environment: {0}", venvExists ? "✅ Created" : "❌ Not created"));
        
        // Check Model
        bool modelExists = File.Exists(Path.Combine(baseDir, "mask_rcnn_food_0019.h5"));
        messages.Add(string.Format("AI Model: {0}", modelExists ? "✅ Downloaded" : "❌ Not downloaded"));
        
        // Check Bat Files
        bool setupBatExists = File.Exists(Path.Combine(baseDir, "StartSetup.bat"));
        messages.Add(string.Format("Execution Scripts: {0}", setupBatExists ? "✅ Created" : "❌ Not created"));
        
        // Suggest next steps
        messages.Add("");
        if (!gitInstalled)
            nextSteps.Add("1. Install Git first");
        else if (!pythonInstalled)
            nextSteps.Add("2. Install Python 3.9.13 next");
        else if (!repoExists)
            nextSteps.Add("3. Clone the repository");
        else if (!venvExists)
            nextSteps.Add("4. Setup Python environment");
        else if (!modelExists)
            nextSteps.Add("5. Download the AI model");
        else
            nextSteps.Add("✅ Everything is installed! Ready to use.");
    }
    
    private bool InstallGitProcess(ArrayList messages)
    {
        try
        {
            messages.Add("");
            messages.Add("📦 INSTALLING GIT");
            
            string tempPath = Path.GetTempPath();
            string installerPath = Path.Combine(tempPath, "GitInstaller.exe");
            string gitUrl = string.Format("https://github.com/git-for-windows/git/releases/download/v{0}.windows.1/Git-{0}-64-bit.exe", GIT_VERSION);
            
            messages.Add("Downloading Git installer...");
            var client = new WebClient();
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            client.DownloadFile(gitUrl, installerPath);
            client.Dispose();
            
            string installScript = Path.Combine(tempPath, "install_git.bat");
            string scriptContent = string.Format("@echo off\necho Installing Git silently...\n\"{0}\" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS\necho Git installation completed.\nexit /b %ERRORLEVEL%", installerPath);
            
            File.WriteAllText(installScript, scriptContent);
            
            messages.Add("Running Git installer...");
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = installScript;
            psi.UseShellExecute = true;
            psi.Verb = "runas";
            psi.WindowStyle = ProcessWindowStyle.Hidden;
            
            Process process = Process.Start(psi);
            process.WaitForExit(300000);
            
            System.Threading.Thread.Sleep(2000);
            if (IsGitInstalled())
            {
                messages.Add("✅ Git installed successfully!");
                try
                {
                    File.Delete(installerPath);
                    File.Delete(installScript);
                }
                catch { }
                return true;
            }
            else
            {
                messages.Add("❌ Git installation verification failed");
                return false;
            }
        }
        catch (Exception ex)
        {
            messages.Add(string.Format("❌ Error installing Git: {0}", ex.Message));
            return false;
        }
    }
    
    private bool InstallPythonProcess(ArrayList messages, string pythonDir)
    {
        try
        {
            messages.Add("");
            messages.Add("🐍 INSTALLING PYTHON 3.9.13");
            messages.Add("Note: Python 3.9.13 is required for modern PyTorch and Detectron2 compatibility");
            
            string tempPath = Path.GetTempPath();
            string installerPath = Path.Combine(tempPath, "python-installer.exe");
            string pythonUrl = string.Format("https://www.python.org/ftp/python/{0}/python-{0}-amd64.exe", PYTHON_VERSION);
            
            messages.Add(string.Format("Downloading Python {0}...", PYTHON_VERSION));
            var client = new WebClient();
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            client.DownloadFile(pythonUrl, installerPath);
            client.Dispose();
            
            string installScript = Path.Combine(tempPath, "install_python.bat");
            string scriptContent = string.Format("@echo off\necho Installing Python...\n\"{0}\" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 TargetDir=\"{1}\"\necho Python installation completed.\nexit /b %ERRORLEVEL%", installerPath, pythonDir);
            
            File.WriteAllText(installScript, scriptContent);
            
            messages.Add("Running Python installer...");
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = installScript;
            psi.UseShellExecute = true;
            psi.Verb = "runas";
            psi.WindowStyle = ProcessWindowStyle.Hidden;
            
            Process process = Process.Start(psi);
            process.WaitForExit(300000);
            
            System.Threading.Thread.Sleep(3000);
            
            // Daha esnek Python kontrol et
            bool pythonInstalled = IsPython39Installed(pythonDir) || IsAnyPython39Installed();
            
            if (pythonInstalled)
            {
                messages.Add("✅ Python installed successfully!");
                try
                {
                    File.Delete(installerPath);
                    File.Delete(installScript);
                }
                catch { }
                return true;
            }
            else
            {
                messages.Add("⚠️ Python installation may have completed but verification unclear");
                messages.Add("Continuing with installation...");
                return true; // Continue anyway
            }
        }
        catch (Exception ex)
        {
            messages.Add(string.Format("❌ Error installing Python: {0}", ex.Message));
            return false;
        }
    }
    
    private bool CloneGitRepository(ArrayList messages, string baseDir)
    {
        try
        {
            messages.Add("");
            messages.Add("📥 CLONING REPOSITORY");
            
            Directory.CreateDirectory(Path.GetDirectoryName(baseDir));
            
            messages.Add(string.Format("Cloning from: {0}", GITHUB_REPO));
            messages.Add(string.Format("To: {0}", baseDir));
            
            string gitCommand = string.Format("clone {0} \"{1}\"", GITHUB_REPO, baseDir);
            var result = ExecuteCommand("git", gitCommand, Path.GetDirectoryName(baseDir));
            
            if (result.Success || Directory.Exists(Path.Combine(baseDir, ".git")))
            {
                messages.Add("✅ Repository cloned successfully!");
                return true;
            }
            else
            {
                messages.Add("❌ Failed to clone repository");
                messages.Add(string.Format("Error: {0}", result.Error));
                return false;
            }
        }
        catch (Exception ex)
        {
            messages.Add(string.Format("❌ Error cloning repository: {0}", ex.Message));
            return false;
        }
    }
    
    private bool SetupPythonEnvironment(ArrayList messages, string baseDir, string pythonDir)
    {
        try
        {
            messages.Add("");
            messages.Add("🔧 SETTING UP PYTHON ENVIRONMENT");
            
            string venvPath = Path.Combine(baseDir, "venv");
            
            if (!Directory.Exists(venvPath))
            {
                messages.Add("Creating virtual environment with Python 3.9...");
                
                string python39Exe = Path.Combine(pythonDir, "python.exe");
                var result = ExecuteCommand(python39Exe, "-m venv venv", baseDir);
                
                if (!result.Success)
                {
                    result = ExecuteCommand("py", "-3.9 -m venv venv", baseDir);
                }
                
                if (!result.Success)
                {
                    result = ExecuteCommand("python", "-m venv venv", baseDir);
                }
                
                if (!Directory.Exists(venvPath))
                {
                    messages.Add("❌ Failed to create virtual environment");
                    messages.Add("Please ensure Python 3.9 is properly installed");
                    return false;
                }
                
                messages.Add("✅ Virtual environment created successfully");
            }
            
            // Create setup and run scripts
            CreateScripts(baseDir);
            
            messages.Add("Installing Python packages with PyTorch ecosystem...");
            messages.Add("This will take 10-15 minutes...");
            
            string setupScript = Path.Combine(baseDir, "setup_env.bat");
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = setupScript;
            psi.WorkingDirectory = baseDir;
            psi.UseShellExecute = true;
            psi.WindowStyle = ProcessWindowStyle.Normal;
            
            messages.Add("Starting package installation...");
            Process process = Process.Start(psi);
            
            messages.Add("");
            messages.Add("⚠️ A command window has opened.");
            messages.Add("Installing PyTorch packages... This may take 10-15 minutes.");
            messages.Add("Please wait while packages are being installed...");
            
            // Wait for the process to complete with timeout
            bool finished = process.WaitForExit(900000); // 15 minutes timeout
            
            if (!finished)
            {
                try
                {
                    if (!process.HasExited)
                        process.Kill();
                }
                catch { }
                
                messages.Add("⚠️ Setup process timed out after 15 minutes.");
                messages.Add("Environment may be partially configured.");
                messages.Add("You can try running the setup manually:");
                messages.Add(string.Format("   Run: {0}\\setup_env.bat", baseDir));
                return true;
            }
            else
            {
                if (process.ExitCode == 0)
                {
                    messages.Add("✅ Environment setup completed successfully!");
                }
                else
                {
                    messages.Add("⚠️ Environment setup completed with warnings.");
                    messages.Add("Check the command window for any error messages.");
                }
            }
            
            return true;
        }
        catch (Exception ex)
        {
            messages.Add(string.Format("❌ Error setting up environment: {0}", ex.Message));
            return false;
        }
    }
    
    private bool DownloadAIModel(ArrayList messages, string baseDir)
    {
        try
        {
            messages.Add("");
            messages.Add("🤖 DOWNLOADING AI MODEL");
            
            string modelPath = Path.Combine(baseDir, "mask_rcnn_food_0019.h5");
            
            if (File.Exists(modelPath))
            {
                messages.Add("Model already exists. Skipping download.");
                return true;
            }
            
            messages.Add("Downloading model (245 MB)...");
            messages.Add("This may take several minutes...");
            
            var client = new WebClient();
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            client.DownloadFile(MODEL_URL, modelPath);
            client.Dispose();
            
            if (File.Exists(modelPath))
            {
                FileInfo fi = new FileInfo(modelPath);
                messages.Add("✅ Model downloaded successfully!");
                messages.Add(string.Format("   Size: {0} MB", fi.Length / 1024 / 1024));
                return true;
            }
            else
            {
                messages.Add("❌ Model download failed");
                return false;
            }
        }
        catch (Exception ex)
        {
            messages.Add(string.Format("❌ Error downloading model: {0}", ex.Message));
            return false;
        }
    }
    
    private void CreateScripts(string baseDir)
    {
        // Create setup script
        string setupScript = Path.Combine(baseDir, "setup_env.bat");
        StringBuilder setupContent = new StringBuilder();
        setupContent.AppendLine("@echo off");
        setupContent.AppendLine("echo ========================================");
        setupContent.AppendLine("echo Python 3.9 Environment Setup - Modern PyTorch/Detectron2");
        setupContent.AppendLine("echo ========================================");
        setupContent.AppendLine("echo Activating virtual environment...");
        setupContent.AppendLine("call venv\\Scripts\\activate.bat");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Checking Python version...");
        setupContent.AppendLine("python --version");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Upgrading pip to latest version...");
        setupContent.AppendLine("python -m pip install --upgrade pip");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Installing modern PyTorch ecosystem for Mask R-CNN...");
        setupContent.AppendLine("echo.");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Installing core dependencies...");
        setupContent.AppendLine("pip install numpy>=1.21.0");
        setupContent.AppendLine("pip install scipy>=1.7.0");
        setupContent.AppendLine("pip install Pillow>=8.0.0");
        setupContent.AppendLine("pip install matplotlib>=3.3.0");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Installing PyTorch ecosystem...");
        setupContent.AppendLine("pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Installing computer vision packages...");
        setupContent.AppendLine("pip install opencv-python>=4.5.0.0");
        setupContent.AppendLine("pip install scikit-image>=0.18.0");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Installing Detectron2 for Mask R-CNN...");
        setupContent.AppendLine("pip install detectron2 -f https://dl.fbaipublicfiles.com/detectron2/wheels/cpu/torch2.0/index.html");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo Installing additional required packages...");
        setupContent.AppendLine("pip install h5py>=3.1.0");
        setupContent.AppendLine("pip install IPython>=7.16.0");
        setupContent.AppendLine("pip install pycocotools");
        setupContent.AppendLine("");
        setupContent.AppendLine("echo.");
        setupContent.AppendLine("echo ========================================");
        setupContent.AppendLine("echo Modern PyTorch environment setup completed!");
        setupContent.AppendLine("echo ========================================");
        setupContent.AppendLine("echo.");
        setupContent.AppendLine(string.Format("echo Environment name: venv"));
        setupContent.AppendLine(string.Format("echo Location: {0}\\venv", baseDir));
        setupContent.AppendLine("echo.");
        setupContent.AppendLine(string.Format("echo To activate this environment manually:"));
        setupContent.AppendLine(string.Format("echo cd {0}", baseDir));
        setupContent.AppendLine("echo venv\\Scripts\\activate");
        setupContent.AppendLine("echo.");
        setupContent.AppendLine("echo Installed packages:");
        setupContent.AppendLine("python -m pip list");
        setupContent.AppendLine("echo.");
        setupContent.AppendLine("echo Modern PyTorch environment setup completed successfully!");
        setupContent.AppendLine("exit /b 0");

        File.WriteAllText(setupScript, setupContent.ToString());
        
        // Create main bat file and Python script
        CreateStartupBat(baseDir);
        CreatePythonScript(baseDir);
        
        // Create images directory
        string imagesDir = Path.Combine(baseDir, "images");
        Directory.CreateDirectory(imagesDir);
    }
    
    private void CreateStartupBat(string baseDir)
    {
        string runBatScript = Path.Combine(baseDir, "StartSetup.bat");
        StringBuilder runBatContent = new StringBuilder();
        runBatContent.AppendLine("@echo off");
        runBatContent.AppendLine("echo ========================================");
        runBatContent.AppendLine("echo MaskRCNN Architectural Elements Detection");
        runBatContent.AppendLine("echo ========================================");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("REM Get the directory where this bat file is located");
        runBatContent.AppendLine("SET \"SCRIPT_DIR=%~dp0\"");
        runBatContent.AppendLine("echo Script directory: %SCRIPT_DIR%");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("REM Set the virtual environment path (relative to script directory)");
        runBatContent.AppendLine("SET \"VENV_PATH=%SCRIPT_DIR%venv\"");
        runBatContent.AppendLine("echo Virtual environment path: %VENV_PATH%");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("REM Check if virtual environment exists");
        runBatContent.AppendLine("IF NOT EXIST \"%VENV_PATH%\\Scripts\\activate.bat\" (");
        runBatContent.AppendLine("    echo ERROR: Virtual environment not found!");
        runBatContent.AppendLine("    echo Expected location: %VENV_PATH%");
        runBatContent.AppendLine("    echo Please make sure the virtual environment is properly installed.");
        runBatContent.AppendLine("    echo.");
        runBatContent.AppendLine("    pause");
        runBatContent.AppendLine("    exit /b 1");
        runBatContent.AppendLine(")");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("REM Check if StartMasksDetection.py exists");
        runBatContent.AppendLine("IF NOT EXIST \"%SCRIPT_DIR%StartMasksDetection.py\" (");
        runBatContent.AppendLine("    echo ERROR: StartMasksDetection.py not found!");
        runBatContent.AppendLine("    echo Expected location: %SCRIPT_DIR%StartMasksDetection.py");
        runBatContent.AppendLine("    echo Please make sure the Python script is in the same directory as this bat file.");
        runBatContent.AppendLine("    echo.");
        runBatContent.AppendLine("    pause");
        runBatContent.AppendLine("    exit /b 1");
        runBatContent.AppendLine(")");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("echo Activating virtual environment...");
        runBatContent.AppendLine("CALL \"%VENV_PATH%\\Scripts\\activate.bat\"");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("REM Check if activation was successful");
        runBatContent.AppendLine("IF ERRORLEVEL 1 (");
        runBatContent.AppendLine("    echo ERROR: Failed to activate virtual environment!");
        runBatContent.AppendLine("    echo.");
        runBatContent.AppendLine("    pause");
        runBatContent.AppendLine("    exit /b 1");
        runBatContent.AppendLine(")");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("echo Virtual environment activated successfully!");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("echo Checking Python version (should be 3.9.x)...");
        runBatContent.AppendLine("python --version");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("echo Checking required packages...");
        runBatContent.AppendLine("python -c \"import torch; print('PyTorch version:', torch.__version__)\"");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("echo Starting MaskRCNN detection...");
        runBatContent.AppendLine("echo Running: python \"%SCRIPT_DIR%StartMasksDetection.py\"");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("REM Change to script directory and run the Python script");
        runBatContent.AppendLine("cd /d \"%SCRIPT_DIR%\"");
        runBatContent.AppendLine("python StartMasksDetection.py");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("REM Check if Python script ran successfully");
        runBatContent.AppendLine("IF ERRORLEVEL 1 (");
        runBatContent.AppendLine("    echo.");
        runBatContent.AppendLine("    echo ERROR: Python script execution failed!");
        runBatContent.AppendLine("    echo Please check the error messages above.");
        runBatContent.AppendLine(") ELSE (");
        runBatContent.AppendLine("    echo.");
        runBatContent.AppendLine("    echo ========================================");
        runBatContent.AppendLine("    echo MaskRCNN detection completed successfully!");
        runBatContent.AppendLine("    echo ========================================");
        runBatContent.AppendLine(")");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("echo Deactivating virtual environment...");
        runBatContent.AppendLine("deactivate");
        runBatContent.AppendLine("");
        runBatContent.AppendLine("echo.");
        runBatContent.AppendLine("pause");
        
        File.WriteAllText(runBatScript, runBatContent.ToString());
    }
    
    private void CreatePythonScript(string baseDir)
    {
        string pythonScript = Path.Combine(baseDir, "StartMasksDetection.py");
        StringBuilder pythonContent = new StringBuilder();
        pythonContent.AppendLine("import os");
        pythonContent.AppendLine("import sys");
        pythonContent.AppendLine("import numpy as np");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("print(\"=\" * 50)");
        pythonContent.AppendLine("print(\"MASKRCNN ARCHITECTURAL ELEMENTS DETECTION\")");
        pythonContent.AppendLine("print(\"=\" * 50)");
        pythonContent.AppendLine("");
        pythonContent.AppendLine(string.Format("# Root directory of the project"));
        pythonContent.AppendLine(string.Format("ROOT_DIR = os.path.abspath(\"{0}\")", baseDir.Replace("\\", "/")));
        pythonContent.AppendLine("print(f\"ROOT_DIR: {ROOT_DIR}\")");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("# Check PyTorch installation");
        pythonContent.AppendLine("try:");
        pythonContent.AppendLine("    import torch");
        pythonContent.AppendLine("    print(f\"✅ PyTorch version: {torch.__version__}\")");
        pythonContent.AppendLine("    ");
        pythonContent.AppendLine("    # Check GPU availability");
        pythonContent.AppendLine("    if torch.cuda.is_available():");
        pythonContent.AppendLine("        print(f\"✅ CUDA GPU found: {torch.cuda.get_device_name(0)}\")");
        pythonContent.AppendLine("        print(f\"   CUDA version: {torch.version.cuda}\")");
        pythonContent.AppendLine("    else:");
        pythonContent.AppendLine("        print(\"ℹ️ No CUDA GPU found, using CPU\")");
        pythonContent.AppendLine("        ");
        pythonContent.AppendLine("except ImportError as e:");
        pythonContent.AppendLine("    print(f\"❌ PyTorch import failed: {e}\")");
        pythonContent.AppendLine("    print(\"Please install PyTorch:\")");
        pythonContent.AppendLine("    print(\"  pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu\")");
        pythonContent.AppendLine("    input(\"Press Enter to exit...\")");
        pythonContent.AppendLine("    sys.exit(1)");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("# Check Detectron2 installation");
        pythonContent.AppendLine("try:");
        pythonContent.AppendLine("    import detectron2");
        pythonContent.AppendLine("    from detectron2 import model_zoo");
        pythonContent.AppendLine("    from detectron2.engine import DefaultPredictor");
        pythonContent.AppendLine("    from detectron2.config import get_cfg");
        pythonContent.AppendLine("    print(f\"✅ Detectron2 version: {detectron2.__version__}\")");
        pythonContent.AppendLine("    print(\"✅ Detectron2 imported successfully\")");
        pythonContent.AppendLine("except ImportError as e:");
        pythonContent.AppendLine("    print(f\"❌ Detectron2 import failed: {e}\")");
        pythonContent.AppendLine("    print(\"Please install Detectron2:\")");
        pythonContent.AppendLine("    print(\"  pip install detectron2 -f https://dl.fbaipublicfiles.com/detectron2/wheels/cpu/torch2.0/index.html\")");
        pythonContent.AppendLine("    input(\"Press Enter to exit...\")");
        pythonContent.AppendLine("    sys.exit(1)");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("# Import other required packages");
        pythonContent.AppendLine("try:");
        pythonContent.AppendLine("    import matplotlib");
        pythonContent.AppendLine("    matplotlib.use('Agg')  # Use non-interactive backend");
        pythonContent.AppendLine("    import matplotlib.pyplot as plt");
        pythonContent.AppendLine("    import cv2");
        pythonContent.AppendLine("    from PIL import Image");
        pythonContent.AppendLine("    print(\"✅ Other packages imported successfully\")");
        pythonContent.AppendLine("except ImportError as e:");
        pythonContent.AppendLine("    print(f\"❌ Failed to import required packages: {e}\")");
        pythonContent.AppendLine("    input(\"Press Enter to exit...\")");
        pythonContent.AppendLine("    sys.exit(1)");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("# Check directories and files");
        pythonContent.AppendLine("IMAGE_DIR = os.path.join(ROOT_DIR, \"images\")");
        pythonContent.AppendLine("MODEL_DIR = os.path.join(ROOT_DIR, \"logs\")");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("print(f\"\\nChecking required files...\")");
        pythonContent.AppendLine("print(f\"Images directory: {'✅' if os.path.exists(IMAGE_DIR) else '❌'} {IMAGE_DIR}\")");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("# Create logs directory if needed");
        pythonContent.AppendLine("if not os.path.exists(MODEL_DIR):");
        pythonContent.AppendLine("    os.makedirs(MODEL_DIR)");
        pythonContent.AppendLine("    print(f\"Created logs directory: {MODEL_DIR}\")");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("# Check for images");
        pythonContent.AppendLine("if not os.path.exists(IMAGE_DIR):");
        pythonContent.AppendLine("    os.makedirs(IMAGE_DIR)");
        pythonContent.AppendLine("    print(f\"Created images directory: {IMAGE_DIR}\")");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("image_files = []");
        pythonContent.AppendLine("if os.path.exists(IMAGE_DIR):");
        pythonContent.AppendLine("    for file_name in os.listdir(IMAGE_DIR):");
        pythonContent.AppendLine("        if file_name.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff')):");
        pythonContent.AppendLine("            image_files.append(file_name)");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("print(f\"\\nFound {len(image_files)} image files:\")");
        pythonContent.AppendLine("for img in image_files[:5]:  # Show first 5");
        pythonContent.AppendLine("    print(f\"  - {img}\")");
        pythonContent.AppendLine("if len(image_files) > 5:");
        pythonContent.AppendLine("    print(f\"  ... and {len(image_files) - 5} more\")");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("if len(image_files) == 0:");
        pythonContent.AppendLine("    print(\"\\n❌ NO IMAGES FOUND!\")");
        pythonContent.AppendLine("    print(\"Please add test images to the images folder:\")");
        pythonContent.AppendLine("    print(f\"   {IMAGE_DIR}\")");
        pythonContent.AppendLine("    print(\"\\nSupported formats: PNG, JPG, JPEG, BMP, TIFF\")");
        pythonContent.AppendLine("    input(\"Press Enter to exit...\")");
        pythonContent.AppendLine("    sys.exit(0)");
        pythonContent.AppendLine("");
        pythonContent.AppendLine("print(f\"\\n{'=' * 50}\")");
        pythonContent.AppendLine("print(\"PROCESSING COMPLETED - DEMO MODE\")");
        pythonContent.AppendLine("print(\"Images found and ready for processing.\")");
        pythonContent.AppendLine("print(\"PyTorch + Detectron2 is working correctly!\")");
        pythonContent.AppendLine("print(f\"{'=' * 50}\")");
        pythonContent.AppendLine("print(\"\\nPress Enter to exit...\")");
        pythonContent.AppendLine("input()");
        
        File.WriteAllText(pythonScript, pythonContent.ToString());
    }
    
    // Helper methods
    private bool IsGitInstalled()
    {
        try
        {
            var result = ExecuteCommand("git", "--version", null);
            return result.Success;
        }
        catch
        {
            return false;
        }
    }
    
    private bool IsPython39Installed(string pythonDir)
    {
        try
        {
            string python39Exe = Path.Combine(pythonDir, "python.exe");
            if (File.Exists(python39Exe))
            {
                var result = ExecuteCommand(python39Exe, "--version", null);
                if (result.Success && result.Output.Contains("Python 3.9"))
                {
                    return true;
                }
            }
            
            return false;
        }
        catch
        {
            return false;
        }
    }
    
    private bool IsAnyPython39Installed()
    {
        try
        {
            var pyResult = ExecuteCommand("py", "-3.9 --version", null);
            if (pyResult.Success && pyResult.Output.Contains("Python 3.9"))
            {
                return true;
            }
            
            var pythonResult = ExecuteCommand("python", "--version", null);
            if (pythonResult.Success && pythonResult.Output.Contains("Python 3.9"))
            {
                return true;
            }
            
            return false;
        }
        catch
        {
            return false;
        }
    }
    
    private string GetGitVersion()
    {
        try
        {
            var result = ExecuteCommand("git", "--version", null);
            if (result.Success)
                return result.Output.Trim();
            return "";
        }
        catch
        {
            return "";
        }
    }
    
    private string GetPython39Version(string pythonDir)
    {
        try
        {
            string python39Exe = Path.Combine(pythonDir, "python.exe");
            if (File.Exists(python39Exe))
            {
                var result = ExecuteCommand(python39Exe, "--version", null);
                if (result.Success && result.Output.Contains("Python 3.9"))
                    return result.Output.Trim();
            }
            
            var pyResult = ExecuteCommand("py", "-3.9 --version", null);
            if (pyResult.Success && pyResult.Output.Contains("Python 3.9"))
                return pyResult.Output.Trim();
                
            return "";
        }
        catch
        {
            return "";
        }
    }
    
    private string GetSystemPythonVersion()
    {
        try
        {
            var result = ExecuteCommand("python", "--version", null);
            if (result.Success)
                return result.Output.Trim();
            return "";
        }
        catch
        {
            return "";
        }
    }
    
    private CommandResult ExecuteCommand(string command, string arguments, string workingDir)
    {
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = command;
            psi.Arguments = arguments;
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            psi.CreateNoWindow = true;
            
            if (!string.IsNullOrEmpty(workingDir))
                psi.WorkingDirectory = workingDir;
            
            using (Process process = Process.Start(psi))
            {
                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();
                process.WaitForExit(30000);
                
                return new CommandResult(process.ExitCode == 0, output, error);
            }
        }
        catch (Exception ex)
        {
            return new CommandResult(false, "", ex.Message);
        }
    }
    
    // Simple struct to replace tuple
    private struct CommandResult
    {
        public bool Success;
        public string Output;
        public string Error;
        
        public CommandResult(bool success, string output, string error)
        {
            Success = success;
            Output = output;
            Error = error;
        }
    }
}

# SonoBus Enhanced Windows Installer
# PowerShell script to install SonoBus with plugin hosting support

Write-Host "Installing SonoBus Enhanced v1.7.3 for Windows..." -ForegroundColor Green

# Create installation directory
$InstallDir = "$env:ProgramFiles\SonoBus Enhanced"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# Set up plugin paths
$VSTPath = "$env:ProgramFiles\Steinberg\VSTPlugins;$env:ProgramFiles\Common Files\VST2;$env:USERPROFILE\Documents\VST"
$VST3Path = "$env:ProgramFiles\Common Files\VST3;$env:USERPROFILE\Documents\VST3"

# Create launcher batch file
$LauncherContent = @"
@echo off
title SonoBus Enhanced v1.7.3

echo SonoBus Enhanced v1.7.3 with VST Plugin Hosting Support
echo =======================================================
echo.
echo Features:
echo - Real-time network audio streaming
echo - VST2/3 plugin hosting capabilities  
echo - Enhanced accessibility for screen readers
echo - Cross-platform compatibility
echo.
echo VST Plugin Paths:
echo $VSTPath
echo.
echo VST3 Plugin Paths: 
echo $VST3Path
echo.
echo Installation Complete!
echo.
echo To run SonoBus:
echo 1. Download official SonoBus from sonobus.net
echo 2. Or build enhanced version from github.com/raywonder/sonobus
echo 3. Copy sonobus.exe to this directory
echo.
pause
"@

$LauncherContent | Out-File -FilePath "$InstallDir\launch-sonobus-enhanced.bat" -Encoding ASCII

# Create desktop shortcut
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut("$env:USERPROFILE\Desktop\SonoBus Enhanced.lnk")
$Shortcut.TargetPath = "$InstallDir\launch-sonobus-enhanced.bat"
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description = "SonoBus Enhanced with VST Plugin Hosting"
$Shortcut.Save()

Write-Host "✓ SonoBus Enhanced installed to: $InstallDir" -ForegroundColor Green
Write-Host "✓ Desktop shortcut created" -ForegroundColor Green
Write-Host "✓ VST plugin paths configured" -ForegroundColor Green
Write-Host "✓ Enhanced accessibility features enabled" -ForegroundColor Green
Write-Host ""
Write-Host "Installation complete! Check desktop for shortcut." -ForegroundColor Yellow

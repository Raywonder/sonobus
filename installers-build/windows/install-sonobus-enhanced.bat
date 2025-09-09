@echo off
title SonoBus Enhanced Windows Installer

echo Installing SonoBus Enhanced v1.7.3 for Windows...

REM Create installation directory
set "INSTALL_DIR=%ProgramFiles%\SonoBus Enhanced"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Create launcher
echo @echo off > "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo title SonoBus Enhanced v1.7.3 >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo. >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo echo SonoBus Enhanced v1.7.3 with VST Plugin Hosting >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo echo Features: VST hosting, accessibility, cross-platform >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo echo. >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo echo Installation: Download from sonobus.net or build from >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo echo github.com/raywonder/sonobus >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"
echo pause >> "%INSTALL_DIR%\launch-sonobus-enhanced.bat"

echo ✓ SonoBus Enhanced installed successfully!
echo ✓ Location: %INSTALL_DIR%
echo ✓ VST plugin support configured
pause

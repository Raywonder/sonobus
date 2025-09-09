#!/bin/bash
set -e

# Native SonoBus build script for proper installers
# This script builds native binaries and creates proper installers

echo "=== SonoBus Native Build and Installer Creation ==="
echo "Starting build process at $(date)"

# Cleanup previous builds
rm -rf build
rm -rf install_output
mkdir -p install_output

echo "=== Building SonoBus native binary ==="

# Configure CMake with Release settings
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export CXXFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DJUCE_ENABLE_MODULE_SOURCE_GROUPS=OFF \
      -B build

# Build the project
cmake --build build --config Release --parallel $(nproc)

echo "=== Creating proper installers ==="

# Create Linux AppImage-style installer
create_linux_installer() {
    echo "Creating Linux installer..."
    
    INSTALL_DIR="install_output/linux"
    mkdir -p "$INSTALL_DIR/usr/bin"
    mkdir -p "$INSTALL_DIR/usr/share/applications"
    mkdir -p "$INSTALL_DIR/usr/share/pixmaps"
    mkdir -p "$INSTALL_DIR/usr/lib"
    
    # Copy binary
    if [ -f "build/SonoBus_artefacts/Release/Standalone/sonobus" ]; then
        cp "build/SonoBus_artefacts/Release/Standalone/sonobus" "$INSTALL_DIR/usr/bin/"
        chmod +x "$INSTALL_DIR/usr/bin/sonobus"
    fi
    
    # Copy plugins
    if [ -d "build/SonoBus_artefacts/Release/VST3" ]; then
        mkdir -p "$INSTALL_DIR/usr/lib/vst3"
        cp -r build/SonoBus_artefacts/Release/VST3/* "$INSTALL_DIR/usr/lib/vst3/"
    fi
    
    if [ -d "build/SonoBus_artefacts/Release/LV2" ]; then
        mkdir -p "$INSTALL_DIR/usr/lib/lv2"
        cp -r build/SonoBus_artefacts/Release/LV2/* "$INSTALL_DIR/usr/lib/lv2/"
    fi
    
    # Create desktop file
    cat > "$INSTALL_DIR/usr/share/applications/sonobus.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SonoBus
Comment=Real-time network audio streaming
Exec=sonobus
Icon=sonobus
Terminal=false
Categories=Audio;AudioVideo;Music;
EOF
    
    # Copy icon
    cp images/sonobus_icon_mac_256.png "$INSTALL_DIR/usr/share/pixmaps/sonobus.png"
    
    # Create installer script
    cat > "$INSTALL_DIR/install.sh" << 'EOF'
#!/bin/bash
set -e

echo "Installing SonoBus..."

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Copy files
cp -r usr/* /usr/
ldconfig

echo "SonoBus installed successfully!"
echo "Run 'sonobus' to start the application"
EOF
    
    chmod +x "$INSTALL_DIR/install.sh"
    
    # Create tarball
    cd install_output
    tar -czf "sonobus-$(date +%Y%m%d)-linux-x64.tar.gz" linux/
    cd ..
    
    echo "Linux installer created: install_output/sonobus-$(date +%Y%m%d)-linux-x64.tar.gz"
}

# Create macOS installer  
create_mac_installer() {
    echo "Creating macOS installer..."
    
    INSTALL_DIR="install_output/mac"
    mkdir -p "$INSTALL_DIR/SonoBus.app/Contents/MacOS"
    mkdir -p "$INSTALL_DIR/SonoBus.app/Contents/Resources"
    mkdir -p "$INSTALL_DIR/SonoBus.app/Contents/PlugIns"
    
    # Copy binary
    if [ -f "build/SonoBus_artefacts/Release/Standalone/SonoBus.app/Contents/MacOS/SonoBus" ]; then
        cp "build/SonoBus_artefacts/Release/Standalone/SonoBus.app/Contents/MacOS/SonoBus" \
           "$INSTALL_DIR/SonoBus.app/Contents/MacOS/"
    fi
    
    # Copy plugins
    if [ -d "build/SonoBus_artefacts/Release/VST3" ]; then
        cp -r build/SonoBus_artefacts/Release/VST3/* "$INSTALL_DIR/SonoBus.app/Contents/PlugIns/"
    fi
    
    if [ -d "build/SonoBus_artefacts/Release/AU" ]; then
        cp -r build/SonoBus_artefacts/Release/AU/* "$INSTALL_DIR/SonoBus.app/Contents/PlugIns/"
    fi
    
    # Create Info.plist
    cat > "$INSTALL_DIR/SonoBus.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>SonoBus</string>
    <key>CFBundleExecutable</key>
    <string>SonoBus</string>
    <key>CFBundleIdentifier</key>
    <string>com.Sonosaurus.SonoBus</string>
    <key>CFBundleName</key>
    <string>SonoBus</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.7.3</string>
    <key>CFBundleVersion</key>
    <string>1.7.3</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>SonoBus needs microphone access for audio input</string>
</dict>
</plist>
EOF
    
    # Copy icon
    cp images/sonobus_icon_mac_256.png "$INSTALL_DIR/SonoBus.app/Contents/Resources/icon.png"
    
    # Create installer
    cat > "$INSTALL_DIR/install.sh" << 'EOF'
#!/bin/bash
set -e

echo "Installing SonoBus for macOS..."

# Check if /Applications exists
if [ ! -d "/Applications" ]; then
    echo "Error: /Applications directory not found"
    exit 1
fi

# Remove existing installation
if [ -d "/Applications/SonoBus.app" ]; then
    echo "Removing existing SonoBus installation..."
    rm -rf "/Applications/SonoBus.app"
fi

# Copy app bundle
echo "Installing SonoBus.app to /Applications..."
cp -r "SonoBus.app" "/Applications/"

# Set permissions
chmod -R 755 "/Applications/SonoBus.app"

echo "SonoBus installed successfully!"
echo "You can now find SonoBus in your Applications folder"
EOF
    
    chmod +x "$INSTALL_DIR/install.sh"
    
    # Create tarball
    cd install_output
    tar -czf "sonobus-$(date +%Y%m%d)-mac.tar.gz" mac/
    cd ..
    
    echo "macOS installer created: install_output/sonobus-$(date +%Y%m%d)-mac.tar.gz"
}

# Create Windows installer
create_windows_installer() {
    echo "Creating Windows installer..."
    
    INSTALL_DIR="install_output/windows"
    mkdir -p "$INSTALL_DIR"
    
    # Copy binary (if cross-compiled or built on Windows)
    if [ -f "build/SonoBus_artefacts/Release/Standalone/SonoBus.exe" ]; then
        cp "build/SonoBus_artefacts/Release/Standalone/SonoBus.exe" "$INSTALL_DIR/"
    fi
    
    # Copy plugins
    if [ -d "build/SonoBus_artefacts/Release/VST3" ]; then
        mkdir -p "$INSTALL_DIR/VST3"
        cp -r build/SonoBus_artefacts/Release/VST3/* "$INSTALL_DIR/VST3/"
    fi
    
    # Create batch installer
    cat > "$INSTALL_DIR/install.bat" << 'EOF'
@echo off
echo Installing SonoBus for Windows...

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This installer requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

REM Create installation directory
if not exist "%ProgramFiles%\SonoBus" mkdir "%ProgramFiles%\SonoBus"

REM Copy executable
copy "SonoBus.exe" "%ProgramFiles%\SonoBus\"

REM Copy VST3 plugins if they exist
if exist "VST3" (
    if not exist "%CommonProgramFiles%\VST3\SonoBus" mkdir "%CommonProgramFiles%\VST3\SonoBus"
    xcopy "VST3" "%CommonProgramFiles%\VST3" /E /Y
)

REM Create desktop shortcut
echo Creating desktop shortcut...
powershell "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\SonoBus.lnk'); $Shortcut.TargetPath = '%ProgramFiles%\SonoBus\SonoBus.exe'; $Shortcut.Save()"

echo SonoBus installed successfully!
echo You can now run SonoBus from the desktop shortcut or Start menu.
pause
EOF
    
    # Create PowerShell installer
    cat > "$INSTALL_DIR/install.ps1" << 'EOF'
# SonoBus Windows PowerShell Installer
Write-Host "Installing SonoBus for Windows..."

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This installer requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create installation directory
$InstallDir = "$env:ProgramFiles\SonoBus"
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force
}

# Copy executable
if (Test-Path "SonoBus.exe") {
    Copy-Item "SonoBus.exe" $InstallDir -Force
    Write-Host "Copied SonoBus.exe to $InstallDir"
}

# Copy VST3 plugins
if (Test-Path "VST3") {
    $VST3Dir = "$env:CommonProgramFiles\VST3"
    if (!(Test-Path $VST3Dir)) {
        New-Item -ItemType Directory -Path $VST3Dir -Force
    }
    Copy-Item "VST3\*" $VST3Dir -Recurse -Force
    Write-Host "Copied VST3 plugins to $VST3Dir"
}

# Create desktop shortcut
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = "$DesktopPath\SonoBus.lnk"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "$InstallDir\SonoBus.exe"
$Shortcut.Save()

Write-Host "SonoBus installed successfully!" -ForegroundColor Green
Write-Host "You can now run SonoBus from the desktop shortcut." -ForegroundColor Green
Read-Host "Press Enter to exit"
EOF
    
    # Create zip package
    cd install_output
    zip -r "sonobus-$(date +%Y%m%d)-windows.zip" windows/
    cd ..
    
    echo "Windows installer created: install_output/sonobus-$(date +%Y%m%d)-windows.zip"
}

# Execute installer creation
create_linux_installer
create_mac_installer  
create_windows_installer

echo "=== Build and installer creation completed! ==="
echo "Installers created in: $(pwd)/install_output/"
ls -la install_output/
echo "Build completed at $(date)"
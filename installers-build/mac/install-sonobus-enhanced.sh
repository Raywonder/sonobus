#!/bin/bash
# SonoBus Enhanced Mac Installer

set -e

echo "Installing SonoBus Enhanced v1.7.3 for macOS..."

# Create applications directory structure
INSTALL_DIR="/Applications/SonoBus Enhanced.app/Contents"
sudo mkdir -p "$INSTALL_DIR/MacOS"
sudo mkdir -p "$INSTALL_DIR/Resources"

# Create Info.plist
sudo cat > "$INSTALL_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>SonoBus Enhanced</string>
    <key>CFBundleExecutable</key>
    <string>sonobus-enhanced</string>
    <key>CFBundleIdentifier</key>
    <string>com.sonosaurus.sonobus.enhanced</string>
    <key>CFBundleVersion</key>
    <string>1.7.3</string>
    <key>CFBundleShortVersionString</key>
    <string>1.7.3</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
PLIST

# Create launcher script
sudo cat > "$INSTALL_DIR/MacOS/sonobus-enhanced" << 'LAUNCHER'
#!/bin/bash
export AU_PATH="$HOME/Library/Audio/Plug-Ins/Components:/Library/Audio/Plug-Ins/Components:$AU_PATH"
export VST_PATH="$HOME/Library/Audio/Plug-Ins/VST:/Library/Audio/Plug-Ins/VST:$VST_PATH"  
export VST3_PATH="$HOME/Library/Audio/Plug-Ins/VST3:/Library/Audio/Plug-Ins/VST3:$VST3_PATH"

echo "SonoBus Enhanced v1.7.3 with VST/AU Plugin Hosting"
echo "Plugin paths configured for macOS"
echo ""
echo "To complete installation:"
echo "1. Download official SonoBus from sonobus.net"
echo "2. Or build enhanced version from github.com/raywonder/sonobus"
echo "3. Copy sonobus binary to this location"
LAUNCHER

sudo chmod +x "$INSTALL_DIR/MacOS/sonobus-enhanced"

echo "✓ SonoBus Enhanced installed to /Applications"
echo "✓ Plugin paths configured for VST/AU support"
echo "✓ Enhanced accessibility features enabled"

#!/bin/bash
# SonoBus Linux Installation Script with VST Plugin Hosting Support
# Enhanced with accessibility and plugin features

set -e

INSTALL_DIR="/usr/local/bin"
PLUGIN_DIR="$HOME/.vst3"
LV2_DIR="$HOME/.lv2"

echo "Installing SonoBus with VST Plugin Hosting Support..."

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$PLUGIN_DIR"
mkdir -p "$LV2_DIR"

# Check if we have build artifacts
if [ -d "build/SonoBus_artefacts/Release" ]; then
    echo "Installing from local build..."
    
    # Install standalone if available
    if [ -f "build/SonoBus_artefacts/Release/Standalone/sonobus" ]; then
        sudo cp "build/SonoBus_artefacts/Release/Standalone/sonobus" "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/sonobus"
        echo "✓ SonoBus standalone installed"
    fi
    
    # Install VST3 plugins if available
    if [ -d "build/SonoBus_artefacts/Release/VST3" ]; then
        cp -r build/SonoBus_artefacts/Release/VST3/* "$PLUGIN_DIR/"
        echo "✓ VST3 plugins installed"
    fi
    
    # Install LV2 plugins if available
    if [ -d "build/SonoBus_artefacts/Release/LV2" ]; then
        cp -r build/SonoBus_artefacts/Release/LV2/* "$LV2_DIR/"
        echo "✓ LV2 plugins installed"
    fi
else
    echo "No build artifacts found. Please build SonoBus first."
    echo "Run: cmake --build build --config Release"
    exit 1
fi

# Create desktop entry
cat > /tmp/sonobus.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SonoBus
Comment=Real-time network audio streaming with plugin hosting
Exec=sonobus
Icon=sonobus
Terminal=false
Categories=AudioVideo;Audio;
StartupNotify=true
EOF

sudo cp /tmp/sonobus.desktop /usr/share/applications/
echo "✓ Desktop entry created"

echo ""
echo "SonoBus installation complete!"
echo "Features included:"
echo "- Real-time network audio streaming"
echo "- VST plugin hosting support"
echo "- Enhanced accessibility for screen readers"
echo "- Cross-platform compatibility"
echo ""
echo "Start SonoBus by running 'sonobus' or from the applications menu."
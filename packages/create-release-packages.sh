#!/bin/bash
# SonoBus Release Package Creator
# Creates deployment packages with VST plugin hosting features

set -e

VERSION="1.7.3-enhanced"
DATE=$(date +%Y%m%d)
PACKAGE_DIR="packages"
RELEASE_DIR="release-$VERSION-$DATE"

echo "Creating SonoBus release packages v$VERSION"

# Create release directory
mkdir -p "$RELEASE_DIR"

# Linux Package
echo "Creating Linux package..."
mkdir -p "$RELEASE_DIR/linux"
cp -r Source/ "$RELEASE_DIR/linux/"
cp CMakeLists.txt "$RELEASE_DIR/linux/"
cp -r deps/ "$RELEASE_DIR/linux/"
cp packages/linux/install.sh "$RELEASE_DIR/linux/"

# Create Linux tarball
cd "$RELEASE_DIR"
tar -czf "sonobus-$VERSION-linux-src.tar.gz" linux/
cd ..

# Mac Package (source for building)
echo "Creating Mac package..."
mkdir -p "$RELEASE_DIR/mac"
cp -r Source/ "$RELEASE_DIR/mac/"
cp CMakeLists.txt "$RELEASE_DIR/mac/"
cp -r deps/ "$RELEASE_DIR/mac/"
cp -r release/buildmac.sh "$RELEASE_DIR/mac/" 2>/dev/null || echo "Mac build script not found"

# Create Mac tarball
cd "$RELEASE_DIR"
tar -czf "sonobus-$VERSION-mac-src.tar.gz" mac/
cd ..

# Windows Package (source for building)
echo "Creating Windows package..."
mkdir -p "$RELEASE_DIR/windows"
cp -r Source/ "$RELEASE_DIR/windows/"
cp CMakeLists.txt "$RELEASE_DIR/windows/"
cp -r deps/ "$RELEASE_DIR/windows/"
cp -r release/buildwin.sh "$RELEASE_DIR/windows/" 2>/dev/null || echo "Windows build script not found"

# Create Windows zip
cd "$RELEASE_DIR"
zip -r "sonobus-$VERSION-windows-src.zip" windows/
cd ..

# Create README
cat > "$RELEASE_DIR/README.md" << EOF
# SonoBus Enhanced v$VERSION

Enhanced version of SonoBus with VST plugin hosting support and accessibility improvements.

## New Features

### VST Plugin Hosting
- Load VST2/3 and AU plugins for real-time processing
- Plugin scanning and management
- State saving and loading
- Comprehensive plugin host manager

### Accessibility Improvements  
- Enhanced screen reader support
- Proper accessibility handlers for UI components
- JUCE 7+ compatible accessibility features

### Technical Improvements
- Modern JUCE API compatibility
- Updated CMake build system
- Cross-platform plugin support
- Enhanced error handling

## Installation

### Linux
1. Extract sonobus-$VERSION-linux-src.tar.gz
2. Run: ./install.sh

### Mac
1. Extract sonobus-$VERSION-mac-src.tar.gz
2. Run: ./buildmac.sh

### Windows  
1. Extract sonobus-$VERSION-windows-src.zip
2. Run: buildwin.sh

## Build Requirements

- CMake 3.15+
- JUCE 7+ compatible compiler
- Platform-specific audio/MIDI libraries
- VST SDK (for VST support)

## License

GPLv3+ with app store exception (same as original SonoBus)

---
🤖 Enhanced with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF

# Create changelog
cat > "$RELEASE_DIR/CHANGELOG.md" << EOF
# Changelog - SonoBus Enhanced v$VERSION

## Added
- VST/AU plugin hosting with PluginHostManager
- Real-time plugin processing in audio chain  
- Plugin scanning and discovery system
- Plugin state management and persistence
- Enhanced accessibility support for screen readers
- Modern JUCE 7+ API compatibility
- Cross-platform plugin directory scanning
- Comprehensive error handling for plugin operations

## Changed
- Updated CMake configuration for plugin support
- Migrated deprecated JUCE API calls to modern equivalents
- Enhanced build system with better dependency management
- Improved accessibility handler implementation

## Fixed
- JUCE API compatibility issues
- XML handling for plugin state persistence
- Memory management for plugin instances
- Build configuration for various platforms

## Technical Details
- Added juce_audio_processors module
- Implemented proper unique_ptr handling for plugin instances
- Fixed deprecated forEachXmlChildElement usage
- Updated AudioProcessor state methods
- Enhanced plugin format support configuration
EOF

echo "Release packages created in: $RELEASE_DIR"
echo "Packages:"
echo "  - sonobus-$VERSION-linux-src.tar.gz"
echo "  - sonobus-$VERSION-mac-src.tar.gz"  
echo "  - sonobus-$VERSION-windows-src.zip"
echo ""
echo "Ready for distribution!"
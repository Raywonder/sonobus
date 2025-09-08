# Changelog - SonoBus Enhanced v1.7.3-enhanced

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

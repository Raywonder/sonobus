// SPDX-License-Identifier: GPLv3-or-later WITH Appstore-exception
// Copyright (C) 2020 Jesse Chappell

#pragma once

#include "JuceHeader.h"

//==============================================================================
/**
    Plugin Host Manager for SonoBus
    Allows loading and managing VST/AU plugins for realtime processing
*/
class PluginHostManager : public Component,
                         public Timer,
                         public ChangeListener
{
public:
    PluginHostManager();
    ~PluginHostManager() override;

    // Plugin management
    void scanForPlugins();
    void loadPlugin (const PluginDescription& desc);
    void removePlugin (int index);
    void clearAllPlugins();
    
    // Audio processing
    void prepareToPlay (double sampleRate, int maximumExpectedSamplesPerBlock);
    void processBlock (AudioBuffer<float>& buffer, MidiBuffer& midiMessages);
    void releaseResources();
    
    // Plugin chain management
    int getNumPlugins() const { return pluginChain.size(); }
    AudioPluginInstance* getPlugin (int index);
    const PluginDescription* getPluginDescription (int index) const;
    
    // UI management
    void showPluginEditor (int index);
    void hidePluginEditor (int index);
    bool hasPluginEditor (int index) const;
    
    // State management
    void getStateInformation (MemoryBlock& destData);
    void setStateInformation (const void* data, int sizeInBytes);
    
    // Enable/disable plugin processing
    void setPluginBypassed (int index, bool shouldBeBypassed);
    bool isPluginBypassed (int index) const;
    
    // Component
    void resized() override;
    void paint (Graphics& g) override;
    
    // Timer
    void timerCallback() override;
    
    // ChangeListener
    void changeListenerCallback (ChangeBroadcaster* source) override;
    
    // Callbacks
    std::function<void()> onPluginListChanged;
    std::function<void(int, bool)> onPluginBypassed;
    
private:
    AudioPluginFormatManager formatManager;
    KnownPluginList knownPluginList;
    std::unique_ptr<AudioPluginDirectoryScanner> scanner;
    
    struct PluginInstance {
        std::unique_ptr<AudioPluginInstance> plugin;
        PluginDescription description;
        bool bypassed = false;
        std::unique_ptr<AudioProcessorEditor> editor;
    };
    
    OwnedArray<PluginInstance> pluginChain;
    
    double currentSampleRate = 44100.0;
    int currentBufferSize = 512;
    bool prepared = false;
    
    // Temporary buffers for plugin processing
    AudioBuffer<float> tempBuffer;
    
    void initializeFormatManager();
    void saveKnownPluginList();
    void loadKnownPluginList();
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (PluginHostManager)
};
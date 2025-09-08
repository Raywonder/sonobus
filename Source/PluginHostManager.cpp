// SPDX-License-Identifier: GPLv3-or-later WITH Appstore-exception
// Copyright (C) 2020 Jesse Chappell

#include "PluginHostManager.h"

PluginHostManager::PluginHostManager()
{
    initializeFormatManager();
    loadKnownPluginList();
    
    // Start timer for plugin scanning and editor updates
    startTimer (100);
}

PluginHostManager::~PluginHostManager()
{
    stopTimer();
    clearAllPlugins();
    saveKnownPluginList();
}

void PluginHostManager::initializeFormatManager()
{
    formatManager.addDefaultFormats();
    
#if JUCE_PLUGINHOST_VST3
    formatManager.addFormat (new VST3PluginFormat());
#endif
    
#if JUCE_PLUGINHOST_VST && JUCE_PLUGINHOST_VST_LEGACY
    formatManager.addFormat (new VSTPluginFormat());
#endif
    
#if JUCE_PLUGINHOST_AU && JUCE_MAC
    formatManager.addFormat (new AudioUnitPluginFormat());
#endif
}

void PluginHostManager::scanForPlugins()
{
    if (scanner != nullptr)
        return; // Already scanning
        
    auto& fileSearchPaths = formatManager.getDefaultLocationsToSearch();
    
    scanner = std::make_unique<AudioPluginDirectoryScanner> (knownPluginList,
                                                            formatManager,
                                                            fileSearchPaths,
                                                            true,
                                                            File());
    
    scanner->setFiltersToUse (AudioPluginDirectoryScanner::FilterType::all);
    
    // Start scanning in background thread
    Thread::launch ([this]() {
        String pluginBeingScanned;
        
        while (scanner->scanNextFile (true, pluginBeingScanned))
        {
            DBG ("Scanning: " + pluginBeingScanned);
            
            if (Thread::currentThreadShouldExit())
                break;
        }
        
        scanner.reset();
        
        MessageManager::callAsync ([this]() {
            if (onPluginListChanged)
                onPluginListChanged();
        });
    });
}

void PluginHostManager::loadPlugin (const PluginDescription& desc)
{
    String errorMessage;
    
    if (auto instance = formatManager.createPluginInstance (desc, currentSampleRate, currentBufferSize, errorMessage))
    {
        auto pluginInstance = new PluginInstance();
        pluginInstance->plugin = std::unique_ptr<AudioPluginInstance> (instance);
        pluginInstance->description = desc;
        
        if (prepared)
        {
            pluginInstance->plugin->prepareToPlay (currentSampleRate, currentBufferSize);
        }
        
        pluginChain.add (pluginInstance);
        
        if (onPluginListChanged)
            onPluginListChanged();
    }
    else
    {
        DBG ("Failed to load plugin: " + desc.name + " - " + errorMessage);
    }
}

void PluginHostManager::removePlugin (int index)
{
    if (isPositiveAndBelow (index, pluginChain.size()))
    {
        pluginChain.remove (index);
        
        if (onPluginListChanged)
            onPluginListChanged();
    }
}

void PluginHostManager::clearAllPlugins()
{
    pluginChain.clear();
    
    if (onPluginListChanged)
        onPluginListChanged();
}

void PluginHostManager::prepareToPlay (double sampleRate, int maximumExpectedSamplesPerBlock)
{
    currentSampleRate = sampleRate;
    currentBufferSize = maximumExpectedSamplesPerBlock;
    prepared = true;
    
    // Prepare temporary buffer
    tempBuffer.setSize (2, maximumExpectedSamplesPerBlock);
    
    // Prepare all loaded plugins
    for (auto* pluginInstance : pluginChain)
    {
        if (pluginInstance->plugin)
        {
            pluginInstance->plugin->prepareToPlay (sampleRate, maximumExpectedSamplesPerBlock);
        }
    }
}

void PluginHostManager::processBlock (AudioBuffer<float>& buffer, MidiBuffer& midiMessages)
{
    if (!prepared)
        return;
        
    const int numSamples = buffer.getNumSamples();
    const int numChannels = buffer.getNumChannels();
    
    // Process through plugin chain
    for (auto* pluginInstance : pluginChain)
    {
        if (pluginInstance->plugin && !pluginInstance->bypassed)
        {
            auto* plugin = pluginInstance->plugin.get();
            
            // Ensure plugin has correct channel configuration
            auto pluginInputs = plugin->getBusCount (true);
            auto pluginOutputs = plugin->getBusCount (false);
            
            if (pluginInputs > 0 && pluginOutputs > 0)
            {
                // Create appropriate buffer for plugin
                tempBuffer.setSize (jmax (numChannels, plugin->getTotalNumInputChannels()), numSamples);
                
                // Copy input to temp buffer
                for (int ch = 0; ch < numChannels; ++ch)
                {
                    tempBuffer.copyFrom (ch, 0, buffer, ch, 0, numSamples);
                }
                
                // Clear any extra channels
                for (int ch = numChannels; ch < tempBuffer.getNumChannels(); ++ch)
                {
                    tempBuffer.clear (ch, 0, numSamples);
                }
                
                // Process through plugin
                plugin->processBlock (tempBuffer, midiMessages);
                
                // Copy processed audio back to main buffer
                for (int ch = 0; ch < numChannels; ++ch)
                {
                    buffer.copyFrom (ch, 0, tempBuffer, ch, 0, numSamples);
                }
            }
        }
    }
}

void PluginHostManager::releaseResources()
{
    for (auto* pluginInstance : pluginChain)
    {
        if (pluginInstance->plugin)
        {
            pluginInstance->plugin->releaseResources();
        }
    }
    
    prepared = false;
}

AudioPluginInstance* PluginHostManager::getPlugin (int index)
{
    if (isPositiveAndBelow (index, pluginChain.size()))
    {
        return pluginChain[index]->plugin.get();
    }
    
    return nullptr;
}

const PluginDescription* PluginHostManager::getPluginDescription (int index) const
{
    if (isPositiveAndBelow (index, pluginChain.size()))
    {
        return &pluginChain[index]->description;
    }
    
    return nullptr;
}

void PluginHostManager::showPluginEditor (int index)
{
    if (auto* pluginInstance = pluginChain[index])
    {
        if (pluginInstance->plugin && pluginInstance->plugin->hasEditor())
        {
            if (!pluginInstance->editor)
            {
                pluginInstance->editor = std::unique_ptr<AudioProcessorEditor> (pluginInstance->plugin->createEditor());
                
                if (pluginInstance->editor)
                {
                    addAndMakeVisible (pluginInstance->editor.get());
                }
            }
            
            if (pluginInstance->editor)
            {
                pluginInstance->editor->setVisible (true);
                pluginInstance->editor->toFront (false);
            }
        }
    }
}

void PluginHostManager::hidePluginEditor (int index)
{
    if (auto* pluginInstance = pluginChain[index])
    {
        if (pluginInstance->editor)
        {
            pluginInstance->editor->setVisible (false);
        }
    }
}

bool PluginHostManager::hasPluginEditor (int index) const
{
    if (auto* pluginInstance = pluginChain[index])
    {
        return pluginInstance->plugin && pluginInstance->plugin->hasEditor();
    }
    
    return false;
}

void PluginHostManager::setPluginBypassed (int index, bool shouldBeBypassed)
{
    if (auto* pluginInstance = pluginChain[index])
    {
        pluginInstance->bypassed = shouldBeBypassed;
        
        if (onPluginBypassed)
            onPluginBypassed (index, shouldBeBypassed);
    }
}

bool PluginHostManager::isPluginBypassed (int index) const
{
    if (auto* pluginInstance = pluginChain[index])
    {
        return pluginInstance->bypassed;
    }
    
    return false;
}

void PluginHostManager::getStateInformation (MemoryBlock& destData)
{
    XmlElement xml ("PluginHostManager");
    
    for (int i = 0; i < pluginChain.size(); ++i)
    {
        auto* pluginInstance = pluginChain[i];
        auto* pluginXml = xml.createNewChildElement ("Plugin");
        
        pluginXml->setAttribute ("index", i);
        pluginXml->setAttribute ("bypassed", pluginInstance->bypassed);
        
        // Save plugin description
        auto* descXml = pluginXml->createNewChildElement ("PluginDescription");
        pluginInstance->description.writeXml (*descXml);
        
        // Save plugin state
        if (pluginInstance->plugin)
        {
            MemoryBlock pluginState;
            pluginInstance->plugin->getStateInformation (pluginState);
            
            if (pluginState.getSize() > 0)
            {
                auto* stateXml = pluginXml->createNewChildElement ("PluginState");
                stateXml->addTextElement (pluginState.toBase64Encoding());
            }
        }
    }
    
    copyXmlToBinary (xml, destData);
}

void PluginHostManager::setStateInformation (const void* data, int sizeInBytes)
{
    clearAllPlugins();
    
    if (auto xml = getXmlFromBinary (data, sizeInBytes))
    {
        forEachXmlChildElement (*xml, pluginXml)
        {
            if (pluginXml->hasTagName ("Plugin"))
            {
                auto index = pluginXml->getIntAttribute ("index");
                auto bypassed = pluginXml->getBoolAttribute ("bypassed");
                
                // Load plugin description
                if (auto* descXml = pluginXml->getChildByName ("PluginDescription"))
                {
                    PluginDescription desc;
                    if (desc.loadFromXml (*descXml))
                    {
                        loadPlugin (desc);
                        
                        // Restore bypass state
                        if (index < pluginChain.size())
                        {
                            setPluginBypassed (index, bypassed);
                        }
                        
                        // Restore plugin state
                        if (auto* stateXml = pluginXml->getChildByName ("PluginState"))
                        {
                            if (index < pluginChain.size() && pluginChain[index]->plugin)
                            {
                                MemoryBlock pluginState;
                                if (pluginState.fromBase64Encoding (stateXml->getAllSubText()))
                                {
                                    pluginChain[index]->plugin->setStateInformation (pluginState.getData(), 
                                                                                   (int) pluginState.getSize());
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

void PluginHostManager::resized()
{
    // Layout plugin editors if needed
    auto bounds = getLocalBounds();
    
    for (auto* pluginInstance : pluginChain)
    {
        if (pluginInstance->editor && pluginInstance->editor->isVisible())
        {
            pluginInstance->editor->setBounds (bounds);
        }
    }
}

void PluginHostManager::paint (Graphics& g)
{
    g.fillAll (findColour (ResizableWindow::backgroundColourId));
}

void PluginHostManager::timerCallback()
{
    // Update plugin editors and handle any background tasks
    for (auto* pluginInstance : pluginChain)
    {
        if (pluginInstance->editor && pluginInstance->editor->isVisible())
        {
            pluginInstance->editor->repaint();
        }
    }
}

void PluginHostManager::changeListenerCallback (ChangeBroadcaster* source)
{
    // Handle format manager or plugin list changes
}

void PluginHostManager::saveKnownPluginList()
{
    auto appDataDir = File::getSpecialLocation (File::userApplicationDataDirectory)
                         .getChildFile ("SonoBus");
    
    if (!appDataDir.exists())
        appDataDir.createDirectory();
        
    auto pluginListFile = appDataDir.getChildFile ("PluginList.xml");
    knownPluginList.writeToXmlFile (pluginListFile);
}

void PluginHostManager::loadKnownPluginList()
{
    auto appDataDir = File::getSpecialLocation (File::userApplicationDataDirectory)
                         .getChildFile ("SonoBus");
    
    auto pluginListFile = appDataDir.getChildFile ("PluginList.xml");
    
    if (pluginListFile.existsAsFile())
    {
        knownPluginList.readFromXmlFile (pluginListFile);
    }
}
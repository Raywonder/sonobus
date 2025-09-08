// SPDX-License-Identifier: GPLv3-or-later WITH Appstore-exception
// Copyright (C) 2020 Jesse Chappell


#include "CrossPlatformUtils.h"

#include "../JuceLibraryCode/JuceHeader.h"

#if JUCE_LINUX


void getSafeAreaInsets(void * component, float & top, float & bottom, float & left, float & right)
{
    top = bottom = left = right = 0;
}

#endif

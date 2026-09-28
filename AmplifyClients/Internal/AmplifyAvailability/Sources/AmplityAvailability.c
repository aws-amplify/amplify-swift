//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#include "include/AmplifyAvailability.h"
#include <Availability.h>

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
int getIOSVersionMinRequired(void) {
    return __IPHONE_OS_VERSION_MIN_REQUIRED;
}
#endif

#if TARGET_OS_OSX
int getMACOSXVersionMinRequired(void) {
    return __MAC_OS_X_VERSION_MIN_REQUIRED;
}
#endif

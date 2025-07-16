//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#ifndef AmplifyAvailability_h
#define AmplifyAvailability_h

#include <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
int getIOSVersionMinRequired(void);
#endif

#if TARGET_OS_OSX
int getMACOSXVersionMinRequired(void);
#endif

#endif /* AmplifyAvailability_h */

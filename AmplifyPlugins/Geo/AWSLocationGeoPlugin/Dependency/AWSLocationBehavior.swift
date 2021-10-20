//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

#if COCOAPODS
import AWSLocation
#else
import AWSLocationXCF
#endif

/// Behavior that `AWSLocationAdapter` will use.
/// This protocol allows a way to create a Mock and ensure the plugin implementation is testable.
protocol AWSLocationBehavior {

    // Get the lower level `AWSLocation` client.
    func getEscapeHatch() -> AWSLocation

    func searchPlaceIndex(forText: AWSLocationSearchPlaceIndexForTextRequest,
                          completionHandler: ((AWSLocationSearchPlaceIndexForTextResponse?,
                                               Error?) -> Void)?)

    func searchPlaceIndex(forPosition: AWSLocationSearchPlaceIndexForPositionRequest,
                          completionHandler: ((AWSLocationSearchPlaceIndexForPositionResponse?,
                                               Error?) -> Void)?)
}

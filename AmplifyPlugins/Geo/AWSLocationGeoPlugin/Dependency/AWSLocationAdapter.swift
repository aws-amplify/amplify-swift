//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSPluginsCore
import Foundation

#if COCOAPODS
import AWSLocation
#else
import AWSLocationXCF
#endif

/// Conforms to AWSLocationBehavior which uses an instance of the AWSLocation to perform its methods.
///
/// This class acts as a wrapper to expose AWSLocation functionality through an instance over a singleton,
/// and allows for mocking in unit tests. The methods contain no other logic other than calling the
/// same method using the AWSLocation instance.
class AWSLocationAdapter: AWSLocationBehavior {

    /// Underlying AWSLocation service client instance.
    let location: AWSLocation

    /// Initializer
    /// - Parameter location: AWSLocation instance to use.
    init(location: AWSLocation) {
        self.location = location
    }

    /// Provides access to the underlying AWSLocation service client.
    /// - Returns: AWSLocation service client instance.
    func getEscapeHatch() -> AWSLocation {
        location
    }

    func searchPlaceIndex(forText: AWSLocationSearchPlaceIndexForTextRequest,
                          completionHandler: ((AWSLocationSearchPlaceIndexForTextResponse?,
                                                         Error?) -> Void)?) {
        location.searchPlaceIndex(forText: forText, completionHandler: completionHandler)
    }

    func searchPlaceIndex(forPosition: AWSLocationSearchPlaceIndexForPositionRequest,
                          completionHandler: ((AWSLocationSearchPlaceIndexForPositionResponse?,
                                                         Error?) -> Void)?) {
        location.searchPlaceIndex(forPosition: forPosition, completionHandler: completionHandler)
    }
}

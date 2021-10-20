//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSLocation
@testable import AWSLocationGeoPlugin
import Foundation

extension MockAWSLocation {

    public func searchPlaceIndex(forText: AWSLocationSearchPlaceIndexForTextRequest,
                                 completionHandler: ((AWSLocationSearchPlaceIndexForTextResponse?,
                                                      Error?) -> Void)?) {
        searchPlaceIndexForTextCalled += 1
        searchPlaceIndexForTextRequest = forText
        if let completionHandler = completionHandler {
            completionHandler(AWSLocationSearchPlaceIndexForTextResponse(), nil)
        }
    }

    public func searchPlaceIndex(forPosition: AWSLocationSearchPlaceIndexForPositionRequest,
                                 completionHandler: ((AWSLocationSearchPlaceIndexForPositionResponse?,
                                                      Error?) -> Void)?) {
        searchPlaceIndexForPositionCalled += 1
        searchPlaceIndexForPositionRequest = forPosition
        if let completionHandler = completionHandler {
            completionHandler(AWSLocationSearchPlaceIndexForPositionResponse(), nil)
        }
    }
}

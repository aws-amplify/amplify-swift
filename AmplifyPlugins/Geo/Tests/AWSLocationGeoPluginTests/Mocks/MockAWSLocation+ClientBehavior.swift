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

    public func searchPlaceIndex(forText: SearchPlaceIndexForTextInput,
                                 completionHandler: ((SearchPlaceIndexForTextOutputResponse?,
                                                      Error?) -> Void)?) {
        searchPlaceIndexForTextCalled += 1
        searchPlaceIndexForTextRequest = forText
        if let completionHandler = completionHandler {
            completionHandler(SearchPlaceIndexForTextOutputResponse(), nil)
        }
    }

    public func searchPlaceIndex(forPosition: SearchPlaceIndexForPositionInput,
                                 completionHandler: ((SearchPlaceIndexForPositionOutputResponse?,
                                                      Error?) -> Void)?) {
        searchPlaceIndexForPositionCalled += 1
        searchPlaceIndexForPositionRequest = forPosition
        if let completionHandler = completionHandler {
            completionHandler(SearchPlaceIndexForPositionOutputResponse(), nil)
        }
    }

    public func searchPlaceIndex(forText: SearchPlaceIndexForTextInput) async throws -> SearchPlaceIndexForTextOutputResponse {
        searchPlaceIndexForTextCalled += 1
        searchPlaceIndexForTextRequest = forText
        return SearchPlaceIndexForTextOutputResponse()
    }

    public func searchPlaceIndex(forPosition: SearchPlaceIndexForPositionInput) async throws -> SearchPlaceIndexForPositionOutputResponse {
        searchPlaceIndexForPositionCalled += 1
        searchPlaceIndexForPositionRequest = forPosition
        return SearchPlaceIndexForPositionOutputResponse()

    }
}

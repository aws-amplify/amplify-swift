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
                                 completionHandler: ((SearchPlaceIndexForTextOutput?,
                                                      Error?) -> Void)?) {
        searchPlaceIndexForTextCalled += 1
        searchPlaceIndexForTextRequest = forText
        if let completionHandler = completionHandler {
            completionHandler(SearchPlaceIndexForTextOutput(), nil)
        }
    }

    public func searchPlaceIndex(forPosition: SearchPlaceIndexForPositionInput,
                                 completionHandler: ((SearchPlaceIndexForPositionOutput?,
                                                      Error?) -> Void)?) {
        searchPlaceIndexForPositionCalled += 1
        searchPlaceIndexForPositionRequest = forPosition
        if let completionHandler = completionHandler {
            completionHandler(SearchPlaceIndexForPositionOutput(), nil)
        }
    }

    public func searchPlaceIndex(forText: SearchPlaceIndexForTextInput) async throws -> SearchPlaceIndexForTextOutput {
        searchPlaceIndexForTextCalled += 1
        searchPlaceIndexForTextRequest = forText
        return SearchPlaceIndexForTextOutput()
    }

    public func searchPlaceIndex(forPosition: SearchPlaceIndexForPositionInput) async throws -> SearchPlaceIndexForPositionOutput {
        searchPlaceIndexForPositionCalled += 1
        searchPlaceIndexForPositionRequest = forPosition
        return SearchPlaceIndexForPositionOutput()

    }
}

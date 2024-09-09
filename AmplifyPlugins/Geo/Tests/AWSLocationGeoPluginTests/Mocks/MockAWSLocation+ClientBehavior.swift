//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSLocation
import Foundation
@testable import AWSLocationGeoPlugin

public extension MockAWSLocation {

    func searchPlaceIndex(
        forText: SearchPlaceIndexForTextInput,
        completionHandler: ((
            SearchPlaceIndexForTextOutput?,
            Error?
        ) -> Void)?
    ) {
        searchPlaceIndexForTextCalled += 1
        searchPlaceIndexForTextRequest = forText
        if let completionHandler {
            completionHandler(SearchPlaceIndexForTextOutput(), nil)
        }
    }

    func searchPlaceIndex(
        forPosition: SearchPlaceIndexForPositionInput,
        completionHandler: ((
            SearchPlaceIndexForPositionOutput?,
            Error?
        ) -> Void)?
    ) {
        searchPlaceIndexForPositionCalled += 1
        searchPlaceIndexForPositionRequest = forPosition
        if let completionHandler {
            completionHandler(SearchPlaceIndexForPositionOutput(), nil)
        }
    }

    func searchPlaceIndex(forText: SearchPlaceIndexForTextInput) async throws -> SearchPlaceIndexForTextOutput {
        searchPlaceIndexForTextCalled += 1
        searchPlaceIndexForTextRequest = forText
        return SearchPlaceIndexForTextOutput()
    }

    func searchPlaceIndex(forPosition: SearchPlaceIndexForPositionInput) async throws -> SearchPlaceIndexForPositionOutput {
        searchPlaceIndexForPositionCalled += 1
        searchPlaceIndexForPositionRequest = forPosition
        return SearchPlaceIndexForPositionOutput()

    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSLocation

/// Behavior that `AWSLocationAdapter` will use.
/// This protocol allows a way to create a Mock and ensure the plugin implementation is testable.
protocol AWSLocationBehavior {

    // Get the lower level `AWSLocation` client.
    func getEscapeHatch() -> LocationClient

    func searchPlaceIndex(forText: SearchPlaceIndexForTextInput)
            async throws -> SearchPlaceIndexForTextOutputResponse

        func searchPlaceIndex(forPosition: SearchPlaceIndexForPositionInput)
            async throws -> SearchPlaceIndexForPositionOutputResponse
}

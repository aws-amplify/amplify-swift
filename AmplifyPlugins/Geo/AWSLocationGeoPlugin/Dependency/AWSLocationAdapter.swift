//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

import AWSLocation

/// Conforms to AWSLocationBehavior which uses an instance of the AWSLocation to perform its methods.
///
/// This class acts as a wrapper to expose AWSLocation functionality through an instance over a singleton,
/// and allows for mocking in unit tests. The methods contain no other logic other than calling the
/// same method using the AWSLocation instance.
class AWSLocationAdapter: AWSLocationBehavior {

    /// Underlying AWSLocation service client instance.
    let location: LocationClient

    /// Initializer
    /// - Parameter location: AWSLocation instance to use.
    init(location: LocationClient) {
        self.location = location
    }

    /// Provides access to the underlying AWSLocation service client.
    /// - Returns: AWSLocation service client instance.
    func getEscapeHatch() -> LocationClient {
        location
    }

    func searchPlaceIndex(forText: SearchPlaceIndexForTextInput) async throws -> SearchPlaceIndexForTextOutputResponse {
        return try await location.searchPlaceIndexForText(input: forText)
    }

    func searchPlaceIndex(forPosition: SearchPlaceIndexForPositionInput) async throws -> SearchPlaceIndexForPositionOutputResponse {
        return try await location.searchPlaceIndexForPosition(input: forPosition)
    }
    
    public func updateLocation(forUpdateDevicePosition: BatchUpdateDevicePositionInput) async throws -> BatchUpdateDevicePositionOutputResponse {
        return try await location.batchUpdateDevicePosition(input: forUpdateDevicePosition)
    }
    
    public func deleteLocationHistory(forPositionHistory: BatchDeleteDevicePositionHistoryInput) async throws -> BatchDeleteDevicePositionHistoryOutputResponse {
        return try await location.batchDeleteDevicePositionHistory(input: forPositionHistory)
    }
}

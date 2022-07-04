//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

/// Groups the `PinpointClientProtocol` instances used for Analytics and Targeting
public struct AWSPinpoint {
    let analyticsClient: PinpointClientProtocol
    let targetingClient: PinpointClientProtocol
}

/// Implemented by `PinpointContext` as a pass through to the methods on `analyticClient` and `endpointClient`.
/// This protocol allows a way to create a Mock and ensure plugin implementation is testable.
protocol AWSPinpointBehavior {
    //MARK: Escape hatch
    /// Returns the low-level `PinpointClientProcotol` clients used to interact with AWS Pinpoint for Analytics and Targeting.
    /// - Returns:A `AWSPinpoint` containing the the lower level clients.
    func getEscapeHatch() -> AWSPinpoint

    //MARK: Analytics
    /// Creates a `PinpointEvent` with the specificed eventType
    /// - Parameter eventType: The `PinpointEvent` to create
    /// - Returns: A new PinpointEvent with the specified event type
    func createEvent(withEventType eventType: String) -> PinpointEvent

    /// Adds the specified property to all subsequent recorded events.
    /// - Parameter value:The value of the property
    /// - Parameter key: The name of the property
    func addGlobalProperty(withValue value: AnalyticsPropertyValue, forKey key: String)

    /// Removes the specified property. All subsequent recorded events will no longer have this global property.
    /// - Parameter value:The value of the property
    /// - Parameter key: The name of the property
    func removeGlobalProperty(withValue value: AnalyticsPropertyValue, forKey key: String)

    /// Records the specified `PinpointEvent` to the local storage.
    /// - Parameter event: The `PinpointEvent` to persist
    func record(_ event: PinpointEvent) async throws

    /// Submits all recorded events to Pinpoint.
    /// Events are automatically submitted when the application goes into the background.
    /// - Returns: An array of successfully submitted events.
    @discardableResult func submitEvents() async throws -> [PinpointEvent]

    //MARK: Targeting
    /// Returns the current endpoint profile.
    /// - Returns:A `PinpointEndpointProfile`  representing the current endpoint.
    func currentEndpointProfile() async -> PinpointEndpointProfile

    /// Updates the current endpoint with the provided one
    /// - Parameter endpointProfile: The new endpoint profile
    func update(_ endpointProfile: PinpointEndpointProfile) async throws

}

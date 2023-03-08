//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

/// Implemented by `PinpointContext` as a pass through to the methods on `analyticClient` and `endpointClient`.
/// This protocol allows a way to create a Mock and ensure plugin implementation is testable.
@_spi(InternalAWSPinpoint)
public protocol AWSPinpointBehavior {
    // MARK: Escape hatch
    /// The low-level `PinpointClientProcotol` client used to interact with AWS Pinpoint for Analytics and Targeting.
    var pinpointClient: PinpointClientProtocol { get }

    // MARK: Analytics
    /// Creates a `PinpointEvent` with the specificed eventType
    /// - Parameter eventType: The `PinpointEvent` to create
    /// - Returns: A new PinpointEvent with the specified event type
    func createEvent(withEventType eventType: String) -> PinpointEvent

    /// Adds the specified property to all subsequent recorded events.
    /// - Parameter value:The value of the property
    /// - Parameter key: The name of the property
    func addGlobalProperty(_ value: AnalyticsPropertyValue, forKey key: String) async

    /// Removes the specified property. All subsequent recorded events will no longer have this global property.
    /// - Parameter value:The value of the property
    /// - Parameter key: The name of the property
    func removeGlobalProperty(_ value: AnalyticsPropertyValue, forKey key: String) async

    /// Adds the provided remote attributes to all subsequent recorded events.
    /// Calling this method will remove any previously set remote attributes.
    /// - Parameter attributes:The global attributes to set
    func setRemoteGlobalAttributes(_ attributes: [String: String]) async

    /// Records the specified `PinpointEvent` to the local storage.
    /// - Parameter event: The `PinpointEvent` to persist
    func record(_ event: PinpointEvent) async throws
    
    /// Sets the interval for the automatic submission of event. If set to `TimeInterval.zero`,
    /// the automatic submission is disabled
    /// - Parameter interval: How much to wait between submissions
    /// - Parameter onSubmit: An optional callback to be run after each submission happens
    func setAutomaticSubmitEventsInterval(_ interval: TimeInterval,
                                          onSubmit: AnalyticsClientBehaviour.SubmitResult?)
    
    // MARK: Session
    /// Beings automatically tracking session activity in the device.
    /// - Parameter backgroundTimeout: How much to wait after the device goes to the background before stopping the session
    func startTrackingSessions(backgroundTimeout: TimeInterval)
    
    /// Submits all recorded events to Pinpoint.
    /// Events are automatically submitted when the application goes into the background.
    /// - Returns: An array of successfully submitted events.
    @discardableResult func submitEvents() async throws -> [PinpointEvent]

    // MARK: Targeting
    /// Returns the current endpoint profile.
    /// - Returns:A `PinpointEndpointProfile`  representing the current endpoint.
    func currentEndpointProfile() async -> PinpointEndpointProfile

    /// Updates the current endpoint with the provided profile
    /// - Parameter endpointProfile: The new endpoint profile
    /// - Parameter source: The source that originates this endpoint update, i.e. analytics or pushNotifications
    func updateEndpoint(with endpointProfile: PinpointEndpointProfile,
                        source: AWSPinpointSource) async throws
}

@_spi(InternalAWSPinpoint)
public enum AWSPinpointSource: String {
    case analytics
    case pushNotifications
}

extension AWSPinpointBehavior {
    /// Sets the interval for the automatic submission of event. If set to `TimeInterval.zero`,
    /// the automatic submission is disabled
    /// - Parameter interval: How much to wait between submissions
    func setAutomaticSubmitEventsInterval(_ interval: TimeInterval) {
        setAutomaticSubmitEventsInterval(interval, onSubmit: nil)
    }
}

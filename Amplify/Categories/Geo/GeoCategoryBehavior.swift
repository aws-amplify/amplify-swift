//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Geo category that clients will use
public protocol GeoCategoryBehavior {

    // MARK: - Search

    /// Search for places or points of interest.
    /// - Parameters:
    ///   - text: The place name or address to be used in the search. (case insensitive)
    ///   - options: Optional parameters when searching for text.
    /// - Returns:
    ///     It returns a Geo.Place array.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    func search(for text: String,
                options: Geo.SearchForTextOptions?) async throws -> [Geo.Place]

    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - options: Optional parameters when searching for coordinates.
    /// - Returns:
    ///     It returns a Geo.Place array.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    func search(for coordinates: Geo.Coordinates,
                options: Geo.SearchForCoordinatesOptions?) async throws -> [Geo.Place]

    // MARK: - Maps

    /// Retrieves metadata for available Map resources.
    /// - Returns:
    ///     It returns an array of available Map resources.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    func availableMaps() async throws -> [Geo.MapStyle]

    /// Retrieves metadata for the default Map resource.
    /// - Returns:
    ///     It returns the default Map resource.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    func defaultMap() async throws -> Geo.MapStyle
    
    /// Update the location for this device.
    /// - Parameters:
    ///   - device: The device that this location update will be applied to.
    ///   - location: The location being updated for this device.
    ///   - options: Additional tracker and metadata associated with the operation
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    func updateLocation(
       _ location: Geo.Location,
       for device: @autoclosure () async throws -> Geo.Device,
       with options: Geo.UpdateLocationOptions
    ) async throws
    
    /// Delete the device location history for this device.
    ///
    /// - Important: This permanently deletes the location history for
    ///   the device remotely and locally (if applicable). This makes a best effort to
    ///   delete location history.
    /// - Parameters:
    ///   - device: The device that this delete request will be applied to.
    ///   - options: Additional tracker associated with the operation.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    func deleteLocationHistory(
       for device: @autoclosure () async throws -> Geo.Device,
       with options: Geo.DeleteLocationOptions
    ) async throws

    /// Start a new tracking session.
    ///
    ///
    /// Location update failures can be listened to on the Hub with SAVE_LOCATIONS_FAILED
    ///
    /// - Parameters:
    ///   - device: The device that this location update will be applied to.
    ///             Default value is `.autogenerated`.
    ///             If you choose to create your own `Device` with your own `Device.ID`,
    ///             you are responsible for ensuring tracker scoped randomness and that the ID doesn't include PII
    ///   - options: The `Geo.LocationManager.TrackingSessionOptions` struct that determines the tracking behavior
    ///              of this tracking session.
    func startTracking(
        for device: @autoclosure () async throws -> Geo.Device,
        with options: Geo.LocationManager.TrackingSessionOptions
     ) async throws
    
    /// Stop tracking an existing tracking session.
    /// Calling this without an existing tracking session does nothing.
    ///
    /// Important: This will save all batched location updates. Any failures
    /// will be published to the Hub.
    func stopTracking()
}

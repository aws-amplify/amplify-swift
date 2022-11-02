//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension GeoCategory: GeoCategoryBehavior {

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
    public func search(for text: String,
                       options: Geo.SearchForTextOptions? = nil) async throws -> [Geo.Place] {
            return try await plugin.search(for: text, options: options)
    }

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
    public func search(for coordinates: Geo.Coordinates,
                       options: Geo.SearchForCoordinatesOptions? = nil) async throws -> [Geo.Place] {
        return try await plugin.search(for: coordinates, options: options)
    }

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
    public func availableMaps() async throws -> [Geo.MapStyle] {
        return try await plugin.availableMaps()
    }

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
    public func defaultMap() async throws -> Geo.MapStyle {
        return try await plugin.defaultMap()
    }
    
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
    public func updateLocation(
       _ location: Geo.Location,
       for device: @autoclosure () async throws -> Geo.Device = try await .tiedToUser(),
       with options: Geo.UpdateLocationOptions = .init()
    ) async throws {
        try await plugin.updateLocation(location, for: await device(), with: options)
    }
    
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
    public func deleteLocationHistory(
       for device: @autoclosure () async throws -> Geo.Device = try await .tiedToUser(),
       with options: Geo.DeleteLocationOptions = .init()
    ) async throws {
        try await plugin.deleteLocationHistory(for: await device(), with: options)
    }
    
    /// Start a new tracking session.
    ///
    ///
    /// Location update failures can be listened to on the Hub with <event name>
    ///
    /// - Parameters:
    ///   - device: The device that this location update will be applied to.
    ///             If you choose to create your own `Device` with your own `Device.ID`,
    ///             you are responsible for ensuring tracker scoped randomness and that the ID doesn't include PII
    ///   - options: The `Geo.LocationManager.TrackingSessionOptions` struct that determines the tracking behavior
    ///              of this tracking session.
    public func startTracking(
        for device: @autoclosure () async throws -> Geo.Device = try await .tiedToUser(),
        with options: Geo.LocationManager.TrackingSessionOptions
    ) async throws {
        try await plugin.startTracking(for: await device(), with: options)
    }
    
    /// Stop tracking an existing tracking session.
    /// Calling this without an existing tracking session does nothing.
    ///
    /// Important: This will save all batched location updates. Any failures
    /// will be published to the Hub.
    public func stopTracking() {
        plugin.stopTracking()
    }
}

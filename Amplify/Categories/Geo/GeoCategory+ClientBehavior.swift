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
    
    /// Search for places or points of interest.
    /// - Parameters:
    ///   - text: The place name or address to be used in the search. (case insensitive)
    ///   - options: Optional parameters when searching for text.
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    @available(*, deprecated, message: """
    Use search(for text: String,
                options: Geo.SearchForTextOptions?) async throws -> [Geo.Place]
    """)
    public func search(for text: String,
                       options: Geo.SearchForTextOptions?,
                       completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {
        Task {
            do {
                let result = try await search(for: text, options: options)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! Geo.Error))
            }
        }
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
                       options: Geo.SearchForCoordinatesOptions?) async throws -> [Geo.Place] {
        return try await plugin.search(for: coordinates, options: options)
    }
    
    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - options: Optional parameters when searching for coorinates.
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    @available(*, deprecated, message: """
    Use search(for coordinates: Geo.Coordinates,
                options: Geo.SearchForCoordinatesOptions?) async throws -> [Geo.Place]
    """)
    public func search(for coordinates: Geo.Coordinates,
                       options: Geo.SearchForCoordinatesOptions?,
                       completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {
        Task {
            do {
                let result = try await search(for: coordinates, options: options)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! Geo.Error))
            }
        }
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
    
    /// Retrieves metadata for available Map resources.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides an array of available Map resources.
    @available(*, deprecated, message: "Use availableMaps() async throws -> [Geo.MapStyle]")
    public func availableMaps(completionHandler: @escaping Geo.ResultsHandler<[Geo.MapStyle]>) {
        Task {
            do {
                let result = try await availableMaps()
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! Geo.Error))
            }
        }
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
    
    /// Retrieves the default Map resource.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides the default Map resource.
    @available(*, deprecated, message: "Use defaultMap() async throws -> Geo.MapStyle")
    public func defaultMap(completionHandler: @escaping Geo.ResultsHandler<Geo.MapStyle>) {
        Task {
            do {
                let result = try await defaultMap()
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! Geo.Error))
            }
        }
    }
}

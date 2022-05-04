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
    func search(for text: String,
                options: Geo.SearchForTextOptions?) async throws -> [Geo.Place]

    
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
    func search(for text: String,
                options: Geo.SearchForTextOptions?,
                completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>)
    
    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - options: Optional parameters when searching for coordinates.
    /// - Returns:
    ///     It returns a Geo.Place array.
    func search(for coordinates: Geo.Coordinates,
                options: Geo.SearchForCoordinatesOptions?) async throws -> [Geo.Place]

    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - options: Optional parameters when searching for coordinates.
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    @available(*, deprecated, message: """
    Use search(for coordinates: Geo.Coordinates,
                options: Geo.SearchForCoordinatesOptions?) async throws -> [Geo.Place]
    """)
    func search(for coordinates: Geo.Coordinates,
                options: Geo.SearchForCoordinatesOptions?,
                completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>)
    
    // MARK: - Maps

    /// Retrieves metadata for available Map resources.
    /// - Returns:
    ///     It returns an array of available Map resources.
    func availableMaps() async throws -> [Geo.MapStyle]

    /// Retrieves metadata for available Map resources.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object. The success case provides an array of available Map resources.
    @available(*, deprecated, message: "Use availableMaps() async throws -> [Geo.MapStyle]")
    func availableMaps(completionHandler: @escaping Geo.ResultsHandler<[Geo.MapStyle]>)
    
    /// Retrieves metadata for the default Map resource.
    /// - Returns:
    ///     It returns the default Map resource.
    func defaultMap() async throws -> Geo.MapStyle
    
    /// Retrieves metadata for the default Map resource.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides the default Map resource.
    @available(*, deprecated, message: "Use defaultMap() async throws -> Geo.MapStyle")
    func defaultMap(completionHandler: @escaping Geo.ResultsHandler<Geo.MapStyle>)
}

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
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    public func search(for text: String,
                       options: Geo.SearchForTextOptions? = nil,
                       completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {
        plugin.search(for: text,
                      options: options,
                      completionHandler: completionHandler)
    }

    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - options: Optional parameters when searching for coorinates.
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    public func search(for coordinates: Geo.Coordinates,
                       options: Geo.SearchForCoordinatesOptions? = nil,
                       completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {
        plugin.search(for: coordinates,
                      options: options,
                      completionHandler: completionHandler)
    }

    // MARK: - Maps

    /// Retrieves metadata for available Map resources.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides an array of available Map resources.
    public func availableMaps(completionHandler: @escaping Geo.ResultsHandler<[Geo.MapStyle]>) {
        plugin.availableMaps(completionHandler: completionHandler)
    }

    /// Retrieves the default Map resource.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides the default Map resource.
    public func defaultMap(completionHandler: @escaping Geo.ResultsHandler<Geo.MapStyle>) {
        plugin.defaultMap(completionHandler: completionHandler)
    }
}

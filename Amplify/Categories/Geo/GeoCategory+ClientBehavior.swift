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
                       options: Geo.SearchForTextOptions,
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
                       options: Geo.SearchForCoordinatesOptions,
                       completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {
        plugin.search(for: coordinates,
                      options: options,
                      completionHandler: completionHandler)
    }

    // MARK: - Maps

    /// Retrieves metadata for available Map resources.
    /// - Returns: Metadata for all available map resources.
    public func getAvailableMaps() -> [Geo.MapStyle] {
        plugin.getAvailableMaps()
    }

    /// Retrieves the default Map resource.
    /// - Returns: Metadata for the default map resource.
    public func getDefaultMap() -> Geo.MapStyle? {
        plugin.getDefaultMap()
    }
}

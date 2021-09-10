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
    ///   - area: The area (.near or .boundingBox) for the search. (optional)
    ///   - countries: Limits the search to the given a list of countries/regions. Use
    ///   ISO-3166 3-digit country codes. (optional)
    ///   - maxResults: The maximum number of results returned per request. (optional,
    ///   default: 50)
    ///   - placeIndexName: The name of the Place Index to query. (optional, default: The
    ///   default Place Index in amplifyconfiguration.json)
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    public func search(for text: String,
                       area: SearchArea? = nil,
                       countries: [String]? = nil,
                       maxResults: Int? = nil,
                       placeIndexName: String? = nil,
                       completionHandler: @escaping GeoResultsHandler<[Place]>) {
        plugin.search(for: text,
                      area: area,
                      countries: countries,
                      maxResults: maxResults,
                      placeIndexName: placeIndexName,
                      completionHandler: completionHandler)
    }

    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - maxResults: The maximum number of results returned per request. (optional,
    ///   default: 50)
    ///   - placeIndexName: The name of the Place Index to query. (optional, default: The
    ///   default Place Index in amplifyconfiguration.json)
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    public func search(for coordinates: Coordinates,
                       maxResults: Int? = nil,
                       placeIndexName: String? = nil,
                       completionHandler: @escaping GeoResultsHandler<[Place]>) {
        plugin.search(for: coordinates,
                      maxResults: maxResults,
                      placeIndexName: placeIndexName,
                      completionHandler: completionHandler)
    }

    // MARK: - Maps

    /// Retrieves metadata for available Map resources.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides an array of available Map resources.
    public func getAvailableMaps() -> [MapStyle] {
        plugin.getAvailableMaps()
    }

    /// Retrieves the default Map resource (first map in amplifyconfiguration.json).
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides an array of available Map resources.
    public func getDefaultMap() -> MapStyle {
        plugin.getDefaultMap()
    }
}

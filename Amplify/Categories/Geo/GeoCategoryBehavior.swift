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
    ///   - area: The area (.near or .boundingBox) for the search. (optional)
    ///   - countries: Limits the search to the given a list of countries/regions. Use
    ///   ISO-3166 3-digit country codes. (optional)
    ///   - maxResults: The maximum number of results returned per request. (optional,
    ///   default: 50)
    ///   - placeIndexName: The name of the Place Index to query. (optional, default: The
    ///   default Place Index in amplifyconfiguration.json)
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    func search(for text: String, // swiftlint:disable:this function_parameter_count
                area: SearchArea?,
                countries: [String]?,
                maxResults: Int?,
                placeIndexName: String?,
                completionHandler: @escaping GeoResultsHandler<[Place]>)

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
    func search(for coordinates: Coordinates,
                maxResults: Int?,
                placeIndexName: String?,
                completionHandler: @escaping GeoResultsHandler<[Place]>)

    // MARK: - Maps

    /// Retrieves metadata for available Map resources.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides an array of available Map resources.
    func getAvailableMaps() -> [MapStyle]

    /// Retrieves the default Map resource (first map in amplifyconfiguration.json).
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides an array of available Map resources.
    func getDefaultMap() -> MapStyle
}

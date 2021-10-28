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
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    func search(for text: String,
                options: Geo.SearchForTextOptions?,
                completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>)

    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - options: Optional parameters when searching for coordinates.
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    func search(for coordinates: Geo.Coordinates,
                options: Geo.SearchForCoordinatesOptions?,
                completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>)

    // MARK: - Maps

    /// Retrieves metadata for available Map resources.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object. The success case provides an array of available Map resources.
    func availableMaps(completionHandler: @escaping Geo.ResultsHandler<[Geo.MapStyle]>)

    /// Retrieves metadata for the default Map resource.
    /// - Parameter completionHandler: The completion handler receives a Response
    /// object.  The success case provides the default Map resource.
    func defaultMap(completionHandler: @escaping Geo.ResultsHandler<Geo.MapStyle>)
}

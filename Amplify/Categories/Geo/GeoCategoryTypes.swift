//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation

/// Results handler for Amplify Geo.
public typealias GeoResultsHandler<T> = (Result<T, Error>) -> Void

/// A pair of coordinates to represent a location (point).
public struct Coordinates {
    /// The latitude of the location.
    public let latitude: Double
    /// The longitude of the location.
    public let longitude: Double

    /// Initializer
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public extension Coordinates {
    /// Initialize a Location from a CLLocationCoordinate2D
    /// - Parameter location: The CLLocationCoordinate2D to use to initialize the
    /// Location.
    init(_ coordinates: CLLocationCoordinate2D) {
        self.init(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}

public extension CLLocationCoordinate2D {
    /// Initialize a Location from a CLLocationCoordinate2D
    /// - Parameter location: The CLLocationCoordinate2D to use to initialize the
    /// Location.
    init(_ coordinates: Coordinates) {
        self.init(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}

/// A bounding box defined by southwest and northeast corners.
public struct BoundingBox {
    /// The southwest corner of the bounding box.
    public let southwest: Coordinates
    /// The northeast corner of the bounding box.
    public let northeast: Coordinates

    /// Initializer
    public init(southwest: Coordinates, northeast: Coordinates) {
        self.southwest = southwest
        self.northeast = northeast
    }
}

/// The area to search.
public enum SearchArea {
    /// Searches for results closest to the given coordinates.
    case near(Coordinates)
    /// Filters the results by returning only Places within the provided bounding box.
    case within(BoundingBox)
}

public extension SearchArea {
    /// Creates a SearchArea that returns results closest to the given
    /// CLLocationCoordinate2D.
    /// - Parameter coordinates: The coordinates for the search area.
    /// - Returns: The SearchArea.
    static func near(_ coordinates: CLLocationCoordinate2D) -> SearchArea {
        .near(Coordinates(coordinates))
    }
}

/// A place defined by a label, location (point), and optional additional locality
/// information.
public struct Place {
    /// The full name and address of the place.
    public let label: String?
    /// The coordinates of the place. (required)
    public let coordinates: Coordinates
    /// The numerical portion of the address of the place, such as a building number.
    public let addressNumber: String?
    /// The name for the street or road of the place. For example, Main Street.
    public let street: String?
    /// The name of the local area of the place, such as a city or town name. For example, Toronto.
    public let municipality: String?
    /// The name for the area or geographical division, such as a province or state
    /// name, of the place. For example, British Columbia.
    public let region: String?
    /// An area that's part of a larger region for the place.  For example, Metro Vancouver.
    public let subRegion: String?
    /// A group of numbers and letters in a country-specific format, which accompanies
    /// the address for the purpose of identifying the place.
    public let postalCode: String?
    /// The country of the place.  Specified using <a
    /// href="https://www.iso.org/iso-3166-country-codes.html">ISO 3166 3-digit
    /// country/region code. For example, CAN.
    public let country: String?

    /// Initializer
    public init(label: String?,
                coordinates: Coordinates,
                addressNumber: String?,
                street: String?,
                municipality: String?,
                region: String?,
                subRegion: String?,
                postalCode: String?,
                country: String?) {
        self.label = label
        self.coordinates = coordinates
        self.addressNumber = addressNumber
        self.street = street
        self.municipality = municipality
        self.region = region
        self.subRegion = subRegion
        self.postalCode = postalCode
        self.country = country
    }
}

/// Identifies the name and style for a map resource.
public struct MapStyle {
    /// The name of the map resource.
    public let mapName: String
    /// The map style selected from an available provider.
    public let style: String
    /// The URL to retrieve the style descriptor of the map resource.
    public let styleURL: URL

    /// Initializer
    public init(mapName: String, style: String, styleURL: URL) {
        self.mapName = mapName
        self.style = style
        self.styleURL = styleURL
    }
}

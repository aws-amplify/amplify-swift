//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct Place: Equatable, Decodable {
    var addressNumber: String?
    var categories: [String]?
    var country: String?
    /// This member is required.
    var geometry: PlaceGeometry?
    var interpolated: Bool?
    var label: String?
    var municipality: String?
    var neighborhood: String?
    var postalCode: String?
    var region: String?
    var street: String?
    var subRegion: String?
    var supplementalCategories: [String]?
    var timeZone: TimeZone?
    /// not returned for SearchPlaceIndexForPosition.
    var unitNumber: String?
    /// Returned only for a place index that uses Esri as a data provider.
    var unitType: String?

    enum CodingKeys: String, CodingKey {
        case addressNumber = "AddressNumber"
        case categories = "Categories"
        case country = "Country"
        case geometry = "Geometry"
        case interpolated = "Interpolated"
        case label = "Label"
        case municipality = "Municipality"
        case neighborhood = "Neighborhood"
        case postalCode = "PostalCode"
        case region = "Region"
        case street = "Street"
        case subRegion = "SubRegion"
        case supplementalCategories = "SupplementalCategories"
        case timeZone = "TimeZone"
        case unitNumber = "UnitNumber"
        case unitType = "UnitType"
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct SearchPlaceIndexForPositionInput: Equatable, Encodable {
    /// This member is required.
    var indexName: String?
    var key: String?
    var language: String?
    var maxResults: Int?
    /// This member is required.
    var position: [Double]?

    enum CodingKeys: String, CodingKey {
        case language = "Language"
        case maxResults = "MaxResults"
        case position = "Position"
    }
}

struct SearchForPositionResult: Equatable, Decodable {
    /// This member is required.
    var distance: Double?
    /// This member is required.
    var place: Place?
    var placeId: String?

    enum CodingKeys: String, CodingKey {
        case distance = "Distance"
        case place = "Place"
        case placeId = "PlaceId"
    }
}

struct SearchPlaceIndexForPositionSummary: Equatable, Decodable {
    /// This member is required.
    var dataSource: String?
    var language: String?
    var maxResults: Int?
    /// This member is required.
    var position: [Double]?

    enum CodingKeys: String, CodingKey {
        case dataSource = "DataSource"
        case language = "Language"
        case maxResults = "MaxResults"
        case position = "Position"
    }
}

struct SearchPlaceIndexForPositionOutputResponse: Equatable, Decodable {
    /// This member is required.
    var results: [SearchForPositionResult]?
    /// This member is required.
    var summary: SearchPlaceIndexForPositionSummary?

    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case summary = "Summary"
    }
}

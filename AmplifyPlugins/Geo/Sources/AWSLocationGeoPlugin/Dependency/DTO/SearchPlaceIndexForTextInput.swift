//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct SearchPlaceIndexForTextInput: Equatable, Encodable {
    var biasPosition: [Double]?
    var filterBBox: [Double]?
    var filterCategories: [String]?
    var filterCountries: [String]?
    var language: String?
    var maxResults: Int?
    /// This member is required.
    var text: String?

    // Request building
    var indexName: String?
    var key: String?

    enum CodingKeys: String, CodingKey {
        case biasPosition = "BiasPosition"
        case filterBBox = "FilterBBox"
        case filterCategories = "FilterCategories"
        case filterCountries = "FilterCountries"
        case language = "Language"
        case maxResults = "MaxResults"
        case text = "Text"
    }
}

struct SearchForTextResult: Equatable, Decodable {
    var distance: Double?
    /// This member is required.
    var place: Place?
    var placeId: String?
    var relevance: Double?

    enum CodingKeys: String, CodingKey {
        case distance = "Distance"
        case place = "Place"
        case placeId = "PlaceId"
        case relevance = "Relevance"
    }
}

struct SearchPlaceIndexForTextSummary: Equatable, Decodable {
    var biasPosition: [Double]?
    /// This member is required.
    var dataSource: String?
    var filterBBox: [Double]?
    var filterCategories: [String]?
    var filterCountries: [String]?
    var language: String?
    var maxResults: Int
    var resultBBox: [Double]?
    /// This member is required.
    var text: String?

    enum CodingKeys: String, CodingKey {
        case biasPosition = "BiasPosition"
        case dataSource = "DataSource"
        case filterBBox = "FilterBBox"
        case filterCategories = "FilterCategories"
        case filterCountries = "FilterCountries"
        case language = "Language"
        case maxResults = "MaxResults"
        case resultBBox = "ResultBBox"
        case text = "Text"
    }
}

struct SearchPlaceIndexForTextOutputResponse: Equatable, Decodable {
    /// This member is required.
    var results: [SearchForTextResult]?
    /// This member is required.
    var summary: SearchPlaceIndexForTextSummary?

    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case summary = "Summary"
    }
}

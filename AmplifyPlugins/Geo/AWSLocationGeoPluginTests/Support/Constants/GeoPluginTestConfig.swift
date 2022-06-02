//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@testable import AWSLocationGeoPlugin

struct GeoPluginTestConfig {
    static let timeout = 1.0

    // Plugin Test Configuration
    static let regionName = "us-east-2"

    // Map Test Configuration
    static let map = "testMap"
    static let style = "VectorEsriStreets"
    static let url = URL(string: "https://maps.geo.\(regionName).amazonaws.com/maps/v0/maps/\(map)/style-descriptor")!
    static let mapStyle = Geo.MapStyle(mapName: map, style: style, styleURL: url)
    static let maps = [map: mapStyle]

    // Search Test Configuration
    static let searchIndex = "testSearchIndex"
    static let searchIndices = [searchIndex]

    // MARK: - Maps Config JSON
    static let mapStyleJSON = JSONValue(stringLiteral: style)
    static let testMapJSON = JSONValue(stringLiteral: map)

    static let mapStyleConfigJSON = JSONValue(dictionaryLiteral:
        (AWSLocationGeoPluginConfiguration.Node.style.key, mapStyleJSON))

    static let mapItemConfigJSON = JSONValue(dictionaryLiteral: (map, mapStyleConfigJSON))

    static let mapsConfigJSON = JSONValue(dictionaryLiteral:
        (AWSLocationGeoPluginConfiguration.Node.items.key, mapItemConfigJSON),
        (AWSLocationGeoPluginConfiguration.Node.default.key, testMapJSON))

    // MARK: - Search Config JSON
    static let searchIndexJSON = JSONValue(stringLiteral: searchIndex)
    static let searchItemsArrayJSON = JSONValue(arrayLiteral: searchIndexJSON)

    static let searchConfigJSON = JSONValue(dictionaryLiteral:
        (AWSLocationGeoPluginConfiguration.Node.items.key, searchItemsArrayJSON),
        (AWSLocationGeoPluginConfiguration.Node.default.key, searchIndexJSON))

    // MARK: - Plugin Config JSON

    static let regionJSON = JSONValue(stringLiteral: regionName)

    static let geoPluginConfigJSON = JSONValue(dictionaryLiteral:
        (AWSLocationGeoPluginConfiguration.Node.region.key, regionJSON),
        (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
        (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, searchConfigJSON))
}

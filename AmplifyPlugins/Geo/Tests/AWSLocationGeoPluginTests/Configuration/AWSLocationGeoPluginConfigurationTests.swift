//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSLocationGeoPlugin

class AWSLocationGeoPluginConfigurationTests: XCTestCase {

    func testConfigureSuccessAll() throws {
        do {
            let config = try AWSLocationGeoPluginConfiguration(config: GeoPluginTestConfig.geoPluginConfigJSON)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.regionName, GeoPluginTestConfig.regionName)
            XCTAssertEqual(config.maps, GeoPluginTestConfig.maps)
            XCTAssertEqual(config.defaultMap, GeoPluginTestConfig.map)
            XCTAssertEqual(config.searchIndices, GeoPluginTestConfig.searchIndices)
            XCTAssertEqual(config.defaultSearchIndex, GeoPluginTestConfig.searchIndex)
        } catch {
            XCTFail("Failed to instantiate geo plugin configuration")
        }
    }

    func testConfigureSuccessEmpty() throws {
        let geoPluginConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON))

        do {
            let config = try AWSLocationGeoPluginConfiguration(config: geoPluginConfigJSON)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.regionName, GeoPluginTestConfig.regionName)
            XCTAssertTrue(config.maps.isEmpty)
            XCTAssertNil(config.defaultMap)
            XCTAssertTrue(config.searchIndices.isEmpty)
            XCTAssertNil(config.defaultSearchIndex)
        } catch {
            XCTFail("Failed to instantiate geo plugin configuration")
        }
    }

    func testConfigureSuccessOnlyMaps() throws {
        let geoPluginConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
            (AWSLocationGeoPluginConfiguration.Section.maps.key, GeoPluginTestConfig.mapsConfigJSON))

        do {
            let config = try AWSLocationGeoPluginConfiguration(config: geoPluginConfigJSON)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.regionName, GeoPluginTestConfig.regionName)
            XCTAssertEqual(config.maps, GeoPluginTestConfig.maps)
            XCTAssertEqual(config.defaultMap, GeoPluginTestConfig.map)
            XCTAssertTrue(config.searchIndices.isEmpty)
            XCTAssertNil(config.defaultSearchIndex)
        } catch {
            XCTFail("Failed to instantiate geo plugin configuration")
        }
    }

    func testConfigureSuccessOnlySearch() throws {
        let geoPluginConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
            (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))

        do {
            let config = try AWSLocationGeoPluginConfiguration(config: geoPluginConfigJSON)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.regionName, GeoPluginTestConfig.regionName)
            XCTAssertTrue(config.maps.isEmpty)
            XCTAssertNil(config.defaultMap)
            XCTAssertEqual(config.searchIndices, GeoPluginTestConfig.searchIndices)
            XCTAssertEqual(config.defaultSearchIndex, GeoPluginTestConfig.searchIndex)
        } catch {
            XCTFail("Failed to instantiate geo plugin configuration")
        }
    }

    func testConfigureThrowsErrorForMissingConfigurationObject() {
        let geoPluginConfig: Any? = nil

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: geoPluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.configurationInvalid(section: .plugin).errorDescription)
        }
    }

    func testConfigureThrowsErrorForInvalidConfigurationObject() {
        let geoPluginConfig = JSONValue(stringLiteral: "notADictionaryLiteral")

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: geoPluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.configurationInvalid(section: .plugin).errorDescription)
        }
    }

    func testConfigureThrowsErrorForInvalidMapsConfiguration() {
        let mapsConfigJSON = JSONValue(stringLiteral: "notADictionaryLiteral")
        let geoPluginConfig = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
            (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON))

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: geoPluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.configurationInvalid(section: .maps).errorDescription)
        }
    }

    func testConfigureThrowsErrorForInvalidSearchConfiguration() {
        let searchConfigJSON = JSONValue(stringLiteral: "notADictionaryLiteral")
        let geoPluginConfig = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
            (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, searchConfigJSON))

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: geoPluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.configurationInvalid(section: .searchIndices).errorDescription)
        }
    }

    func testConfigureThrowsErrorForDefaultMapNotFound() {
        let map = "missingMapName"
        let mapJSON = JSONValue(stringLiteral: map)

        let mapsConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.items.key, GeoPluginTestConfig.mapItemConfigJSON),
            (AWSLocationGeoPluginConfiguration.Node.default.key, mapJSON))

        let geoPluginConfig = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
            (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON))

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: geoPluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.mapDefaultNotFound(mapName: map).errorDescription)
        }
    }

    func testConfigureThrowsErrorForDefaultSearchIndexNotFound() {
        let searchIndex = "missingSearchIndex"
        let searchIndexJSON = JSONValue(stringLiteral: searchIndex)

        let searchConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.items.key, GeoPluginTestConfig.searchItemsArrayJSON),
            (AWSLocationGeoPluginConfiguration.Node.default.key, searchIndexJSON))

        let geoPluginConfig = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
            (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, searchConfigJSON))

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: geoPluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.searchDefaultNotFound(indexName: searchIndex).errorDescription)
        }
    }
}

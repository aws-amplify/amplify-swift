//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable @_spi(InternalAmplifyConfiguration) import Amplify
import XCTest

@testable import AWSLocationGeoPlugin

class AWSLocationGeoPluginAmplifyOutputsConfigurationTests: XCTestCase {

    func testConfigureSuccessAll() throws {
        do {
            let config = try AWSLocationGeoPluginConfiguration(
                config: GeoPluginTestConfig.geoPluginConfigAmplifyOutputs)
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
        let config = AmplifyOutputsData(
            geo: .init(awsRegion: GeoPluginTestConfig.regionName))
        do {
            let config = try AWSLocationGeoPluginConfiguration(config: config)
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
        let config = AmplifyOutputsData(
            geo: .init(
                awsRegion: GeoPluginTestConfig.regionName,
                maps: .init(
                    items: [GeoPluginTestConfig.map: .init(style: GeoPluginTestConfig.style)],
                    default: GeoPluginTestConfig.map)))
        do {
            let config = try AWSLocationGeoPluginConfiguration(config: config)
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
        let config = AmplifyOutputsData(
            geo: .init(
                awsRegion: GeoPluginTestConfig.regionName,
                searchIndices: .init(
                    items: [GeoPluginTestConfig.searchIndex],
                    default: GeoPluginTestConfig.searchIndex)))

        do {
            let config = try AWSLocationGeoPluginConfiguration(config: config)
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

    func testConfigureThrowsErrorForMissingGeoCategory() {
        let config = AmplifyOutputsData(geo: nil)

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.configurationInvalid(section: .plugin).errorDescription)
        }
    }

    /// - Given: geo plugin configuration
    /// - When: the object initializes missing default map
    /// - Then: the configuration fails to initialize with mapDefaultNotFound error
    func testConfigureThrowsErrorForDefaultMapNotFound() {
        let map = "missingMapName"

        let config = AmplifyOutputsData(
            geo: .init(
                awsRegion: GeoPluginTestConfig.regionName,
                maps: .init(
                    items: [GeoPluginTestConfig.map: .init(style: GeoPluginTestConfig.style)],
                    default: map)))

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.mapDefaultNotFound(mapName: map).errorDescription)
        }
    }

    /// - Given: geo plugin configuration
    /// - When: the object initializes missing default search
    /// - Then: the configuration fails to initialize with searchDefaultNotFound error
    func testConfigureThrowsErrorForDefaultSearchIndexNotFound() {
        let searchIndex = "missingSearchIndex"
        let config = AmplifyOutputsData(
            geo: .init(
                awsRegion: GeoPluginTestConfig.regionName,
                maps: nil,
                searchIndices: .init(items: [GeoPluginTestConfig.searchIndex], default: searchIndex)))

        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.searchDefaultNotFound(indexName: searchIndex).errorDescription)
        }
    }
}

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

    /// - Given: geo plugin configuration
    /// - When: the object initializes missing default map
    /// - Then: the configuration fails to initialize with mapDefaultNotFound error
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

    /// - Given: geo plugin configuration
    /// - When: the object initializes missing default search
    /// - Then: the configuration fails to initialize with searchDefaultNotFound error
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
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes missing region
    /// - Then: the configuration fails to initialize with regionMissing error
    func testConfigureFailureForMissingRegion() async {
        let config = JSONValue(dictionaryLiteral: (AWSLocationGeoPluginConfiguration.Section.maps.key, GeoPluginTestConfig.mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.regionMissing.errorDescription)
        }
    }

    /// - Given: geo plugin configuration
    /// - When: the object initializes with an invalid region
    /// - Then: the configuration fails to initialize with regionInvalid error
    func testConfigureFailureForInvalidRegion() async {
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, JSONValue(integerLiteral: 1)),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, GeoPluginTestConfig.mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.regionInvalid.errorDescription)
        }
    }
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes with a missing default maps section
    /// - Then: the configuration fails to initialize with defaultMissing error
    func testConfigureFailureForMissingDefaultMapsSection() async {
        let mapsConfigJSON = JSONValue(dictionaryLiteral: (AWSLocationGeoPluginConfiguration.Node.items.key, GeoPluginTestConfig.mapItemConfigJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.defaultMissing(section: .maps).errorDescription)
        }
    }
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes without default map
    /// - Then: the configuration fails to initialize with mapDefaultNotFound error
    func testConfigureFailureWithoutDefaultMapsSection() async {
        let mapName = "test"
        let mapStyleJSON = JSONValue(stringLiteral: "VectorEsriStreets")
        let mapStyleConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.style.key, mapStyleJSON))
        let mapItemConfigJSON = JSONValue(dictionaryLiteral: (mapName, mapStyleConfigJSON))
        let mapsConfigJSON = JSONValue(dictionaryLiteral:
                                        (AWSLocationGeoPluginConfiguration.Node.items.key, mapItemConfigJSON),
                                       (AWSLocationGeoPluginConfiguration.Node.default.key, GeoPluginTestConfig.testMapJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.mapDefaultNotFound(mapName: "testMap").errorDescription)
        }
    }

    /// - Given: geo plugin configuration
    /// - When: the object initializes with a invalid default maps section
    /// - Then: the configuration fails to initialize with defaultNotString error
    func testConfigureFailureForInvalidDefaultMapsSection() async {
        let mapsConfigJSON = JSONValue(dictionaryLiteral: (AWSLocationGeoPluginConfiguration.Node.items.key, GeoPluginTestConfig.mapItemConfigJSON),
                                       (AWSLocationGeoPluginConfiguration.Node.default.key, JSONValue(integerLiteral: 1)))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.defaultNotString(section: .maps).errorDescription)
        }

    }


    /// - Given: geo plugin configuration
    /// - When: the object initializes with a empty default maps section
    /// - Then: the configuration fails to initialize with defaultIsEmpty error
    func testConfigureFailureForEmptyDefaultMapsSection() async {
        let mapsConfigJSON = JSONValue(dictionaryLiteral: (AWSLocationGeoPluginConfiguration.Node.items.key, GeoPluginTestConfig.mapItemConfigJSON),
                                       (AWSLocationGeoPluginConfiguration.Node.default.key, JSONValue(stringLiteral: "")))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.defaultIsEmpty(section: .maps).errorDescription)
        }
    }
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes with a items default maps section
    /// - Then: the configuration fails to initialize with itemsMissing error
    func testConfigureFailureForMissingItemsMapsSection() async {
        let mapsConfigJSON = JSONValue(dictionaryLiteral: (AWSLocationGeoPluginConfiguration.Node.default.key,GeoPluginTestConfig.testMapJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.itemsMissing(section: .maps).errorDescription)
        }
    }
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes with a invalid maps section
    /// - Then: the configuration fails to initialize with mapInvalid error
    func testConfigureFailureForInvalidMapsSection() async {
        let mapItemConfigJSON = JSONValue(dictionaryLiteral: ("testMap", JSONValue(stringLiteral: "")))
        let mapsConfigJSON = JSONValue(dictionaryLiteral:
                                        (AWSLocationGeoPluginConfiguration.Node.items.key, mapItemConfigJSON),
                                       (AWSLocationGeoPluginConfiguration.Node.default.key, GeoPluginTestConfig.testMapJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.mapInvalid(mapName: "testMap").errorDescription)
        }
    }
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes with a invalid maps section
    /// - Then: the configuration fails to initialize with mapStyleMissing error
    func testConfigureFailureForMapStyleMissingError() async {
        let mapStyleConfigJSON = JSONValue(dictionaryLiteral:
                                            (AWSLocationGeoPluginConfiguration.Node.region.key, JSONValue(stringLiteral: "")))
        let mapItemConfigJSON = JSONValue(dictionaryLiteral: ("testMap", mapStyleConfigJSON))
        let mapsConfigJSON = JSONValue(dictionaryLiteral:
                                        (AWSLocationGeoPluginConfiguration.Node.items.key, mapItemConfigJSON),
                                       (AWSLocationGeoPluginConfiguration.Node.default.key, GeoPluginTestConfig.testMapJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.mapStyleMissing(mapName: "testMap").errorDescription)
        }
    }
    
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes with a invalid maps section
    /// - Then: the configuration fails to initialize with mapStyleMissing error
    func testConfigureFailureForInvalidMapStyleURLError() async {
        let mapName = "test  Map"
        let mapStyleJSON = JSONValue(stringLiteral: "VectorEsriStreets")
        let mapStyleConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.style.key, mapStyleJSON))
        let mapItemConfigJSON = JSONValue(dictionaryLiteral: (mapName, mapStyleConfigJSON))
        let mapsConfigJSON = JSONValue(dictionaryLiteral:
                                        (AWSLocationGeoPluginConfiguration.Node.items.key, mapItemConfigJSON),
                                       (AWSLocationGeoPluginConfiguration.Node.default.key, GeoPluginTestConfig.testMapJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.mapStyleURLInvalid(mapName: mapName).errorDescription)
        }
    }
    
    /// - Given: geo plugin configuration
    /// - When: the object initializes with a invalid map style url
    /// - Then: the configuration fails to initialize with mapStyleIsNotString error
    func testConfigureFailureForMapStyleIsNotStringError() async {
        let mapName = "testSearchIndex"
        let mapStyleJSON = JSONValue(integerLiteral: 1)
        let mapStyleConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.style.key, mapStyleJSON))
        let mapItemConfigJSON = JSONValue(dictionaryLiteral: (mapName, mapStyleConfigJSON))
        let mapsConfigJSON = JSONValue(dictionaryLiteral:
                                        (AWSLocationGeoPluginConfiguration.Node.items.key, mapItemConfigJSON),
                                       (AWSLocationGeoPluginConfiguration.Node.default.key, GeoPluginTestConfig.testMapJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, GeoPluginTestConfig.searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.mapStyleIsNotString(mapName: mapName).errorDescription)
        }
    }

    /// - Given: geo plugin configuration
    /// - When: object initializes with a invalid items search indices section
    /// - Then: object fails to initialize with itemsInvalid error
    func testConfigureFailureForInvalidItemsSearchIndicesSection() async {
        let searchIndex = "testSearchIndex"
        let searchIndexJSON = JSONValue(stringLiteral: searchIndex)
        let searchItemsArrayJSON = JSONValue(stringLiteral: "")
        let searchConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.items.key, searchItemsArrayJSON),
            (AWSLocationGeoPluginConfiguration.Node.default.key, searchIndexJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, GeoPluginTestConfig.mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.itemsInvalid(section: .searchIndices).errorDescription)
        }
    }

    /// - Given: geo plugin configuration
    /// - When: configuration is initialize with with an array of int literals ofr search items
    /// - Then: the object fails to initialize with a itemsIsNotStringArray error
    func testConfigureFailureForEmptyItemsSearchIndicesSection() async {
        let searchIndex = "testSearchIndex"
        let searchIndexJSON = JSONValue(stringLiteral: searchIndex)
        let searchItemsArrayJSON = JSONValue(arrayLiteral: 1)
        let searchConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.items.key, searchItemsArrayJSON),
            (AWSLocationGeoPluginConfiguration.Node.default.key, searchIndexJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, GeoPluginTestConfig.mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, searchConfigJSON))
        XCTAssertThrowsError(try AWSLocationGeoPluginConfiguration(config: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription,
                           GeoPluginConfigError.itemsIsNotStringArray(section: .searchIndices).errorDescription)
        }
    }
    
    /// - Given: geo plugin configuration
    /// - When: configuration initializes with a mismatch search items and default item
    /// - Then: the configuration fails to initializes with searchDefaultNotFound error
    func testConfigureFailureForMissingDefaultSearchSection() async {
        let searchIndex = "testSearchIndex"
        let searchIndexJSON = JSONValue(stringLiteral: searchIndex)
        let searchItemsArrayJSON = JSONValue(arrayLiteral: JSONValue(stringLiteral: "test"))
        let searchConfigJSON = JSONValue(dictionaryLiteral:
            (AWSLocationGeoPluginConfiguration.Node.items.key, searchItemsArrayJSON),
            (AWSLocationGeoPluginConfiguration.Node.default.key, searchIndexJSON))
        let config = JSONValue(dictionaryLiteral:(AWSLocationGeoPluginConfiguration.Node.region.key, GeoPluginTestConfig.regionJSON),
                               (AWSLocationGeoPluginConfiguration.Section.maps.key, GeoPluginTestConfig.mapsConfigJSON),
                               (AWSLocationGeoPluginConfiguration.Section.searchIndices.key, searchConfigJSON))
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

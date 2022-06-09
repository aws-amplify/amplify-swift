//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSLocation

@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSLocationGeoPlugin

class AWSLocationGeoPluginIntergrationTests: XCTestCase {
    let timeout = 30.0
    let searchText = "coffee shop"
    let coordinates = Geo.Coordinates(latitude: 39.7392, longitude: -104.9903)
    let amplifyConfigurationFile = "testconfiguration/AWSLocationGeoPluginIntegrationTests-amplifyconfiguration"

    override func setUp() {
        continueAfterFailure = false
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSLocationGeoPlugin())
            let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(configuration)
        } catch {
            XCTFail("Failed to initialize and configure Amplify: \(error)")
        }
        XCTAssertNotNil(Amplify.Geo.plugin)
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testGetEscapeHatch() throws {
        let plugin = try Amplify.Geo.getPlugin(for: "awsLocationGeoPlugin")
        guard let locationPlugin = plugin as? AWSLocationGeoPlugin else {
            XCTFail("Could not get plugin of type AWSLocationGeoPlugin")
            return
        }
        let awsLocation = locationPlugin.getEscapeHatch()
        XCTAssertNotNil(awsLocation)
    }

    // MARK: - Search
    
    /// Test if search(for: text) successfully gets Place results.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: text)
    /// - Then:
    ///    - Place results are returned.
    ///
    func testSearchForText() async {
        let options = Geo.SearchForTextOptions(area: .near(coordinates))
        do {
            let places = try await Amplify.Geo.search(for: searchText, options: options)
            XCTAssertFalse(places.isEmpty)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if search(for: coordinates) successfully gets Place results.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: coordinates)
    /// - Then:
    ///    - Place results are returned.
    ///
    func testSearchForCoordinates() async {
        do {
            let places = try await Amplify.Geo.search(for: coordinates, options: nil)
            XCTAssertFalse(places.isEmpty)
            XCTAssertNotNil(places.first?.coordinates)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    // MARK: - Maps

    /// Test if defaultMap() successfully gets the default map metadata.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke defaultMap().
    /// - Then:
    ///    - Default map metadata is returned.
    ///
    func testDefaultMap() async {
        do {
            let map = try await Amplify.Geo.defaultMap()
            XCTAssertNotNil(map)
            XCTAssertNotNil(map.mapName)
            XCTAssertNotNil(map.style)
            XCTAssertNotNil(map.styleURL)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if availableMaps() successfully gets metadata for all available maps.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke availableMaps().
    /// - Then:
    ///    - Metadata for all available maps is returned.
    ///
    func testAvailableMaps() async {
        do {
            let maps = try await Amplify.Geo.availableMaps()
            XCTAssertFalse(maps.isEmpty)
            XCTAssertNotNil(maps.first?.mapName)
            XCTAssertNotNil(maps.first?.style)
            XCTAssertNotNil(maps.first?.styleURL)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}

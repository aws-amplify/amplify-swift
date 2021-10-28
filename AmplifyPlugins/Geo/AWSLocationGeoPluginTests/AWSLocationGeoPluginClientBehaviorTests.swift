//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSLocation
@testable import AWSLocationGeoPlugin
import XCTest

class AWSLocationGeoPluginClientBehaviorTests: AWSLocationGeoPluginTestBase {
    let searchText = "coffee shop"
    let coordinates = Geo.Coordinates(latitude: 39.7392, longitude: -104.9903)

    // MARK: - Search
    func testSearchForText() {
        let expResult = expectation(description: "Receive result")

        geoPlugin.search(for: searchText) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success:
                let request = AWSLocationSearchPlaceIndexForTextRequest()!
                request.text = self?.searchText
                self?.mockLocation.verifySearchPlaceIndexForText(request)
                expResult.fulfill()
            }
        }

        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testSearchForTextWithOptions() {
        var options = Geo.SearchForTextOptions()
        options.countries = [.usa, .can]
        options.maxResults = 5
        options.area = .near(coordinates)
        options.pluginOptions = AWSLocationGeoPluginSearchOptions(searchIndex: GeoPluginTestConfig.searchIndex)
        let expResult = expectation(description: "Receive result")
        geoPlugin.search(for: searchText, options: options) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success:
                let request = AWSLocationSearchPlaceIndexForTextRequest()!
                request.text = self?.searchText
                request.biasPosition = [(self?.coordinates.longitude ?? 0) as NSNumber,
                                        (self?.coordinates.latitude ?? 0) as NSNumber]
                request.filterCountries = options.countries?.map { $0.code }
                request.maxResults = options.maxResults as NSNumber?
                request.indexName = (options.pluginOptions as? AWSLocationGeoPluginSearchOptions)?.searchIndex
                self?.mockLocation.verifySearchPlaceIndexForText(request)
                expResult.fulfill()
            }
        }
        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testSearchForTextWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig

        let expResult = expectation(description: "Receive result")

        geoPlugin.search(for: searchText) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error.errorDescription, "No default search index was found.")
                expResult.fulfill()
            case .success:
                XCTFail("This call returned success when a failure was expected.")
            }
        }

        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testSearchForCoordinates() {
        let expResult = expectation(description: "Receive result")

        geoPlugin.search(for: coordinates) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success:
                let request = AWSLocationSearchPlaceIndexForPositionRequest()!
                request.position = [(self?.coordinates.longitude ?? 0) as NSNumber,
                                    (self?.coordinates.latitude ?? 0) as NSNumber]
                self?.mockLocation.verifySearchPlaceIndexForPosition(request)
                expResult.fulfill()
            }
        }
        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testSearchForCoordinatesWithOptions() {
        var options = Geo.SearchForCoordinatesOptions()
        options.maxResults = 5
        options.pluginOptions = AWSLocationGeoPluginSearchOptions(searchIndex: GeoPluginTestConfig.searchIndex)
        let expResult = expectation(description: "Receive result")
        geoPlugin.search(for: coordinates,
                         options: options) { [weak self] result in

            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success:
                let request = AWSLocationSearchPlaceIndexForPositionRequest()!
                request.position = [(self?.coordinates.longitude ?? 0) as NSNumber,
                                    (self?.coordinates.latitude ?? 0) as NSNumber]
                request.maxResults = options.maxResults as NSNumber?
                request.indexName = (options.pluginOptions as? AWSLocationGeoPluginSearchOptions)?.searchIndex
                self?.mockLocation.verifySearchPlaceIndexForPosition(request)
                expResult.fulfill()
            }
        }
        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testSearchForCoordinatesWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig

        let expResult = expectation(description: "Receive result")

        geoPlugin.search(for: coordinates) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error.errorDescription, "No default search index was found.")
                expResult.fulfill()
            case .success:
                XCTFail("This call returned success when a failure was expected.")
            }
        }

        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    // MARK: - Maps
    func testAvailableMaps() {
        let expResult = expectation(description: "Receive result")

        geoPlugin.availableMaps { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success(let maps):
                XCTAssertEqual(maps.count, GeoPluginTestConfig.maps.count)
                for map in maps {
                    XCTAssertEqual(GeoPluginTestConfig.maps[map.mapName], map)
                }
                expResult.fulfill()
            }
        }

        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testAvailableMapsWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig
        let expResult = expectation(description: "Receive result")

        geoPlugin.availableMaps { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error.errorDescription, "No maps are available.")
                expResult.fulfill()
            case .success:
                XCTFail("This call returned success when a failure was expected.")
            }
        }

        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testDefaultMap() {
        let expResult = expectation(description: "Receive result")

        geoPlugin.defaultMap { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success(let map):
                XCTAssertEqual(map.mapName, GeoPluginTestConfig.map)
                expResult.fulfill()
            }
        }

        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testDefaultMapWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig

        let expResult = expectation(description: "Receive result")

        geoPlugin.defaultMap { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error.errorDescription, "No default map was found.")
                expResult.fulfill()
            case .success:
                XCTFail("This call returned success when a failure was expected.")
            }
        }

        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }
}

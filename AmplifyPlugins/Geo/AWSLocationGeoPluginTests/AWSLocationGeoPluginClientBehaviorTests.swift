//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSLocation
@testable import AWSLocationGeoPlugin
import CwlPreconditionTesting
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
        let countries: [Geo.Country] = [.USA, .CAN]
        let maxResults = 5
        let searchIndex = GeoPluginTestConfig.searchIndex
        let expResult = expectation(description: "Receive result")
        geoPlugin.search(for: searchText,
                         area: .near(coordinates),
                         countries: countries,
                         maxResults: maxResults,
                         placeIndexName: searchIndex) { [weak self] result in

            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success:
                let request = AWSLocationSearchPlaceIndexForTextRequest()!
                request.text = self?.searchText
                request.biasPosition = [(self?.coordinates.longitude ?? 0) as NSNumber,
                                        (self?.coordinates.latitude ?? 0) as NSNumber]
                request.filterCountries = countries.map { String(describing: $0) }
                request.maxResults = maxResults as NSNumber
                request.indexName = searchIndex
                self?.mockLocation.verifySearchPlaceIndexForText(request)
                expResult.fulfill()
            }
        }
        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testSearchForTextWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig

        var reachedPoint1 = false
        var reachedPoint2 = false
        let missingConfigAssertion = CwlPreconditionTesting.catchBadInstruction {
            reachedPoint1 = true
            self.geoPlugin.search(for: self.searchText) { _ in }
            reachedPoint2 = true
        }
        XCTAssertNotNil(missingConfigAssertion)
        XCTAssertTrue(reachedPoint1)
        XCTAssertFalse(reachedPoint2)
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
        let maxResults = 5
        let searchIndex = GeoPluginTestConfig.searchIndex
        let expResult = expectation(description: "Receive result")
        geoPlugin.search(for: coordinates,
                         maxResults: maxResults,
                         placeIndexName: searchIndex) { [weak self] result in

            switch result {
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            case .success:
                let request = AWSLocationSearchPlaceIndexForPositionRequest()!
                request.position = [(self?.coordinates.longitude ?? 0) as NSNumber,
                                    (self?.coordinates.latitude ?? 0) as NSNumber]
                request.maxResults = maxResults as NSNumber
                request.indexName = searchIndex
                self?.mockLocation.verifySearchPlaceIndexForPosition(request)
                expResult.fulfill()
            }
        }
        waitForExpectations(timeout: GeoPluginTestConfig.timeout)
    }

    func testSearchForCoordinatesWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig

        var reachedPoint1 = false
        var reachedPoint2 = false
        let missingConfigAssertion = CwlPreconditionTesting.catchBadInstruction {
            reachedPoint1 = true
            self.geoPlugin.search(for: self.coordinates) { _ in }
            reachedPoint2 = true
        }
        XCTAssertNotNil(missingConfigAssertion)
        XCTAssertTrue(reachedPoint1)
        XCTAssertFalse(reachedPoint2)
    }

    // MARK: - Maps
    func testGetAvailableMaps() {
        let maps = geoPlugin.getAvailableMaps()

        XCTAssertEqual(maps.count, GeoPluginTestConfig.maps.count)
        for map in maps {
            XCTAssertEqual(GeoPluginTestConfig.maps[map.mapName], map)
        }
    }

    func testGetAvailableMapsWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig

        var reachedPoint1 = false
        var reachedPoint2 = false
        let missingConfigAssertion = CwlPreconditionTesting.catchBadInstruction {
            reachedPoint1 = true
            _ = self.geoPlugin.getAvailableMaps()
            reachedPoint2 = true
        }
        XCTAssertNotNil(missingConfigAssertion)
        XCTAssertTrue(reachedPoint1)
        XCTAssertFalse(reachedPoint2)
    }

    func testGetDefaultMap() {
        let map = geoPlugin.getDefaultMap()

        XCTAssertEqual(map, GeoPluginTestConfig.mapStyle)
    }

    func testGetDefaultMapWithoutConfigFails() {
        geoPlugin.pluginConfig = emptyPluginConfig

        var reachedPoint1 = false
        var reachedPoint2 = false
        let missingConfigAssertion = CwlPreconditionTesting.catchBadInstruction {
            reachedPoint1 = true
            _ = self.geoPlugin.getDefaultMap()
            reachedPoint2 = true
        }
        XCTAssertNotNil(missingConfigAssertion)
        XCTAssertTrue(reachedPoint1)
        XCTAssertFalse(reachedPoint2)
    }
}

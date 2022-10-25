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

    /// Test if search(for: text) calls the location service correctly.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: text)
    /// - Then:
    ///    - Correct serivce call is made.
    ///
    func testSearchForText() async {
        do {
            _ = try await geoPlugin.search(for: searchText, options: nil)
            var request = SearchPlaceIndexForTextInput()
            request.text = self.searchText
            self.mockLocation.verifySearchPlaceIndexForText(request)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    /// Test if search(for: text) calls the location service correctly and sets the correct options.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: text) with options
    /// - Then:
    ///    - Correct serivce call is made with correct parameters.
    ///
    func testSearchForTextWithOptions() async {
        var options = Geo.SearchForTextOptions()
        options.countries = [.usa, .can]
        options.maxResults = 5
        options.area = .near(coordinates)
        options.pluginOptions = AWSLocationGeoPluginSearchOptions(searchIndex: GeoPluginTestConfig.searchIndex)

        do {
            _ = try await geoPlugin.search(for: searchText, options: options)
            var request = SearchPlaceIndexForTextInput()
            request.text = self.searchText
            request.biasPosition = [(self.coordinates.longitude),
                                    (self.coordinates.latitude)]
            request.filterCountries = options.countries?.map { $0.code }
            request.maxResults = options.maxResults ?? 0
            request.indexName = (options.pluginOptions as? AWSLocationGeoPluginSearchOptions)?.searchIndex
            self.mockLocation.verifySearchPlaceIndexForText(request)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    /// Test if search(for: text) fails when configuration is invalid.
    ///
    /// - Given: Geo plugin with a missing configuration.
    /// - When:
    ///    - I invoke search(for: text)
    /// - Then:
    ///    - Expected error is returned.
    ///
    func testSearchForTextWithoutConfigFails() async {
        geoPlugin.pluginConfig = emptyPluginConfig

        do {
            _ = try await geoPlugin.search(for: searchText, options: nil)
            XCTFail("This call returned success when a failure was expected.")
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, "No default search index was found.")
        }
    }

    /// Test if search(for: coordinates) calls the location service correctly.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: coordinates)
    /// - Then:
    ///    - Correct serivce call is made.
    ///
    func testSearchForCoordinates() async {
        do {
            _ = try await geoPlugin.search(for: coordinates, options: nil)
            var request = SearchPlaceIndexForPositionInput()
            request.position = [(self.coordinates.longitude),
                                (self.coordinates.latitude)]
            self.mockLocation.verifySearchPlaceIndexForPosition(request)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    /// Test if search(for: coordinates) calls the location service correctly and sets the correct options.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: coordinates) with options
    /// - Then:
    ///    - Correct serivce call is made with correct parameters.
    ///
    func testSearchForCoordinatesWithOptions() async {
        var options = Geo.SearchForCoordinatesOptions()
        options.maxResults = 5
        options.pluginOptions = AWSLocationGeoPluginSearchOptions(searchIndex: GeoPluginTestConfig.searchIndex)

        do {
            _ = try await geoPlugin.search(for: coordinates, options: options)
            var request = SearchPlaceIndexForPositionInput()
            request.position = [(self.coordinates.longitude),
                                (self.coordinates.latitude) ]
            request.maxResults = options.maxResults ?? 0
            request.indexName = (options.pluginOptions as? AWSLocationGeoPluginSearchOptions)?.searchIndex
            self.mockLocation.verifySearchPlaceIndexForPosition(request)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    /// Test if search(for: coordinates) fails when configuration is invalid.
    ///
    /// - Given: Geo plugin with a missing configuration.
    /// - When:
    ///    - I invoke search(for: coordinates).
    /// - Then:
    ///    - Expected error is returned.
    ///
    func testSearchForCoordinatesWithoutConfigFails() async {
        geoPlugin.pluginConfig = emptyPluginConfig

        do {
            _ = try await geoPlugin.search(for: coordinates, options: nil)
            XCTFail("This call returned success when a failure was expected.")
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, "No default search index was found.")
        }
    }

    // MARK: - Maps

    /// Test if availableMaps() calls the location service correctly.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke availableMaps().
    /// - Then:
    ///    - Correct serivce call is made.
    ///
    func testAvailableMaps() async {
        do {
            let maps = try await geoPlugin.availableMaps()
            XCTAssertEqual(maps.count, GeoPluginTestConfig.maps.count)
            for map in maps {
                XCTAssertEqual(GeoPluginTestConfig.maps[map.mapName], map)
            }
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    /// Test if availableMaps() fails when configuration is invalid.
    ///
    /// - Given: Geo plugin with a missing configuration.
    /// - When:
    ///    - I invoke availableMaps().
    /// - Then:
    ///    - Expected error is returned.
    ///
    func testAvailableMapsWithoutConfigFails() async {
        geoPlugin.pluginConfig = emptyPluginConfig

        do {
            _ = try await geoPlugin.availableMaps()
            XCTFail("This call returned success when a failure was expected.")
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, "No maps are available.")
        }
    }

    /// Test if defaultMap() calls the location service correctly.
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke defaultMap().
    /// - Then:
    ///    - Correct serivce call is made.
    ///
    func testDefaultMap() async {
        do {
            let map = try await geoPlugin.defaultMap()
            XCTAssertEqual(map.mapName, GeoPluginTestConfig.map)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    /// Test if defaultMap() fails when configuration is invalid.
    ///
    /// - Given: Geo plugin with a missing configuration.
    /// - When:
    ///    - I invoke defaultMap().
    /// - Then:
    ///    - Expected error is returned.
    ///
    func testDefaultMapWithoutConfigFails() async {
        geoPlugin.pluginConfig = emptyPluginConfig

        do {
            _ = try await geoPlugin.defaultMap()
            XCTFail("This call returned success when a failure was expected.")
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, "No default map was found.")
        }
    }
    
    // MARK: - Device Tracking
    
    /// Test if updateLocation calls the location service correctly
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke updateLocation.
    /// - Then:
    ///    - Expected operation succeeds.
    ///
    func testUpdateLocation() async {
        do {
            let device = Geo.Device.unchecked(id: "123-456-789")
            let location = Geo.Location(latitude: 44.4, longitude: 45.5)
            try await geoPlugin.updateLocation(location, for: device, with: Geo.UpdateLocationOptions())
            XCTAssertEqual(mockLocation.updateLocationCalled, 1)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if updateLocation fails when configuration is invalid.
    ///
    /// - Given: Geo plugin with a missing configuration.
    /// - When:
    ///    - I invoke updateLocation.
    /// - Then:
    ///    - Expected error is returned.
    ///
    func testUpdateLocationWithoutConfigFails() async {
        geoPlugin.pluginConfig = emptyPluginConfig

        do {
            let device = Geo.Device.unchecked(id: "123-456-789")
            let location = Geo.Location(latitude: 44.4, longitude: 45.5)
            try await geoPlugin.updateLocation(location, for: device, with: Geo.UpdateLocationOptions())
            XCTFail("This call returned success when a failure was expected.")
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, GeoPluginErrorConstants.missingTracker.errorDescription)
        }
    }
    
    /// Test if deleteLocationHistory calls location service correctly
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke deleteLocationHistory.
    /// - Then:
    ///    - Expected operation completes.
    ///
    func testDeleteLocationHistory() async {

        do {
            let device = Geo.Device.unchecked(id: "123-456-789")
            try await geoPlugin.deleteLocationHistory(for: device, with: Geo.DeleteLocationOptions())
            XCTAssertEqual(mockLocation.deleteLocationHistoryCalled, 1)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if deleteLocationHistory fails when configuration is invalid.
    ///
    /// - Given: Geo plugin with a missing configuration.
    /// - When:
    ///    - I invoke deleteLocationHistory.
    /// - Then:
    ///    - Expected error is returned.
    ///
    func testDeleteLocationHistoryWithoutConfigFails() async {
        geoPlugin.pluginConfig = emptyPluginConfig

        do {
            let device = Geo.Device.unchecked(id: "123-456-789")
            try await geoPlugin.deleteLocationHistory(for: device, with: Geo.DeleteLocationOptions())
            XCTFail("This call returned success when a failure was expected.")
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, GeoPluginErrorConstants.missingTracker.errorDescription)
        }
    }
    
    /// Test if startTracking succeeds with a valid configuration and with a default tracker
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke startTracking.
    /// - Then:
    ///    - Expected operation completes.
    ///
    func testStartTrackingWithDefaultTracker() async {
        do {
            let device = Geo.Device.unchecked(id: "123-456-789")
            try await geoPlugin.startTracking(for: device, with: Geo.LocationManager.TrackingSessionOptions())
            XCTAssertEqual(mockDeviceTracker.startDeviceTrackingCalled, 1)
            XCTAssertEqual(mockDeviceTracker.configureCalled, 1)
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, GeoPluginErrorConstants.missingTracker.errorDescription)
        }
    }
    
    /// Test if startTracking succeeds with a valid configuration and with custom tracker
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke startTracking.
    /// - Then:
    ///    - Expected operation completes.
    ///
    func testStartTrackingWithCustomTracker() async {
        do {
            let device = Geo.Device.unchecked(id: "123-456-789")
            var options = Geo.LocationManager.TrackingSessionOptions()
            options.tracker = "tracker"
            try await geoPlugin.startTracking(for: device, with: options)
            XCTAssertEqual(mockDeviceTracker.startDeviceTrackingCalled, 1)
            XCTAssertEqual(mockDeviceTracker.configureCalled, 1)
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, GeoPluginErrorConstants.missingTracker.errorDescription)
        }
    }
    
    /// Test if startTracking fails when configuration is invalid and tracking session options
    /// has empty tracker.
    ///
    /// - Given: Geo plugin with a missing configuration.
    /// - When:
    ///    - I invoke startTracking.
    /// - Then:
    ///    - Expected error is returned.
    ///
    func testStartTrackingWithoutConfigAndTrackerFails() async {
        geoPlugin.pluginConfig = emptyPluginConfig

        do {
            let device = Geo.Device.unchecked(id: "123-456-789")
            try await geoPlugin.startTracking(for: device, with: Geo.LocationManager.TrackingSessionOptions())
            XCTFail("This call returned success when a failure was expected.")
        } catch {
            guard let geoError = error as? Geo.Error else {
                XCTFail("Error thrown should be Geo.Error")
                return
            }
            XCTAssertEqual(geoError.errorDescription, GeoPluginErrorConstants.missingTracker.errorDescription)
        }
    }
    
    /// Test if stopTracking succeeds with a valid configuration
    ///
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke stopTracking.
    /// - Then:
    ///    - Expected operation completes.
    ///
    func testStopTracking() async {
        geoPlugin.stopTracking()
        XCTAssertEqual(mockDeviceTracker.stopDeviceTrackingCalled, 1)
    }
}

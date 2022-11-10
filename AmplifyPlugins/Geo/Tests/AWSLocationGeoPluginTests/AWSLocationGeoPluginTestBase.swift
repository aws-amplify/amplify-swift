//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSLocationGeoPlugin
@testable import AWSPluginsTestCommon
import XCTest

class AWSLocationGeoPluginTestBase: XCTestCase {
    var geoPlugin: AWSLocationGeoPlugin!
    var mockLocation: MockAWSLocation!
    var mockLocationManager: MockLocationManager!
    var mockDeviceTracker: MockAWSDeviceTracker!
    var mockNetworkMonitor: MockGeoNetworkMonitor!
    var mockLocationStore: SQLiteLocationPersistenceAdapter!
    var pluginConfig: AWSLocationGeoPluginConfiguration!
    var emptyPluginConfig: AWSLocationGeoPluginConfiguration!

    override func setUp() async throws {
        pluginConfig = AWSLocationGeoPluginConfiguration(regionName: GeoPluginTestConfig.regionName,
                                                         defaultMap: GeoPluginTestConfig.map,
                                                         maps: GeoPluginTestConfig.maps,
                                                         defaultSearchIndex: GeoPluginTestConfig.searchIndex,
                                                         searchIndices: GeoPluginTestConfig.searchIndices,
                                                         defaultTracker: GeoPluginTestConfig.defaultTracker,
                                                         trackers: GeoPluginTestConfig.trackers)

        emptyPluginConfig = AWSLocationGeoPluginConfiguration(regionName: GeoPluginTestConfig.regionName,
                                                              defaultMap: nil,
                                                              maps: [:],
                                                              defaultSearchIndex: nil,
                                                              searchIndices: [],
                                                              defaultTracker: nil,
                                                              trackers: [])
        do {
            mockLocation = try MockAWSLocation(pluginConfig: pluginConfig)
        } catch {
            XCTFail("Error initializing mockLocation: \(error)")
        }
        mockNetworkMonitor = MockGeoNetworkMonitor()
        mockLocationStore = try SQLiteLocationPersistenceAdapter(fileSystemBehavior: MockLocationFileSystem())
        mockLocationManager = MockLocationManager()
        mockDeviceTracker = try MockAWSDeviceTracker(options: .init(),
                                                     locationManager: mockLocationManager,
                                                     locationService: mockLocation,
                                                     networkMonitor: mockNetworkMonitor,
                                                     locationStore: mockLocationStore)
        geoPlugin = AWSLocationGeoPlugin()
        geoPlugin.locationService = mockLocation
        AWSLocationGeoPlugin.deviceTracker = mockDeviceTracker
        geoPlugin.authService = MockAWSAuthService()
        geoPlugin.pluginConfig = pluginConfig

        await Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
        geoPlugin.reset()
    }
}

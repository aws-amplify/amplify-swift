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
    var pluginConfig: AWSLocationGeoPluginConfiguration!
    var emptyPluginConfig: AWSLocationGeoPluginConfiguration!

    override func setUp() {
        pluginConfig = AWSLocationGeoPluginConfiguration(regionName: GeoPluginTestConfig.regionName,
                                                         defaultMap: GeoPluginTestConfig.map,
                                                         maps: GeoPluginTestConfig.maps,
                                                         defaultSearchIndex: GeoPluginTestConfig.searchIndex,
                                                         searchIndices: GeoPluginTestConfig.searchIndices)

        emptyPluginConfig = AWSLocationGeoPluginConfiguration(regionName: GeoPluginTestConfig.regionName,
                                                              defaultMap: nil,
                                                              maps: [:],
                                                              defaultSearchIndex: nil,
                                                              searchIndices: [])

        do {
            mockLocation = try MockAWSLocation(pluginConfig: pluginConfig)
        } catch {
            XCTFail("Error initializing mockLocation: \(error)")
        }
        
        geoPlugin = AWSLocationGeoPlugin()
        geoPlugin.locationService = mockLocation
        geoPlugin.authService = MockAWSAuthService()
        geoPlugin.pluginConfig = pluginConfig

        Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
        geoPlugin.reset {}
    }
}

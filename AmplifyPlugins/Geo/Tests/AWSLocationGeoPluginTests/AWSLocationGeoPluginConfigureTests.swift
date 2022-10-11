//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSLocationGeoPlugin
import XCTest

class AWSLocationGeoPluginConfigureTests: AWSLocationGeoPluginTestBase {
    // MARK: - Plugin Key test

    func testPluginKey() {
        let pluginKey = geoPlugin.key
        XCTAssertEqual(pluginKey, "awsLocationGeoPlugin")
    }

    // MARK: - Configuration tests

    func testConfigureSuccess() {
        geoPlugin.reset()

        do {
            try geoPlugin.configure(using: GeoPluginTestConfig.geoPluginConfigJSON)

            XCTAssertNotNil(geoPlugin.locationService)
            XCTAssertNotNil(geoPlugin.authService)
            XCTAssertNotNil(geoPlugin.pluginConfig)
        } catch {
            XCTFail("Failed to configure geo plugin with error: \(error)")
        }
    }

    func testConfigureFailureForNilConfiguration() throws {
        let plugin = AWSLocationGeoPlugin()
        do {
            try plugin.configure(using: nil)
            XCTFail("Geo configuration should not succeed.")
        } catch {
            guard let pluginError = error as? PluginError,
                case .pluginConfigurationError = pluginError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSLocationGeoPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSLocationGeoPluginConfigureTests: AWSLocationGeoPluginTestBase, @unchecked Sendable {
    // MARK: - Plugin Key test

    func testPluginKey() {
        let pluginKey = geoPlugin.key
        XCTAssertEqual(pluginKey, "awsLocationGeoPlugin")
    }

    // MARK: - Configuration tests

    func testConfigureSuccess() async {
        let resettable = geoPlugin as Resettable
        await resettable.reset()

        do {
            try geoPlugin.configure(using: GeoPluginTestConfig.geoPluginConfigJSON)

            XCTAssertNotNil(geoPlugin.locationService)
            XCTAssertNotNil(geoPlugin.authService)
            XCTAssertNotNil(geoPlugin.pluginConfig)
        } catch {
            XCTFail("Failed to configure geo plugin with error: \(error)")
        }
    }

    func testConfigureAmplifyOutputsSuccess() async {
        let resettable = geoPlugin as Resettable
        await resettable.reset()

        do {
            try geoPlugin.configure(using: GeoPluginTestConfig.geoPluginConfigAmplifyOutputs)

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
                case .pluginConfigurationError = pluginError
            else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }
}

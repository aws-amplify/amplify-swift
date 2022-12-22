//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AmplifyTestCommon
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import XCTest

class AWSPinpointAnalyticsPluginTestBase: XCTestCase {
    var analyticsPlugin: AWSPinpointAnalyticsPlugin!
    var mockPinpoint: MockAWSPinpoint!
    var mockNetworkMonitor: MockNetworkMonitor!

    let testAppId = "56e6f06fd4f244c6b202bc1234567890"
    let testRegion = "us-east-1"
    let testAutoFlushInterval = 30
    let testTrackAppSession = true
    let testAutoSessionTrackingInterval = 10

    var plugin: HubCategoryPlugin {
        guard let plugin = try? Amplify.Hub.getPlugin(for: "awsHubPlugin"),
            plugin.key == "awsHubPlugin" else {
            fatalError("Could not access awsHubPlugin")
        }
        return plugin
    }

    override func setUp() async throws {
        analyticsPlugin = AWSPinpointAnalyticsPlugin()

        mockPinpoint = MockAWSPinpoint()
        mockNetworkMonitor = MockNetworkMonitor()

        analyticsPlugin.configure(pinpoint: mockPinpoint,
                                  networkMonitor: mockNetworkMonitor)

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
        analyticsPlugin.reset()
    }
}

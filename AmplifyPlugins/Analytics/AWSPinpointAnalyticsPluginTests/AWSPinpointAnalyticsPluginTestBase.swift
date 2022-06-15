//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSPinpointAnalyticsPlugin
@testable import Amplify
@testable import AmplifyTestCommon

class AWSPinpointAnalyticsPluginTestBase: XCTestCase {
  var analyticsPlugin: AWSPinpointAnalyticsPlugin!
  var mockPinpoint: MockAWSPinpoint!
  var authService: MockAWSAuthService!
  var appSessionTracker: MockAppSessionTracker!

  let testAppId = "56e6f06fd4f244c6b202bc1234567890"
  let testRegion = "us-east-1"
  let testAutoFlushInterval = 30
  let testTrackAppSession = true
  let testAutoSessionTrackingInterval = 10

  var plugin: HubCategoryPlugin {
    guard let plugin = try? Amplify.Hub.getPlugin(for: "awsHubPlugin"),
      plugin.key == "awsHubPlugin"
    else {
      fatalError("Could not access awsHubPlugin")
    }
    return plugin
  }

  override func setUp() {
    analyticsPlugin = AWSPinpointAnalyticsPlugin()

    mockPinpoint = MockAWSPinpoint()
    authService = MockAWSAuthService()
    appSessionTracker = MockAppSessionTracker(
      trackAppSessions: AWSPinpointAnalyticsPluginConfiguration.defaultTrackAppSession,
      autoSessionTrackingInterval: AWSPinpointAnalyticsPluginConfiguration
        .defaultAutoSessionTrackingInterval
    )

    analyticsPlugin.configure(
      pinpoint: mockPinpoint,
      authService: authService,
      autoFlushEventsTimer: nil,
      appSessionTracker: appSessionTracker)

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
    analyticsPlugin.reset {}
  }
}

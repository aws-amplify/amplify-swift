//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint

/// The AWSPinpointAnalyticsPlugin implements the Analytics APIs for Pinpoint
final public class AWSPinpointAnalyticsPlugin: AnalyticsCategoryPlugin {

    /// An instance of the AWS Pinpoint service
    var pinpoint: AWSPinpointBehavior!

    /// An instance of the authentication service
    var authService: AWSAuthServiceBehavior!

    /// Tracks when events should be submitted
    var flushEventsTracker: Tracker!

    /// Tracks the application sessions
    var appSessionTracker: Tracker!

    // The collection of properties applied to every event
    var globalProperties: [String: AnalyticsPropertyValue]!

    /// Specifies whether the plugin is enabled
    var isEnabled: Bool!

    /// The unique key of the plugin within the analytics category
    public var key: PluginKey {
        return PluginConstants.awsPinpointAnalyticsPluginKey
    }

    /// Instantiates an instance of the AWSPinpointAnalyticsPlugin
    public init() {
    }
}

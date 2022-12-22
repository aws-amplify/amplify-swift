//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
import Network

/// The AWSPinpointAnalyticsPlugin implements the Analytics APIs for Pinpoint
public final class AWSPinpointAnalyticsPlugin: AnalyticsCategoryPlugin {
    /// An instance of the AWS Pinpoint service
    var pinpoint: AWSPinpointBehavior!

    // The collection of properties applied to every event
    var globalProperties: AtomicDictionary<String, AnalyticsPropertyValue>!

    /// Specifies whether the plugin is enabled
    var isEnabled: Bool!

    /// An observer to monitor connectivity changes
    var networkMonitor: NetworkMonitor!

    /// The unique key of the plugin within the analytics category
    public var key: PluginKey {
        "awsPinpointAnalyticsPlugin"
    }

    /// Instantiates an instance of the AWSPinpointAnalyticsPlugin
    public init() {}
}

extension AWSPinpointAnalyticsPlugin: AmplifyVersionable { }

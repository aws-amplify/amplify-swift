//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import AWSPluginsCore
import Amplify
import Foundation

/// The AWSPinpointAnalyticsPlugin implements the Analytics APIs for Pinpoint
public final class AWSPinpointAnalyticsPlugin: AnalyticsCategoryPlugin {
  /// An instance of the AWS Pinpoint service
  var pinpoint: AWSPinpointBehavior!

  /// An instance of the authentication service
  var authService: AWSAuthServiceBehavior!

  /// Tracks the application sessions
  var appSessionTracker: Tracker!

  // The collection of properties applied to every event
  var globalProperties: [String: AnalyticsPropertyValue]!

  /// Specifies whether the plugin is enabled
  var isEnabled: Bool!

  /// Optional timer is nil when auto flush is disabled
  /// Otherwise automatically flushes the events that have been recorded on an interval
  var autoFlushEventsTimer: DispatchSourceTimer?

  /// The unique key of the plugin within the analytics category
  public var key: PluginKey {
    "awsPinpointAnalyticsPlugin"
  }

  /// Instantiates an instance of the AWSPinpointAnalyticsPlugin
  public init() {}
}

extension AWSPinpointAnalyticsPlugin: AmplifyVersionable {}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Analytics properties can store values of common types
/// - Note: `Sendable` because analytics properties are carried into the plugin's async recording
///   paths. The conforming types are `String`, `Int`, `Double` and `Bool`.
public protocol AnalyticsPropertyValue: Sendable {}

extension String: AnalyticsPropertyValue {}
extension Int: AnalyticsPropertyValue {}
extension Double: AnalyticsPropertyValue {}
extension Bool: AnalyticsPropertyValue {}

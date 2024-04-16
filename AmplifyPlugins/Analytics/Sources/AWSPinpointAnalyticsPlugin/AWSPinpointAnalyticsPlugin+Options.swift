//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSPinpointAnalyticsPlugin {
    public struct Options {
        public static let defaultAutoFlushEventsInterval: TimeInterval = 60
        public static let defaultTrackAppSession = true
        public static let defaultAutoSessionTrackingInterval: TimeInterval = {
        #if os(macOS)
            .max
        #else
            5
        #endif
        }()

        public let autoFlushEventsInterval: TimeInterval
        public let trackAppSessions: Bool
        public let autoSessionTrackingInterval: TimeInterval

        public init(autoFlushEventsInterval: TimeInterval = defaultAutoFlushEventsInterval,
                    trackAppSessions: Bool = defaultTrackAppSession,
                    autoSessionTrackingInterval: TimeInterval = defaultAutoSessionTrackingInterval) {
            self.autoFlushEventsInterval = autoFlushEventsInterval
            self.trackAppSessions = trackAppSessions
            self.autoSessionTrackingInterval = autoSessionTrackingInterval
        }

        public static var `default`: Options {
            .init()
        }
    }
}

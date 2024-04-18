//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSPinpointAnalyticsPlugin {
    public struct Options {
        static let defaultAutoFlushEventsInterval: TimeInterval = 60
        static let defaultTrackAppSession = true
        static let defaultAutoSessionTrackingInterval: TimeInterval = {
        #if os(macOS)
            .infinity
        #else
            5
        #endif
        }()

        public let autoFlushEventsInterval: TimeInterval
        public let trackAppSessions: Bool
        public let autoSessionTrackingInterval: TimeInterval

        #if os(macOS)
        public init(autoFlushEventsInterval: TimeInterval = 60,
                    trackAppSessions: Bool = true,
                    autoSessionTrackingInterval: TimeInterval = .infinity) {
            self.autoFlushEventsInterval = autoFlushEventsInterval
            self.trackAppSessions = trackAppSessions
            self.autoSessionTrackingInterval = autoSessionTrackingInterval
        }
        #else
        public init(autoFlushEventsInterval: TimeInterval = 60,
                    trackAppSessions: Bool = true,
                    autoSessionTrackingInterval: TimeInterval = 5) {
            self.autoFlushEventsInterval = autoFlushEventsInterval
            self.trackAppSessions = trackAppSessions
            self.autoSessionTrackingInterval = autoSessionTrackingInterval
        }
        #endif

        public static var `default`: Options {
            .init()
        }
    }
}

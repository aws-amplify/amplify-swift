//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSPinpointAnalyticsPlugin {
    public struct Options {
        public static let defaultAutoFlushEventsInterval: UInt = 60
        public static let defaultTrackAppSession = true
        public static let defaultAutoSessionTrackingInterval: UInt = {
        #if os(macOS)
            .max
        #else
            5
        #endif
        }()

        public let autoFlushEventsInterval: UInt
        public let trackAppSessions: Bool
        public let autoSessionTrackingInterval: UInt

        public init(autoFlushEventsInterval: UInt = defaultAutoFlushEventsInterval,
                    trackAppSessions: Bool = defaultTrackAppSession,
                    autoSessionTrackingInterval: UInt = defaultAutoSessionTrackingInterval) {
            self.autoFlushEventsInterval = autoFlushEventsInterval
            self.trackAppSessions = trackAppSessions
            self.autoSessionTrackingInterval = autoSessionTrackingInterval
        }

        public static var `default`: Options {
            .init()
        }
    }
}

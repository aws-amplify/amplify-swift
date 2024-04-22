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

        public let autoFlushEventsInterval: TimeInterval
        public let trackAppSessions: Bool

        #if os(macOS)
        public init(autoFlushEventsInterval: TimeInterval = 60,
                    trackAppSessions: Bool = true) {
            self.autoFlushEventsInterval = autoFlushEventsInterval
            self.trackAppSessions = trackAppSessions
        }
        #else
        public init(autoFlushEventsInterval: TimeInterval = 60,
                    trackAppSessions: Bool = true) {
            self.autoFlushEventsInterval = autoFlushEventsInterval
            self.trackAppSessions = trackAppSessions
        }
        #endif

        public static var `default`: Options {
            .init()
        }
    }
}

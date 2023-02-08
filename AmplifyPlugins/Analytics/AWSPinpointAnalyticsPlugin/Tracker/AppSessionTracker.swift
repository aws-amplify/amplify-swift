//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class AppSessionTracker: Tracker {
    /// Specifies whether to track application sessions
    var trackAppSessions: Bool!

    /// The amount of time to wait before ending a session after going to the background
    /// Only used when `trackAppSessions` is set to true
    var autoSessionTrackingInterval: Int!

    public init(trackAppSessions: Bool, autoSessionTrackingInterval: Int) {
        self.trackAppSessions = trackAppSessions
        self.autoSessionTrackingInterval = autoSessionTrackingInterval

        if trackAppSessions {
            // swiftlint:disable:next todo
            // TODO: to be implemented
        }
    }
}

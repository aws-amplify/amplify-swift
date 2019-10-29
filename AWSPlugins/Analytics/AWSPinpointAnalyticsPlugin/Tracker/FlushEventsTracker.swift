//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class FlushEventsTracker: Tracker {
    /// The amount of time to wait in between submitting events
    var autoFlushEventsInterval: Int!

    /// The timer scheduled for flushing events on every `autoSessionTrackingInterval` seconds
    var autoFlushEventsTimer: RepeatingTimer?

    public init(autoFlushEventsInterval: Int) {
        self.autoFlushEventsInterval = autoFlushEventsInterval
        if autoFlushEventsInterval != 0 {
            // TODO: to be implemented
            self.autoFlushEventsTimer = RepeatingTimer()
        }
    }
}

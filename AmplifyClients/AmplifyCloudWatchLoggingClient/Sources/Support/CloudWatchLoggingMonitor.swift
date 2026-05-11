//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Provides a monitor to automatically flush the log at a specific TimeInterval.
class CloudWatchLoggingMonitor {
    private let automaticFlushLogsInterval: TimeInterval
    private var automaticFlushLogsTimer: DispatchSourceTimer? {
        willSet {
            automaticFlushLogsTimer?.cancel()
        }
    }

    private weak var eventDelegate: CloudWatchLoggingMonitorDelegate?

    init(flushIntervalInSeconds: TimeInterval, eventDelegate: CloudWatchLoggingMonitorDelegate?) {
        self.automaticFlushLogsInterval = flushIntervalInSeconds
        self.eventDelegate = eventDelegate
    }

    func setAutomaticFlushIntervals() {
        guard automaticFlushLogsInterval != .zero else {
            automaticFlushLogsTimer = nil
            return
        }

        automaticFlushLogsTimer = createRepeatingTimer(
            timeInterval: automaticFlushLogsInterval,
            eventHandler: { [weak self] in
                guard let self else { return }
                eventDelegate?.handleAutomaticFlushIntervalEvent()
            }
        )
        automaticFlushLogsTimer?.resume()
    }

    func createRepeatingTimer(timeInterval: TimeInterval, eventHandler: @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
        timer.setEventHandler(handler: eventHandler)
        return timer
    }
}

protocol CloudWatchLoggingMonitorDelegate: AnyObject {
    func handleAutomaticFlushIntervalEvent()
}

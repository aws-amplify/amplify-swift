//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A simple implementation of a stopwatch used for gathering metrics of elapsed time.
class Stopwatch {
    let lock = NSLock()
    var startTime: DispatchTime?
    var lapStart: DispatchTime?

    /// Marks the beginning of the stopwatch.
    /// If called multiple times, the latest call will overwrite the previous start values.
    func start() {
        lock.lock()
        defer {
            lock.unlock()
        }
        startTime = DispatchTime.now()
        lapStart = startTime
    }

    /// Returns the elapsed time since `start()` or the last `lap()` was called.
    ///
    /// - Returns: the elapsed time in seconds
    func lap() -> Double {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard let lapStart = lapStart else {
            return 0
        }

        let lapEnd = DispatchTime.now()
        let lapTime = Double(lapEnd.uptimeNanoseconds - lapStart.uptimeNanoseconds) / 1_000_000_000.0
        self.lapStart = lapEnd
        return lapTime
    }

    /// Returns the total time from the initial `start()` call and resets the stopwatch.
    ///
    /// - Returns: the total time in seconds that the stop watch has been running, or 0
    func stop() -> Double {
        lock.lock()
        defer {
            lapStart = nil
            startTime = nil
            lock.unlock()
        }
        guard let startTime = startTime else {
            lapStart = nil
            return 0
        }
        let endTime = DispatchTime.now()
        let total = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000.0
        self.startTime = nil
        lapStart = nil
        return total
    }
}

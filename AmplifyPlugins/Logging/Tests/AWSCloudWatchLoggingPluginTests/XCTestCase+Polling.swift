//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import XCTest

extension XCTestCase {

    /// Polls `condition` until it holds, or until `timeout` passes.
    func waitUntil(timeout: TimeInterval = 5, _ condition: () async -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await condition() { return true }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return await condition()
    }

    /// Polls `condition` for `duration`, and returns false as soon as it stops holding.
    func staysTrue(for duration: TimeInterval, _ condition: () async -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(duration)
        while Date() < deadline {
            if await !condition() { return false }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return await condition()
    }

    /// Runs `body` on its own utility `Thread` (a dispatch queue would starve) while every utility cooperative thread is held.
    func whileCooperativePoolIsBusy(_ body: @escaping @Sendable () -> Void) async {
        let width = ProcessInfo.processInfo.activeProcessorCount
        let held = AtomicValue(initialValue: 0)
        let released = AtomicValue(initialValue: false)
        let holders = (0 ..< width).map { _ in
            Task.detached(priority: .utility) {
                _ = held.increment()
                while !released.get() {
                    usleep(100)
                }
            }
        }
        await withCheckedContinuation { continuation in
            let thread = Thread {
                let deadline = Date().addingTimeInterval(2)
                while held.get() < width, Date() < deadline {
                    usleep(100)
                }
                body()
                released.set(true)
                continuation.resume()
            }
            thread.qualityOfService = .utility
            thread.start()
        }
        for holder in holders {
            await holder.value
        }
    }
}

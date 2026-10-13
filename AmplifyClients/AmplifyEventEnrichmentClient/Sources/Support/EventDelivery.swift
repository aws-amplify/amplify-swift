//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Builds an event stamped with the current user ID and global fields.
typealias EventFactory = @Sendable (
    _ eventType: String,
    _ session: Session,
    _ attributes: [String: String],
    _ metrics: [String: Double]
) -> EnrichedEvent

/// An event waiting for the sink, with the signal its `record()` caller waits on.
struct Delivery: Sendable {
    let event: EnrichedEvent
    let sent: DeliverySignal?
}

/// Lets one waiter suspend until the consumer has sent its event.
final class DeliverySignal: @unchecked Sendable {
    private let lock = NSLock()
    private var isSignaled = false
    private var waiter: CheckedContinuation<Void, Never>?

    func signal() {
        lock.lock()
        isSignaled = true
        let waiter = waiter
        self.waiter = nil
        lock.unlock()
        waiter?.resume()
    }

    func wait() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lock.lock()
            if isSignaled {
                lock.unlock()
                continuation.resume()
            } else {
                waiter = continuation
                lock.unlock()
            }
        }
    }
}

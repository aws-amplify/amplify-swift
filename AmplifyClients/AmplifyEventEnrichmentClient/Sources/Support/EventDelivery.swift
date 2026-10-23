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
/// With no event, it only signals once everything queued before it has been sent.
struct Delivery: Sendable {
    let event: EnrichedEvent?
    let sent: DeliverySignal?
}

/// Lets one waiter suspend until the consumer has sent its event.
final class DeliverySignal: @unchecked Sendable {
    private let lock = NSLock()
    private var isSignaled = false
    private var waiter: CheckedContinuation<Void, Never>?

    func signal() {
        let waiter = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            isSignaled = true
            let waiter = self.waiter
            self.waiter = nil
            return waiter
        }
        waiter?.resume()
    }

    func wait() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let alreadySignaled = lock.withLock {
                if !isSignaled { waiter = continuation }
                return isSignaled
            }
            if alreadySignaled { continuation.resume() }
        }
    }
}

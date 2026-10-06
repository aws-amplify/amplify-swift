//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Fans one session's events out to every current subscriber.
///
/// `AsyncStream` has a single consumer, so one shared stream cannot serve two listeners. Instead
/// each `events()` call makes a fresh stream and registers its continuation here, and `send(_:)`
/// yields to all of them. One instance per session, with nothing shared between instances, so one
/// session's events can never reach, or be suppressed by, another session's stream.
///
/// - **No replay.** A subscriber receives only what is sent after it subscribed. Where a session
///   stands now is a question for its current state, not for its event history.
/// - **One order.** Delivery happens under the lock, so concurrent `send(_:)` calls are seen in the
///   same order by every subscriber.
/// - **Termination removes the subscriber.** When a stream ends — its consuming task is cancelled
///   or `finish()` is called — its continuation is dropped, so an abandoned listener is not kept
///   alive. A stream that is never iterated is not detectable as abandoned, since the continuation
///   held here keeps it alive; it is released by `finish()` or when the broadcaster is released.
/// - **Finishing is final.** After `finish()`, or once the broadcaster is released, every stream has
///   ended, later `send(_:)` calls are ignored, and a later `events()` returns a stream that is
///   already finished, so a `for await` loop over it exits rather than hanging.
///
/// Buffering is unbounded. These are coarse lifecycle events, a handful per session lifetime, so a
/// slow consumer holding a few is preferable to one silently missing a `signedOut`.
///
/// A lock-guarded class rather than an actor, because `events()` is synchronous: the facade's
/// `listenToAuthEvents()` returns a stream directly, and a subscription must be in place when it
/// returns, or an event sent right after would be lost.
final class SessionEventStream<Event: Sendable>: @unchecked Sendable {

    private let lock = NSLock()
    private var subscribers: [UInt64: AsyncStream<Event>.Continuation] = [:]
    private var nextSubscriberID: UInt64 = 0
    private var isFinished = false

    init() {}

    deinit {
        // Without this, a released broadcaster would leave every subscriber's loop waiting forever:
        // dropping a continuation does not end its stream.
        finish()
    }

    /// A new stream that receives every event sent from now on.
    func events() -> AsyncStream<Event> {
        let (stream, continuation) = AsyncStream<Event>.makeStream(bufferingPolicy: .unbounded)

        lock.lock()
        guard !isFinished else {
            lock.unlock()
            continuation.finish()
            return stream
        }
        let id = nextSubscriberID
        nextSubscriberID &+= 1
        subscribers[id] = continuation
        lock.unlock()

        // Installed after registering, and outside the lock, because `onTermination` can run
        // synchronously when it is set on a stream that has already been terminated, and it takes
        // the lock. Weak, because the continuation, and so this closure, is held by `self`.
        continuation.onTermination = { [weak self] _ in
            self?.removeSubscriber(id)
        }
        return stream
    }

    /// Delivers `event` to every live subscriber. Ignored once finished.
    func send(_ event: Event) {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else {
            return
        }
        // Yielding does not call `onTermination`, so doing it under the lock cannot re-enter it.
        for (id, continuation) in subscribers {
            if case .terminated = continuation.yield(event) {
                subscribers[id] = nil
            }
        }
    }

    /// Ends every stream. Final: later subscribers receive an already-finished stream.
    func finish() {
        lock.lock()
        isFinished = true
        let ending = subscribers.values
        subscribers = [:]
        lock.unlock()

        // Outside the lock: `finish()` calls each stream's `onTermination`, which takes the lock.
        for continuation in ending {
            continuation.finish()
        }
    }

    /// The number of streams currently registered.
    var subscriberCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return subscribers.count
    }

    private func removeSubscriber(_ id: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        subscribers[id] = nil
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A convenience class for managing an Operation Queue that dispatches Hub messages
final class HubChannelDispatcher {
    /// The message queue to which the message operations are added
    private let messageQueue: OperationQueue

    /// A dictionary of listeners, keyed by their ID
    /// Reads and write should be protected by the lock.
    private var listenersById = [UUID: FilteredListener]()

    /// Lock to protect shared mutable state of `listenersById` dictionary.
    private let lock: UnsafeMutablePointer<os_unfair_lock> = {
        let pointer = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock())
        return pointer
    }()

    init() {
        self.messageQueue = OperationQueue()
        messageQueue.name = "com.amazonaws.HubChannelDispatcher"
        messageQueue.maxConcurrentOperationCount = 1
    }

    /// Returns true if the dispatcher has a listener registered with `id`
    ///
    /// - Parameter id: The ID of the listener to check
    /// - Returns: True if the dispatcher has a listener registered with `id`
    func hasListener(withId id: UUID) -> Bool {
        defer { os_unfair_lock_unlock(lock) }
        os_unfair_lock_lock(lock)
        return listenersById[id] != nil
    }

    /// Inserts `listener` into the `listenersById` dictionary by its ID
    ///
    /// - Parameter listener: The listener to add
    func insert(_ listener: FilteredListener) {
        defer { os_unfair_lock_unlock(lock) }
        os_unfair_lock_lock(lock)
        listenersById[listener.id] = listener
    }

    /// Removes the listener identified by `id` from the `listeners` dictionary
    ///
    /// - Parameter id: The ID of the listener to remove
    func removeListener(withId id: UUID) {
        defer { os_unfair_lock_unlock(lock) }
        os_unfair_lock_lock(lock)
        listenersById[id] = nil
    }

    /// Dispatches `payload` to all listeners on `channel`
    ///
    /// Internally, this method creates a HubDispatchOperation and adds it to the OperationQueue
    ///
    /// - Parameters:
    ///   - channel: The channel to dispatch to
    ///   - payload: The HubPayload to dispatch
    func dispatch(to channel: HubChannel, payload: HubPayload) {
        let hubDispatchOperation = HubDispatchOperation(for: channel, payload: payload, delegate: self)
        messageQueue.addOperation(hubDispatchOperation)
    }

    /// Cancels all operation and removes listeners.
    ///
    /// This method is only used during the `reset` flow, which is only invoked during tests. Although the method
    /// cancels in-process operations and waits for them to complete, it does not attempt to assert anything about
    /// whether a given listener closure has completed. If your test encounters errors like "Hub is not configured"
    /// after you issue an `await Amplify.reset()`, you may wish to add additional sleep around your code
    /// that calls `await Amplify.reset()`.
    func destroy() async {
        listenersById.removeAll()
        messageQueue.cancelAllOperations()
        await withCheckedContinuation { continuation in
            messageQueue.addBarrierBlock {
                continuation.resume()
            }
        }
    }
}

extension HubChannelDispatcher: HubDispatchOperationDelegate {
    var listeners: [FilteredListener] {
        os_unfair_lock_lock(lock)
        let listeners = listenersById.map(\.value)
        os_unfair_lock_unlock(lock)
        return listeners
    }
}

protocol HubDispatchOperationDelegate: AnyObject {
    /// Used to let a dispatch operation retrieve the list of listeners at the time of invocation, rather than the time
    /// of queuing.
    var listeners: [FilteredListener] { get async }
}

final class HubDispatchOperation: Operation {

    private static let thresholdForConcurrentPerform = 500

    private var payload: HubPayload
    private var channel: HubChannel
    private var dispatcher: Dispatcher?

    weak var delegate: HubDispatchOperationDelegate?

    /// Creates a new HubDispatchOperation. When the operation is started, it will retrieve the current list of
    /// listeners via the `getListeners` closure, then filter and invoke the payload for each listener. The listener
    /// will be invoked on the main queue.
    ///
    /// - Parameters:
    ///   - channel: The channel on which this dispatch operation is delivering messages
    ///   - payload: The HubPayload to dispatch
    ///   - delegate: A delegate used to retrieve the listeners to dispatch to
    init(for channel: HubChannel, payload: HubPayload, delegate: HubDispatchOperationDelegate) {
        self.channel = channel
        self.payload = payload
        self.delegate = delegate
    }

    override func cancel() {
        super.cancel()
        dispatcher?.isCancelled = true
    }

    override func main() {
        guard !isCancelled else {
            return
        }

        Task {
            guard let listeners = await delegate?.listeners else {
                return
            }

            let dispatcher = SerialDispatcher(channel: channel, payload: payload)
            dispatcher.dispatch(to: listeners)
        }
    }

}

/// A Dispatcher fans out a single payload to a group of listeners
protocol Dispatcher {
    var isCancelled: Bool { get set }
    func dispatch(to listeners: [FilteredListener])
}

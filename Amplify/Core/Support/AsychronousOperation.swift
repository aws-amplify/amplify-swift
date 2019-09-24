//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

open class AsynchronousOperation: Operation {

    /// State for this operation.
    @objc private enum OperationState: Int {
        case notRunning
        case executing
        case finished
    }

    /// Concurrent queue for synchronizing access to `state`.
    private let stateQueue = DispatchQueue(label: "com.amazonaws.AsynchronousOperation", attributes: .concurrent)

    /// Private backing stored property for `state`.
    private var _state: OperationState = .notRunning

    /// The state of the operation
    @objc private dynamic var state: OperationState {
        get { return stateQueue.sync { _state } }
        set { stateQueue.async(flags: .barrier) { self._state = newValue } }
    }

    // MARK: - Various `Operation` properties
    open override var isReady: Bool { return state == .notRunning && super.isReady }
    public final override var isExecuting: Bool { return state == .executing }
    public final override var isFinished: Bool { return state == .finished }

    // KVN for dependent properties
    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }

        return super.keyPathsForValuesAffectingValue(forKey: key)
    }

    // Start
    public final override func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .executing
        main()
    }

    /// Subclasses must implement this to perform their work and they must not call `super`.
    /// The default implementation of this function throws an exception.
    open override func main() {
        fatalError("Subclasses must implement `main`.")
    }

    // Call this function to pause an operation that is currently executing
    open func pause() {
        if isExecuting {
            state = .notRunning
        }
    }

    // Call this function to resume an operation that is currently ready
    open func resume() {
        if isReady {
            state = .executing
        }
    }

    /// Call this function to finish an operation that is currently executing
    public final func finish() {
        if !isFinished {
            state = .finished
        }
    }
}

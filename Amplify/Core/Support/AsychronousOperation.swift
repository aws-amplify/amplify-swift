//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// This class is to facilitate executing asychronous requests. The caller can transition the operation to its finished
/// state by calling finish() in the callback of an asychronous request to ensure that the operation is only removed
/// from the OperationQueue after it has completed all its work. This class is not inherently thread safe. Although it
/// is a subclass of Foundation's Operation, it contains private state to support pausing, resuming, and finishing, that
/// must be managed by callers.
open class AsynchronousOperation: Operation, @unchecked Sendable {

    /// State for this operation.
    @objc private enum OperationState: Int {
        case notExecuting
        case executing
        case finished
    }

    /// Synchronizes access to `state`.
    private let stateQueue = DispatchQueue(
        label: "com.amazonaws.amplify.AsynchronousOperation.state",
        target: DispatchQueue.global()
    )

    /// Private backing stored property for `state`.
    private var _state: OperationState = .notExecuting

    /// The state of the operation
    @objc private dynamic var state: OperationState {
        get { return stateQueue.sync { _state } }
        set { stateQueue.sync { self._state = newValue } }
    }

    // MARK: - Various `Operation` properties

    /// `true` if the operation is ready to be executed
    override open var isReady: Bool {
        return state == .notExecuting && super.isReady
    }

    /// `true` if the operation is currently executing
    override public final var isExecuting: Bool {
        return state == .executing
    }

    /// `true` if the operation has completed executing, either successfully or with an error
    override public final var isFinished: Bool {
        return state == .finished
    }

    /// KVN for dependent properties
    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }

        return super.keyPathsForValuesAffectingValue(forKey: key)
    }

    /// Starts the operation
    override public final func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .executing
        main()
    }

    /// Subclasses must implement this to perform their work and they must not call `super`.
    /// The default implementation of this function throws an exception.
    override open func main() {
        fatalError("Subclasses must implement `main`.")
    }

    /// Call this function to pause an operation that is currently executing
    open func pause() {
        if isExecuting {
            state = .notExecuting
        }
    }

    /// Call this function to resume an operation that is currently ready
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

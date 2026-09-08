//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - Result/Value -

public protocol InternalTaskResult {
    associatedtype Success
    associatedtype Failure: AmplifyError
    typealias TaskResult = Result<Success, Failure>
    var result: TaskResult { get async }
}

public protocol InternalTaskValue {
    associatedtype Success
    associatedtype Failure: AmplifyError
    var value: Success { get async throws }
}

// MARK: - Sequences -

public protocol InternalTaskInProcess {
    associatedtype InProcess: Sendable
    var inProcess: AmplifyAsyncSequence<InProcess> { get async }
}

public struct InternalTaskAsyncSequenceContext<InProcess: Sendable> {
    public let bufferingPolicy: AsyncStream<InProcess>.Continuation.BufferingPolicy
    public var weakSequenceRef: WeakAmplifyAsyncSequenceRef<InProcess>
    public var task: Task<Void, Error>?
    public var sequence: AmplifyAsyncSequence<InProcess>? {
        get {
            weakSequenceRef.value
        }
        set {
            weakSequenceRef.value = newValue
        }
    }

    public init(bufferingPolicy: AsyncStream<InProcess>.Continuation.BufferingPolicy = .unbounded) {
        self.bufferingPolicy = bufferingPolicy
        self.weakSequenceRef = WeakAmplifyAsyncSequenceRef(nil)
    }
}

public protocol InternalTaskAsyncSequence: AnyObject {
    associatedtype InProcess: Sendable
    var context: InternalTaskAsyncSequenceContext<InProcess> { get set }
    var sequence: AmplifyAsyncSequence<InProcess> { get }
}

public struct InternalTaskAsyncThrowingSequenceContext<InProcess: Sendable> {
    public let bufferingPolicy: AsyncThrowingStream<InProcess, Error>.Continuation.BufferingPolicy
    public var weakSequenceRef: WeakAmplifyAsyncThrowingSequenceRef<InProcess>
    public var task: Task<Void, Error>?
    public var sequence: AmplifyAsyncThrowingSequence<InProcess>? {
        get {
            weakSequenceRef.value
        }
        set {
            weakSequenceRef.value = newValue
        }
    }

    public init(bufferingPolicy: AsyncThrowingStream<InProcess, Error>.Continuation.BufferingPolicy = .unbounded) {
        self.bufferingPolicy = bufferingPolicy
        self.weakSequenceRef = WeakAmplifyAsyncThrowingSequenceRef(nil)
    }
}

public protocol InternalTaskAsyncThrowingSequence: AnyObject {
    associatedtype InProcess: Sendable
    var context: InternalTaskAsyncThrowingSequenceContext<InProcess> { get set }
    var sequence: AmplifyAsyncThrowingSequence<InProcess> { get }
}

public protocol InternalTaskChannel {
    associatedtype InProcess: Sendable

    /// Sends element to sequence
    /// - Parameter element: element
    func send(_ element: InProcess)

    /// Terminates sequence
    func finish()
}

public protocol InternalTaskThrowingChannel {
    associatedtype InProcess: Sendable

    /// Sends element to sequence
    /// - Parameter element: element
    func send(_ element: InProcess)

    /// Fails sequence
    /// - Parameter error: error
    func fail(_ error: Error)

    /// Terminates sequence
    func finish()
}

// MARK: - Control -

/// - Note: `Sendable` because the whole point of a runner is that `run()` is driven from a
///   detached `Task`, so conformers already cross concurrency domains. Requiring it here is
///   what lets `InternalTask+AsyncSequence` start that task without sending a non-`Sendable`
///   `self`.
public protocol InternalTaskRunner: AnyObject, AmplifyCancellable, Sendable {
    associatedtype Request: AmplifyOperationRequest
    var request: Request { get }

    /// Run task
    func run() async throws
}

public protocol InternalTaskController {
    func pause()
    func resume()
    func cancel()
}

// MARK: - Hub Support -

/// - Note: `Sendable` because `idFilter` builds a `@Sendable` Hub filter that closes over `self`.
public protocol InternalTaskIdentifiable: Sendable {
    associatedtype Request: AmplifyOperationRequest
    var id: UUID { get }
    var request: Request { get }
    var categoryType: CategoryType { get }
    var eventName: HubPayloadEventName { get }
}

/// - Note: `Sendable` because the Hub listener built below closes over `self`.
public protocol InternalTaskHubResult: Sendable {
    associatedtype Request: AmplifyOperationRequest
    associatedtype Success
    associatedtype Failure: AmplifyError

    typealias OperationResult = Result<Success, Failure>
    typealias ResultListener = @Sendable (OperationResult) -> Void

    /// Subscribe for result
    /// - Parameter resultListener: result listener
    /// - Returns: unsubscribe token
    func subscribe(resultListener: @escaping ResultListener) -> UnsubscribeToken

    /// Unsubscribe from Hub channel
    /// - Parameter token: unsubscribe token
    func unsubscribe(_ token: UnsubscribeToken)

    /// Dispatch result to Hub channel
    /// - Parameter result: result
    func dispatch(result: OperationResult)
}

/// - Note: `Sendable` for the same reason as `InternalTaskHubResult`.
public protocol InternalTaskHubInProcess: Sendable {
    associatedtype Request: AmplifyOperationRequest
    associatedtype InProcess: Sendable

    typealias InProcessListener = @Sendable (InProcess) -> Void

    /// Subscribe for result
    /// - Parameter resultListener: result listener
    /// - Returns: unsubscribe token
    func subscribe(inProcessListener: @escaping InProcessListener) -> UnsubscribeToken

    /// Unsubscribe from Hub channel
    /// - Parameter token: unsubscribe token
    func unsubscribe(_ token: UnsubscribeToken)

    /// Dispatch value to sequence
    /// - Parameter inProcess: InProcess value
    func dispatch(inProcess: InProcess)
}

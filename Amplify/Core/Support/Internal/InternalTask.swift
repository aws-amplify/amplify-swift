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
    func send(_ element: InProcess)
    func finish()
}

public protocol InternalTaskThrowingChannel {
    associatedtype InProcess: Sendable
    func send(_ element: InProcess)
    func fail(_ error: Error)
    func finish()
}

// MARK: - Control -

public protocol InternalTaskRunner: AnyObject, AmplifyCancellable {
    associatedtype Request: AmplifyOperationRequest
    var request: Request { get }
    func run() async throws
}

public protocol InternalTaskController {
    func pause()
    func resume()
    func cancel()
}

// MARK: - Hub Support -

public protocol InternalTaskIdentifiable {
    associatedtype Request: AmplifyOperationRequest
    var id: UUID { get }
    var request: Request { get }
    var categoryType: CategoryType { get }
    var eventName: HubPayloadEventName { get }
}

public protocol InternalTaskHubResult {
    associatedtype Request: AmplifyOperationRequest
    associatedtype Success
    associatedtype Failure: AmplifyError

    typealias OperationResult = Result<Success, Failure>
    typealias ResultListener = (OperationResult) -> Void

    func subscribe(resultListener: @escaping ResultListener) -> UnsubscribeToken
    func unsubscribe(_ token: UnsubscribeToken)
    func dispatch(result: OperationResult)
}

public protocol InternalTaskHubInProcess {
    associatedtype Request: AmplifyOperationRequest
    associatedtype InProcess: Sendable

    typealias InProcessListener = (InProcess) -> Void

    func subscribe(inProcessListener: @escaping InProcessListener) -> UnsubscribeToken
    func unsubscribe(_ token: UnsubscribeToken)
    func dispatch(inProcess: InProcess)
}

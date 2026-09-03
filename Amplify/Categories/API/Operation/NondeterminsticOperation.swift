//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

/**
 A non-deterministic operation offers multiple paths to accomplish its task.
 It attempts the next path if all preceding paths have failed with an error that allows for continuation.
 */
enum NondeterminsticOperationError: Error {
    case totalFailure
    case cancelled
}

/// - Note: `@unchecked Sendable` because `_cancellables` and `_task` are mutable but every
///   access is serialized by `lock`.
final class NondeterminsticOperation<T: Sendable>: @unchecked Sendable {
    /// operation that to be eval
    // Both closures are handed to a `Task` and yielded through an `AsyncStream`, so they
    // must be `@Sendable` under the Swift 6 language mode.
    typealias Operation = @Sendable () async throws -> T
    typealias OnError = @Sendable (Error) -> Bool

    private let operations: AsyncStream<Operation>

    /// Immutable now that it is assigned once in `init`, which is what removes it from the
    /// mutable state the lock below has to cover.
    private let shouldTryNextOnError: OnError

    /// Guards `_cancellables` and `_task`.
    private let lock = NSLock()
    private var _cancellables = Set<AnyCancellable>()
    private var _task: Task<Void, Never>?

    private var cancellables: Set<AnyCancellable> {
        get { lock.withLock { _cancellables } }
        set { lock.withLock { _cancellables = newValue } }
    }

    private var task: Task<Void, Never>? {
        get { lock.withLock { _task } }
        set { lock.withLock { _task = newValue } }
    }

    deinit {
        cancel()
    }

    init(operations: AsyncStream<Operation>, shouldTryNextOnError: OnError? = nil) {
        self.operations = operations
        self.shouldTryNextOnError = shouldTryNextOnError ?? { _ in true }
    }

    convenience init(
        operationStream: AnyPublisher<Operation, Never>,
        shouldTryNextOnError: OnError? = nil
    ) {
        var cancellables = Set<AnyCancellable>()
        let (asyncStream, continuation) = AsyncStream.makeStream(of: Operation.self)
        operationStream.sink { _ in
            continuation.finish()
        } receiveValue: {
            continuation.yield($0)
        }.store(in: &cancellables)

        self.init(
            operations: asyncStream,
            shouldTryNextOnError: shouldTryNextOnError
        )
        self.cancellables = cancellables
    }

    /// Synchronous version of executing the operations
    func execute() -> Future<T, Error> {
        Future { [weak self] promise in
            // `Future.Promise` is not `Sendable`; Combine calls it at most once, so moving it
            // into the task is safe.
            let promise = UncheckedSendable(promise)
            self?.task = Task { [weak self] in
                do {
                    if let self {
                        try await promise.value(.success(run()))
                    } else {
                        promise.value(.failure(NondeterminsticOperationError.cancelled))
                    }
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
    }

    /// Asynchronous version of executing the operations
    func run() async throws -> T {
        for await operation in operations {
            if Task.isCancelled {
                throw NondeterminsticOperationError.cancelled
            }
            do {
                return try await operation()
            } catch {
                if shouldTryNextOnError(error) {
                    continue
                } else {
                    throw error
                }
            }
        }
        throw NondeterminsticOperationError.totalFailure
    }

    /// Cancel the operation
    func cancel() {
        task?.cancel()
        cancellables = Set<AnyCancellable>()
    }
}

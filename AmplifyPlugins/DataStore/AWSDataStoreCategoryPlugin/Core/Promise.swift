//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Promise represents a runnable computation and a continuation closure on the result
struct Promise<Output, Failure: Error> {
    typealias Closure = (Result<Output, Failure>) -> Void
    private let run: (@escaping Closure) -> Void
    private let dispatchQueue: DispatchQueue

    init(
        runOn dispatchQueue: DispatchQueue = .global(),
        run: @escaping (@escaping Closure) -> Void
    ) {
        self.dispatchQueue = dispatchQueue
        self.run = run
    }

    func execute(_ closure: @escaping Closure) {
        dispatchQueue.async {
            self.run(closure)
        }
    }
}

// MARK: - operators
extension Promise {

    /// map operator applies transform function on the computation result
    /// - Parameters:
    ///     - transform: A closure that take the success return value of the computation and
    ///         transform it to a new type of output
    ///     - runOn: DispatchQueue that new promise runnable will be running on
    ///     - receiveOn: DispatchQueue that new promise closure will be running on
    /// - Returns:
    ///     - A promise wraps the current promise as runnable and
    ///     triggers the closure on designated closure dispatchQueue
    func map<NextOutput>(
        _ transform: @escaping (Output) -> NextOutput,
        runOn dispatchQueue: DispatchQueue = .global(),
        receiveOn closureDispatchQueue: DispatchQueue? = nil
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure>(runOn: dispatchQueue) { nextOutputCallback in
            self.execute { outputResult in
                Self.tryExecuteOn(closureDispatchQueue) { nextOutputCallback(outputResult.map(transform)) }
            }
        }
    }

    /// flatMapOnResult operator applies transform function on the computation result
    /// - Parameters:
    ///     - transform: A closure that takes the success return value of the computation
    ///         and return a new result
    ///     - runOn: DispatchQueue that new promise runnable will be running on
    ///     - receiveOn: DispatchQueue that new promise closure will be running on
    /// - Returns:
    ///     - A promise wraps the current promise as runnable and
    ///     triggers the closure on designated closure dispatchQueue
    ///
    func flatMapOnResult<NextOutput>(
        _ transform: @escaping (Output) -> Result<NextOutput, Failure>,
        runOn dispatchQueue: DispatchQueue = .global(),
        receiveOn closureDispatchQueue: DispatchQueue? = nil
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure>(runOn: dispatchQueue) { nextOutputCallback in
            self.execute { outputResult in
                Self.tryExecuteOn(closureDispatchQueue) { nextOutputCallback(outputResult.flatMap(transform)) }
            }
        }
    }

    /// flatMap operator applies transform function on the computation result
    /// - Parameters:
    ///     - transform: A closure that takes the success return value of the computation
    ///         and return a new Promise
    ///     - runOn: DispatchQueue that new promise runnable will be running on
    ///     - receiveOn: DispatchQueue that new promise closure will be running on
    /// - Returns:
    ///     - A promise:
    ///         - wraps the current promise as runnable
    ///         - executes the transformed promise and
    ///         - triggers the closure on designated closure dispatchQueue
    ///
    func flatMap<NextOutput>(
        _ transform: @escaping (Output) -> Promise<NextOutput, Failure>,
        runOn dispatchQueue: DispatchQueue = .global(),
        receiveOn closureDispatchQueue: DispatchQueue? = nil
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure>(runOn: dispatchQueue) { nextOutputCallback in
            self.execute { outputResult in
                switch outputResult.map(transform) {
                case .success(let nextPromise):
                    nextPromise.execute { nextOutput in
                        Self.tryExecuteOn(closureDispatchQueue) { nextOutputCallback(nextOutput) }
                    }
                case .failure(let error):
                    Self.tryExecuteOn(closureDispatchQueue) { nextOutputCallback(.failure(error)) }
                }
            }
        }
    }

    private static func tryExecuteOn(_ dispatchQueue: DispatchQueue?, runnable: @escaping () -> Void) {
        if let dispatchQueue = dispatchQueue {
            dispatchQueue.async {
                runnable()
            }
        } else {
            runnable()
        }
    }
}

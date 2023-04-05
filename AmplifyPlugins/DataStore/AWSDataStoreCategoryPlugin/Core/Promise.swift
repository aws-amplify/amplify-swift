//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Promise represents a computation that take a continuation closure on the result
struct Promise<Output, Failure: Error> {

    /// Continuation closure type, take computation result as input and no return value
    typealias Closure = (Result<Output, Failure>) -> Void

    /// the computation that take the continuation closure
    private let run: (@escaping Closure) -> Void

    /// the dispatch queue that computation runs on
    private let runDispatchQueue: DispatchQueue

    /// the dispatch queue that continuation closure runs on.
    /// if not privided, use the computation thread.
    private let receiveDisptachQueue: DispatchQueue?

    init(
        runOn runDispatchQueue: DispatchQueue = .global(),
        receiveOn receiveDispatchQueue: DispatchQueue? = nil,
        run: @escaping (@escaping Closure) -> Void
    ) {
        self.runDispatchQueue = runDispatchQueue
        self.receiveDisptachQueue = receiveDispatchQueue
        self.run = run
    }

    /// take a continuation closure and trigger it when computation is done
    func execute(_ closure: @escaping Closure) {
        runDispatchQueue.async {
            self.run { result in
                if let receiveDisptachQueue = receiveDisptachQueue {
                    receiveDisptachQueue.async {
                        closure(result)
                    }
                } else {
                    closure(result)
                }
            }
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
        runOn runDispatchQueue: DispatchQueue = .global(),
        receiveOn receiveDispatchQueue: DispatchQueue? = nil
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure>(
            runOn: runDispatchQueue,
            receiveOn: receiveDispatchQueue
        ) { nextOutputCallback in
            self.execute { outputResult in
                nextOutputCallback(outputResult.map(transform))
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
        runOn runDispatchQueue: DispatchQueue = .global(),
        receiveOn receiveDispatchQueue: DispatchQueue? = nil
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure>(
            runOn: runDispatchQueue,
            receiveOn: receiveDispatchQueue
        ) { nextOutputCallback in
            self.execute { outputResult in
                nextOutputCallback(outputResult.flatMap(transform))
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
        runOn runDispatchQueue: DispatchQueue = .global(),
        receiveOn receiveDispatchQueue: DispatchQueue? = nil
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure>(
            runOn: runDispatchQueue,
            receiveOn: receiveDispatchQueue
        ) { nextOutputCallback in
            self.execute { outputResult in
                switch outputResult.map(transform) {
                case .success(let nextPromise):
                    nextPromise.execute { nextOutput in
                       nextOutputCallback(nextOutput)
                    }
                case .failure(let error):
                    nextOutputCallback(.failure(error))
                }
            }
        }
    }

}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

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

    func exec(_ closure: @escaping Closure) {
        dispatchQueue.async {
            self.run(closure)
        }
    }
}

// MARK: - operators
extension Promise {

    // Promise Result A -> A -> B -> Promise Result B
    func map<NextOutput>(
        _ transform: @escaping (Output) -> NextOutput
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure> { nextOutputCallback in
            self.exec { outputResult in
                nextOutputCallback(outputResult.map(transform))
            }
        }
    }

    // Promise Result A -> A -> Result B -> Promise Result B
    func flatMapOnResult<NextOutput>(
        _ transform: @escaping (Output) -> Result<NextOutput, Failure>
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure> { nextOutputCallback in
            self.exec { outputResult in
                nextOutputCallback(outputResult.flatMap(transform))
            }
        }
    }

    // Promise Result A -> A -> Promise Result B -> Promise Result B
    func flatMap<NextOutput>(
        _ transform: @escaping (Output) -> Promise<NextOutput, Failure>
    ) -> Promise<NextOutput, Failure> {
        Promise<NextOutput, Failure> { nextOutputCallback in
            self.exec { outputResult in
                switch outputResult.map(transform) {
                case .success(let nextPromise):
                    nextPromise.exec { nextOutput in
                        nextOutputCallback(nextOutput)
                    }
                case .failure(let error):
                    nextOutputCallback(.failure(error))
                }
            }
        }
    }
}

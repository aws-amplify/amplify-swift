//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class StateAsyncSequence<Element: Sendable>: AsyncSequence {

    typealias Iterator = AsyncStream<Element>.Iterator
    private var continuation: AsyncStream<Element>.Continuation! = nil

    private var asyncStream: AsyncStream<Element>! = nil

    init(bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded) {
        asyncStream = AsyncStream<Element>(
            Element.self,
            bufferingPolicy: bufferingPolicy) { continuation in
                self.continuation = continuation
            }
    }

    func makeAsyncIterator() -> Iterator {
        asyncStream.makeAsyncIterator()
    }

    func send(_ element: Element) {
        continuation.yield(element)
    }

    func cancel() {
        continuation.finish()
    }
}

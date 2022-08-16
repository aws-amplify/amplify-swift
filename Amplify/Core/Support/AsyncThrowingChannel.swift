//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AsyncThrowingChannel<Element: Sendable>: AsyncSequence {
    public typealias Iterator = AsyncThrowingStream<Element, Error>.Iterator
    private var asyncStream: AsyncThrowingStream<Element, Error>! = nil
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation! = nil

    public init(bufferingPolicy: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy = .unbounded) {
        asyncStream = AsyncThrowingStream(Element.self, bufferingPolicy: bufferingPolicy, { continuation in
            self.continuation = continuation
        })
    }

    public func makeAsyncIterator() -> Iterator {
        asyncStream.makeAsyncIterator()
    }

    public func send(_ element: Element) {
        continuation.yield(element)
    }

    public func fail(_ error: Error) {
        continuation.yield(with: .failure(error))
        continuation.finish()
    }

    public func finish() {
        continuation.finish()
    }
}

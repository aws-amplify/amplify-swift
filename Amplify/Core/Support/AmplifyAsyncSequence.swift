//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AmplifyAsyncSequence<Element: Sendable>: AsyncSequence, Cancellable {
    public typealias Iterator = AsyncStream<Element>.Iterator
    private var asyncStream: AsyncStream<Element>! = nil
    private var continuation: AsyncStream<Element>.Continuation! = nil
    private var parent: Cancellable? = nil

    public init(parent: Cancellable? = nil,
                bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded) {
        self.parent = parent
        asyncStream = AsyncStream<Element>(Element.self, bufferingPolicy: bufferingPolicy) { continuation in
            self.continuation = continuation
        }
    }

    public func makeAsyncIterator() -> Iterator {
        asyncStream.makeAsyncIterator()
    }

    public func send(_ element: Element) {
        continuation.yield(element)
    }

    public func finish() {
        continuation.finish()
    }

    public func cancel() {
        finish()
        parent?.cancel()
    }
}

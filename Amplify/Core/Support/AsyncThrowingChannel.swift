//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public actor AsyncThrowingChannel<Element: Sendable, Failure: Error>: AsyncSequence {
    public struct Iterator: AsyncIteratorProtocol, Sendable {
        private let channel: AsyncThrowingChannel<Element, Failure>

        public init(_ channel: AsyncThrowingChannel<Element, Failure>) {
            self.channel = channel
        }

        public mutating func next() async throws -> Element? {
            try Task.checkCancellation()
            return try await channel.next()
        }
    }

    public enum InternalFailure: Error {
        case cannotSendAfterTerminated
    }
    public typealias ChannelContinuation = CheckedContinuation<Element?, Error>

    private var continuations: [ChannelContinuation] = []
    private var elements: [Element] = []
    private var cancelled: Bool = false
    private var terminated: Bool = false
    private var error: Error? = nil

    private var hasNext: Bool {
        !continuations.isEmpty && !elements.isEmpty
    }

    private var canFail: Bool {
        error != nil && !continuations.isEmpty
    }

    private var canTerminate: Bool {
        terminated && elements.isEmpty && !continuations.isEmpty
    }

    init() {
    }

    public nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(self)
    }

    public func next() async throws -> Element? {
        if cancelled {
            throw CancellationError()
        }
        return try await withCheckedThrowingContinuation { (continuation: ChannelContinuation) in
            continuations.append(continuation)
            processNext()
        }
    }

    public func send(_ element: Element) throws {
        if Task.isCancelled {
            cancelled = true
            processNext()
            throw CancellationError()
        }
        guard !terminated else {
            throw InternalFailure.cannotSendAfterTerminated
        }
        elements.append(element)
        processNext()
    }

    public func fail(_ error: Error) where Failure == Error {
        self.error = error
        processNext()
    }

    public func finish() {
        terminated = true
        processNext()
    }

    private func processNext() {
        if cancelled && !continuations.isEmpty {
            let continuation = continuations.removeFirst()
            assert(continuations.isEmpty)
            continuation.resume(throwing: CancellationError())
            return
        }

        if canFail {
            let continuation = continuations.removeFirst()
            assert(continuations.isEmpty)
            assert(elements.isEmpty)
            assert(error != nil)
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
        }

        if canTerminate {
            let continuation = continuations.removeFirst()
            assert(continuations.isEmpty)
            assert(elements.isEmpty)
            continuation.resume(returning: nil)
            return
        }

        guard hasNext else {
            return
        }

        assert(!continuations.isEmpty)
        assert(!elements.isEmpty)

        let continuation = continuations.removeFirst()
        let element = elements.removeFirst()

        continuation.resume(returning: element)
    }
}

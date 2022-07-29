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
            try await channel.next()
        }
    }

    public enum InternalFailure: Error {
        case cannotSendAfterTerminated
    }
    public typealias ChannelContinuation = CheckedContinuation<Element?, Error>

    private var continuations: [ChannelContinuation] = []
    private var elements: [Element] = []
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

    public init() {
    }

    public nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(self)
    }

    public func next() async throws -> Element? {
        try await withCheckedThrowingContinuation { (continuation: ChannelContinuation) in
            continuations.append(continuation)
            processNext()
        }
    }

    public func send(_ element: Element) throws {
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
        if canFail {
            let contination = continuations.removeFirst()
            assert(continuations.isEmpty)
            assert(elements.isEmpty)
            assert(error != nil)
            if let error = error {
                contination.resume(throwing: error)
                return
            }
        }

        if canTerminate {
            let contination = continuations.removeFirst()
            assert(continuations.isEmpty)
            assert(elements.isEmpty)
            contination.resume(returning: nil)
            return
        }

        guard hasNext else {
            return
        }

        assert(!continuations.isEmpty)
        assert(!elements.isEmpty)

        let contination = continuations.removeFirst()
        let element = elements.removeFirst()

        contination.resume(returning: element)
    }
}

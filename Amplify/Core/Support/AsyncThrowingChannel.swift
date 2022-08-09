//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

actor AsyncThrowingChannel<Element: Sendable, Failure: Error>: AsyncSequence {
    struct Iterator: AsyncIteratorProtocol, Sendable {
        private let channel: AsyncThrowingChannel<Element, Failure>

        init(_ channel: AsyncThrowingChannel<Element, Failure>) {
            self.channel = channel
        }

        mutating func next() async throws -> Element? {
            try await channel.next()
        }
    }

    enum InternalFailure: Error {
        case cannotSendAfterTerminated
    }
    typealias ChannelContinuation = CheckedContinuation<Element?, Error>

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

    init() {
    }

    nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(self)
    }

    func next() async throws -> Element? {
        try await withCheckedThrowingContinuation { (continuation: ChannelContinuation) in
            continuations.append(continuation)
            processNext()
        }
    }

    func send(_ element: Element) throws {
        guard !terminated else {
            throw InternalFailure.cannotSendAfterTerminated
        }
        elements.append(element)
        processNext()
    }


    func fail(_ error: Error) where Failure == Error {
        self.error = error
        processNext()
    }

    func finish() {
        terminated = true
        processNext()
    }

    private func processNext() {
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

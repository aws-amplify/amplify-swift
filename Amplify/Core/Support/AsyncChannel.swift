//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public actor AsyncChannel<Element: Sendable>: AsyncSequence {
    public struct Iterator: AsyncIteratorProtocol, Sendable {
        private let channel: AsyncChannel<Element>

        public init(_ channel: AsyncChannel<Element>) {
            self.channel = channel
        }

        public mutating func next() async -> Element? {
            Task.isCancelled ? nil : await channel.next()
        }
    }

    public enum InternalFailure: Error {
        case cannotSendAfterTerminated
    }
    public typealias ChannelContinuation = CheckedContinuation<Element?, Never>

    private var continuations: [ChannelContinuation] = []
    private var elements: [Element] = []
    private var cancelled: Bool = false
    private var terminated: Bool = false

    private var hasNext: Bool {
        !continuations.isEmpty && !elements.isEmpty
    }

    private var canTerminate: Bool {
        terminated && elements.isEmpty && !continuations.isEmpty
    }

    init() {
    }

    public nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(self)
    }

    public func next() async -> Element? {
        if cancelled || terminated {
            return nil
        }
        return await withCheckedContinuation { (continuation: ChannelContinuation) in
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

    public func finish() {
        terminated = true
        processNext()
    }

    private func processNext() {
        if cancelled && !continuations.isEmpty {
            let continuation = continuations.removeFirst()
            assert(continuations.isEmpty)
            continuation.resume(returning: nil)
            return
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

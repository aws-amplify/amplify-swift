//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

actor AsyncChannel<Element: Sendable>: AsyncSequence {
    struct Iterator: AsyncIteratorProtocol, Sendable {
        private let channel: AsyncChannel<Element>

        init(_ channel: AsyncChannel<Element>) {
            self.channel = channel
        }

        mutating func next() async -> Element? {
            await channel.next()
        }
    }

    enum InternalFailure: Error {
        case cannotSendAfterTerminated
    }
    typealias ChannelContinuation = CheckedContinuation<Element?, Never>

    private var continuations: [ChannelContinuation] = []
    private var elements: [Element] = []
    private var terminated: Bool = false

    private var hasNext: Bool {
        !continuations.isEmpty && !elements.isEmpty
    }

    private var canTerminate: Bool {
        terminated && elements.isEmpty && !continuations.isEmpty
    }

    init() {
    }

    nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(self)
    }

    func next() async -> Element? {
        await withCheckedContinuation { (continuation: ChannelContinuation) in
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

    func finish() {
        terminated = true
        processNext()
    }

    private func processNext() {
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

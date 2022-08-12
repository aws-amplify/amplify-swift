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
        private var active = true

        public init(_ channel: AsyncThrowingChannel<Element, Failure>) {
            self.channel = channel
        }

        public mutating func next() async throws -> Element? {
            guard active else {
                return nil
            }
            do {
                let value: Element? = try await withTaskCancellationHandler { [channel] in
                    Task {
                        await channel.cancel()
                    }
                } operation: {
                    try await channel.next()
                }

                if let value = value {
                    return value
                } else {
                    active = false
                    return nil
                }
            } catch {
                active = false
                throw error
            }
        }
    }

    typealias NextContinuation = CheckedContinuation<Element?, Error>
    typealias SendContinuation = CheckedContinuation<Void, Never>

    private var elements: [Element] = []
    private var nexts: [NextContinuation] = []
    private var sends: [SendContinuation] = []
    private var terminated: Bool = false

    init() {
    }

    public nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(self)
    }

    public func next() async throws -> Element? {
        try await withCheckedThrowingContinuation { (continuation: NextContinuation) in
            nexts.append(continuation)
            processNext()
        }
    }

    func send(_ element: Element) async {
        await withTaskCancellationHandler {
            Task {
                await terminateAll()
            }
        } operation: {
            await withCheckedContinuation { (continuation: SendContinuation) in
                elements.append(element)
                sends.append(continuation)
                processNext()
            }
        }
    }

    func terminateAll(error: Failure? = nil) {
        terminated = true
        while !sends.isEmpty {
            let send = sends.removeFirst()
            send.resume(returning: ())
        }
        while !nexts.isEmpty {
            let next = nexts.removeFirst()
            if let error = error {
                next.resume(throwing: error)
            } else {
                next.resume(returning: nil)
            }
        }
    }

    func fail(_ error: Error) where Failure == Error {
        terminateAll(error: error)
    }

    func finish() {
        terminateAll()
    }

    func cancel() {
        terminateAll()
    }

    private func processNext() {
        if terminated && !nexts.isEmpty {
            let next = nexts.removeFirst()
            next.resume(returning: nil)
            return
        }

        guard !elements.isEmpty,
              !sends.isEmpty,
              !nexts.isEmpty else {
            return
        }

        assert(!elements.isEmpty)
        assert(!nexts.isEmpty)
        assert(!sends.isEmpty)

        let element = elements.removeFirst()
        let send = sends.removeFirst()
        let next = nexts.removeFirst()

        next.resume(returning: element)
        send.resume(returning: ())
    }
}

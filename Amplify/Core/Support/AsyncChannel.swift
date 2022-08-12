//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public actor AsyncChannel<Element: Sendable>: AsyncSequence {
    public struct Iterator: AsyncIteratorProtocol, Sendable {
        private let channel: AsyncChannel<Element>
        private var active = true

        public init(_ channel: AsyncChannel<Element>) {
            self.channel = channel
        }

        public mutating func next() async -> Element? {
            guard active else {
                return nil
            }
            let value: Element? = await withTaskCancellationHandler { [channel] in
                Task {
                    await channel.cancel()
                }
            } operation: {
                await channel.next()
            }

            if let value = value {
                return value
            } else {
                active = false
                return nil
            }
        }
    }

    typealias NextContinuation = CheckedContinuation<Element?, Never>
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

    public func next() async -> Element? {
        await withCheckedContinuation { (continuation: NextContinuation) in
            nexts.append(continuation)
            processNext()
        }
    }

    // send should not continue until there is a matched next or task is cancelled
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

    private func terminateAll() {
        terminated = true
        while !sends.isEmpty {
            let send = sends.removeFirst()
            send.resume(returning: ())
        }
        while !nexts.isEmpty {
            let next = nexts.removeFirst()
            next.resume(returning: nil)
        }
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

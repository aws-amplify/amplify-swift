//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Combine

class CancellableAsyncStream<T>: AsyncSequence {

    typealias AsyncIterator = AsyncStream<T>.AsyncIterator

    typealias Element = T

    private let asyncStream: AsyncStream<T>

    private let cancellable: AnyCancellable?

    deinit {
        cancel()
    }

    init(asyncStream: AsyncStream<T>, canellable: AnyCancellable?) {
        self.asyncStream = asyncStream
        self.cancellable = canellable
    }

    convenience init(with source: AnyPublisher<T, Never>) {
        var cancellable: AnyCancellable?
        self.init(asyncStream: AsyncStream { continuation in
            cancellable = source.sink { _ in
                continuation.finish()
            } receiveValue: {
                continuation.yield($0)
            }
        }, canellable: cancellable)
    }

    func makeAsyncIterator() -> AsyncStream<T>.AsyncIterator {
        asyncStream.makeAsyncIterator()
    }

    func cancel() {
        cancellable?.cancel()
    }
}

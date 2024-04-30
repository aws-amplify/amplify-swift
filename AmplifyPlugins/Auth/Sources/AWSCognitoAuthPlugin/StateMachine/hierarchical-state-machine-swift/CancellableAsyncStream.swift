//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

class CancellableAsyncStream<Element>: AsyncSequence {

    typealias AsyncIterator = AsyncStream<Element>.AsyncIterator
    private let asyncStream: AsyncStream<Element>
    private let cancellable: AnyCancellable?

    deinit {
        cancel()
    }

    init(asyncStream: AsyncStream<Element>, cancellable: AnyCancellable?) {
        self.asyncStream = asyncStream
        self.cancellable = cancellable
    }

    convenience init(with publisher: AnyPublisher<Element, Never>) {
        var cancellable: AnyCancellable?
        self.init(asyncStream: AsyncStream { continuation in
            cancellable = publisher.sink { _ in
                continuation.finish()
            } receiveValue: {
                continuation.yield($0)
            }
        }, cancellable: cancellable)
    }

    func makeAsyncIterator() -> AsyncStream<Element>.AsyncIterator {
        asyncStream.makeAsyncIterator()
    }

    func cancel() {
        cancellable?.cancel()
    }
}

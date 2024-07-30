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
        let (asyncStream, contiuation) = AsyncStream.makeStream(of: Element.self)
        let cancellable = publisher.sink { _ in
            contiuation.finish()
        } receiveValue: {
            contiuation.yield($0)
        }

        self.init(asyncStream: asyncStream, cancellable: cancellable)
    }

    func makeAsyncIterator() -> AsyncStream<Element>.AsyncIterator {
        asyncStream.makeAsyncIterator()
    }

    func cancel() {
        cancellable?.cancel()
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

/// - Note: `final` and `@unchecked Sendable`: both stored properties are `let`, but `AnyCancellable`
///   is not declared `Sendable`. The stream is awaited from the auth tasks, which are `Sendable`.
final class CancellableAsyncStream<Element: Sendable>: AsyncSequence, @unchecked Sendable {

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

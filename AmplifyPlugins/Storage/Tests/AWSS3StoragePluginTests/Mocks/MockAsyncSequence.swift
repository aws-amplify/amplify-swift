//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Tag: MockAsyncSequence
final class MockAsyncSequence<Element> {

    /// - Tag: MockAsyncSequence.elements
    var elements: [Result<Element, Error>] = []

    /// - Tag: MockAsyncSequence.init
    init(elements: [Result<Element, Error>]) {
        self.elements = elements
    }
}

extension MockAsyncSequence: AsyncSequence {
    typealias Element = Element
    typealias AsyncIterator = MockAsyncIterator<Element>
    func makeAsyncIterator() -> AsyncIterator {
        return MockAsyncIterator(iterator: elements.makeIterator())
    }
}

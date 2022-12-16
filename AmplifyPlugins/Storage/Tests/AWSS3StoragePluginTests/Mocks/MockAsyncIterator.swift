//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Tag: MockAsyncIterator
final class MockAsyncIterator<Element> {

    /// - Tag: MockAsyncIterator.iterator
    var iterator: any IteratorProtocol<Result<Element, Error>>

    /// - Tag: MockAsyncIterator.init
    init(iterator: any IteratorProtocol<Result<Element, Error>>) {
        self.iterator = iterator
    }
}

extension MockAsyncIterator: AsyncIteratorProtocol {
    func next() async throws -> Element? {
        guard let result = iterator.next() else {
            return nil
        }
        switch result {
        case .failure(let error): throw error
        case .success(let element): return element
        }
    }
}

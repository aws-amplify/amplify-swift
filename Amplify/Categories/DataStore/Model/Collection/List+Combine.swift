//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

@available(iOS 13.0, *)
extension List {

    public typealias LazyListPublisher = AnyPublisher<Elements, DataStoreError>

    /// Lazy load the collection and expose the loaded `Elements` as a Combine `Publisher`.
    /// This is useful for integrating the `List<ModelType>` with existing Combine code
    /// and/or SwiftUI.
    ///
    /// - Returns: a type-erased Combine publisher
    public func loadAsPublisher() -> LazyListPublisher {
        return Future { promise in
            self.load {
                switch $0 {
                case .success(let elements):
                    promise(.success(elements))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}

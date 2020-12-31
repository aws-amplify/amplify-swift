//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

@available(iOS 13.0, *)
extension List {

    public typealias LazyListPublisher = AnyPublisher<[Element], DataStoreError>

    /// This method has been deprecated, Use load(completion:) instead.
    ///
    /// Lazy load the collection and expose the loaded `Elements` as a Combine `Publisher`. The List will retrieve the
    /// data from the underlying data source before the publisher is returned. This is useful for integrating the
    /// `List<ModelType>` with existing Combine code and/or SwiftUI. This method has been deprecated
    /// and is currently not a supported API.
    ///
    /// - Returns: a type-erased Combine publisher
    @available(*, deprecated, message: "Use `load(completion:)` instead.")
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

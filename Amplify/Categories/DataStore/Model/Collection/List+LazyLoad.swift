//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// This extension adds lazy load logic to the `List<ModelType>`. Lazy loading means
/// the contents of a list that represents an association between two models will only be
/// loaded when it's needed.
extension List {

    /// Represents the data state of the `List`.
    internal enum LoadState {
        case pending
        case loaded
    }

    // MARK: - Asynchronous API

    /// Trigger `DataStore` query to initialize the collection. This function always
    /// fetches data from the `DataStore.query`.
    ///
    /// - seealso: `load()`
    public func load(_ completion: DataStoreCallback<Elements>) {
        lazyLoad(completion)
    }

    internal func lazyLoad(_ completion: DataStoreCallback<Elements>) {

        // if the collection has no associated field, return the current elements
        guard let associatedId = self.associatedId,
              let associatedField = self.associatedField else {
            completion(.success(elements))
            return
        }

        // TODO: this is currently done by specific plugin implementations (API or DataStore)
        // How to add this name resolution to Amplify?
        let modelName = Element.modelName
        var name = modelName.camelCased() + associatedField.name.pascalCased() + "Id"
        if case let .belongsTo(_, targetName) = associatedField.association {
            name = targetName ?? name
        }

        let predicate: QueryPredicate = field(name) == associatedId
        Amplify.DataStore.query(Element.self, where: predicate) {
            switch $0 {
            case .success(let elements):
                self.elements = elements
                self.state = .loaded
                completion(.success(elements))
            case .failure(let error):
                completion(.failure(causedBy: error))
            }
        }
    }

    // MARK: - Synchronous API

    /// Trigger `DataStore` query to initialize the collection. This function always
    /// fetches data from the `DataStore.query`. However, consumers must be aware of
    /// the internal behavior which relies on `DispatchSemaphore` and will block the
    /// current `DispatchQueue` until data is ready. When operating on large result
    /// sets, prefer using the asynchronous `load(completion:)` instead.
    ///
    /// - Returns: the current instance after data was loaded.
    /// - seealso: `load(completion:)`
    public func load() -> Self {
        lazyLoad()
        return self
    }

    /// Internal function that only calls `lazyLoad()` if the `state` is not `.loaded`.
    /// - seealso: `lazyLoad()`
    internal func loadIfNeeded() {
        if state != .loaded {
            lazyLoad()
        }
    }

    /// The synchronized version of `lazyLoad(completion:)`. This function is useful so
    /// instances of `List<ModelType>` behave like any other `Collection`.
    internal func lazyLoad() {
        let semaphore = DispatchSemaphore(value: 0)
        lazyLoad {
            switch $0 {
            case .success(let elements):
                self.elements = elements
                semaphore.signal()
            case .failure(let error):
                semaphore.signal()
                // TODO how to handle this failure? should it crash? just log the error?
                fatalError(error.errorDescription)
            }
        }
        semaphore.wait()
    }

}

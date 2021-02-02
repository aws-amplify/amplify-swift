//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// This extension adds lazy load logic to the `List<ModelType>`. Lazy loading means
/// the contents of a list that represents an association between two models will only be
/// loaded when it's needed.
extension List {

    // MARK: - Asynchronous API

    /// Call this to initialize the collection if you have retrieved the list by traversing from your model objects
    /// to its associated children objects. For example, a Post model may contain a list of Comments. By retrieving the
    /// post object and traversing to the comments, the comments are not retrieved from the data source until this
    /// method is called. Data will be retrieved based on the plugin's data source and may have different failure
    /// conditions--for example, a data source that requires network connectivity may fail if the network is
    /// unavailable. Alternately, you can trigger an implicit `fetch` by invoking the Collection methods (such as using
    /// `map`, or iterating in a `for/in` loop) on the List, which will retrieve data if it hasn't already been
    /// retrieved. In such cases, the time to perform that operation will include the time required to request data
    /// from the underlying data source.
    ///
    /// If you have directly created this list object (for example, by calling `List(elements:)`) then the collection
    /// has already been initialized and calling this method will have no effect.
    public func fetch(_ completion: @escaping (Result<Void, CoreError>) -> Void) {
        guard case .notLoaded = loadedState else {
            completion(.successfulVoid)
            return
        }

        listProvider.load { result in
            switch result {
            case .success(let elements):
                self.elements = elements
                completion(.success(()))
            case .failure(let coreError):
                completion(.failure(coreError))
            }
        }
    }

    /// Call this to initialize the collection if you have retrieved the list by traversing from your model objects
    /// to its associated children objects. For example, a Post model may contain a list of Comments. By retrieving the
    /// post object and traversing to the comments, the comments are not retrieved from the data source until this
    /// method is called. Data will be retrieved based on the plugin's data source and may have different failure
    /// conditions--for example, a data source that requires network connectivity may fail if the network is
    /// unavailable. Alternately, you can trigger an implicit `load` by invoking the Collection methods (such as using
    /// `map`, or iterating in a `for/in` loop) on the List, which will retrieve data if it hasn't already been
    /// retrieved. In such cases, the time to perform that operation will include the time required to request data
    /// from the underlying data source.
    ///
    /// If you have directly created this list object (for example, by calling `List(elements:)`) then the collection
    /// has already been initialized and calling this method will have no effect.
    @available(*, deprecated, message: "Use fetch(completion:) instead.")
    public func load(_ completion: DataStoreCallback<[Element]>) {
        if case .loaded(let elements) = loadedState {
            completion(.success(elements))
            return
        }
        let result = listProvider.load()
        switch result {
        case .success(let elements):
            self.elements = elements
            completion(.success(elements))
        case .failure(let coreError):
            switch coreError {
            case .listOperation(_, _, let error),
                 .clientValidation(_, _, let error):
                completion(.failure(causedBy: error ?? coreError))
            }
        }
    }

    // MARK: - Synchronous API

    /// This method has been deprecated, Use load(completion:) instead.
    ///
    /// Load data into the collection from the data source. Consumers must be aware of
    /// the internal behavior which relies on `DispatchSemaphore` and will block the
    /// current `DispatchQueue` until data is ready. When operating on large result
    /// sets, prefer using the asynchronous `load(completion:)` instead.
    ///
    /// - Returns: the current instance after data was loaded.
    /// - seealso: `load(completion:)`
    @available(*, deprecated, message: "Use fetch(completion:) instead.")
    public func load() -> Self {
        guard case .notLoaded = loadedState else {
            return self
        }
        let result = listProvider.load()
        switch result {
        case .success(let elements):
            self.elements = elements
        case .failure(let error):
            Amplify.log.error(error: error)
            assert(false, error.errorDescription)
        }
        return self
    }
}

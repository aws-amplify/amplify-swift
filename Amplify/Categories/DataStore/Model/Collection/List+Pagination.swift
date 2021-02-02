//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension List {

    /// Check if there is subsequent data to retrieve. If true, the next page can be retrieved using
    /// `getNextPage(completion:)`. Calling `hasNextPage()` will load the underlying elements from the data source if not yet
    /// loaded before.
    public func hasNextPage() -> Bool {
        switch loadedState {
        case .loaded:
            return listProvider.hasNextPage()
        case .notLoaded:
            let result = listProvider.load()
            switch result {
            case .success(let elements):
                self.elements = elements
                return listProvider.hasNextPage()
            case .failure(let coreError):
                Amplify.log.error(error: coreError)
                return false
            }
        }
    }

    /// Retrieve the next page as a new in-memory List object. Calling `getNextPage(completion:)` will load the
    /// underlying elements of the receiver from the data source if not yet loaded before
    public func getNextPage(completion: @escaping (Result<List<Element>, CoreError>) -> Void) {
        switch loadedState {
        case .loaded:
            listProvider.getNextPage(completion: completion)
        case .notLoaded:
            let result = listProvider.load()
            switch result {
            case .success(let elements):
                self.elements = elements
                listProvider.getNextPage(completion: completion)
            case .failure(let coreError):
                Amplify.log.error(error: coreError)
                completion(.failure(coreError))
            }
        }
    }
}

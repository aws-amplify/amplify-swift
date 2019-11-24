//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol LoadableCollection {

//    associatedtype ModelType

    func load() -> Self
}

extension List {

    internal enum LoadStatus {
        case pending
        case loaded
    }

    /// Trigger `DataStore` query to initialize the collection. This function always
    /// fetches data from the `DataStore.query`
    public func load() -> Self {
        lazyLoad()
        return self
    }

    internal func loadIfNeeded() {
        if status != .loaded {
            lazyLoad()
        }
    }

    internal func lazyLoad() {
        // check if the list is associated with a associated Model
        guard let associatedId = self.associatedId,
              let associatedField = self.associatedField else {
            return
        }

        let semaphore = DispatchSemaphore(value: 0)

        let name = "\(associatedField.name)Id"
        let predicate = { field(name) == associatedId }
        Amplify.DataStore.query(Element.self, where: predicate) {
            switch $0 {
            case .result(let elements):
                self.elements = elements
                self.status = .loaded
                semaphore.signal()
            case .error(let error):
                semaphore.signal()
                // TODO should we crash? or silently fail and warn? Hub event?
                fatalError(error.errorDescription)
            }
        }
        semaphore.wait()
    }

}

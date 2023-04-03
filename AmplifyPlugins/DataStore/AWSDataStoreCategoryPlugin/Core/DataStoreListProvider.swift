//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

/// `DataStoreList<ModelType>` is a DataStore-aware custom `Collection` that is capable of loading
/// records from the `DataStore` on-demand. This is especially useful when dealing with
/// Model associations that need to be lazy loaded.
///
/// When using `DataStore.query(_ modelType:)` some models might contain associations
/// with other models and those aren't fetched automatically. This collection keeps track
/// of the associated `id` and `field` and fetches the associated data on demand.
public class DataStoreListProvider<Element: Model>: ModelListProvider {

    /// The current state of lazily loaded list
    enum LoadedState {
        /// If the list represents an association between two models, the `associatedId` will
        /// hold the information necessary to query the associated elements (e.g. comments of a post)
        ///
        /// The associatedField represents the field to which the owner of the `List` is linked to.
        /// For example, if `Post.comments` is associated with `Comment.post` the `List<Comment>`
        /// of `Post` will have a reference to the `post` field in `Comment`.
        case notLoaded(associatedId: Model.Identifier, associatedField: String)

        case loaded([Element])
    }

    var loadedState: LoadedState

    init(associatedId: Model.Identifier,
         associatedField: String) {
        self.loadedState = .notLoaded(associatedId: associatedId,
                                      associatedField: associatedField)
    }

    init(_ elements: [Element]) {
        self.loadedState = .loaded(elements)
    }

    public func load() -> Result<[Element], CoreError> {
        let semaphore = DispatchSemaphore(value: 0)
        var loadResult: Result<[Element], CoreError> = .failure(
            .listOperation("DataStore query failed to complete.",
                           AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                           nil))
        load { result in
            defer {
                semaphore.signal()
            }
            switch result {
            case .success(let elements):
                loadResult = .success(elements)
            case .failure(let error):
                Amplify.DataStore.log.error(error: error)
                assert(false, error.errorDescription)
                loadResult = .failure(error)
            }
        }
        semaphore.wait()
        return loadResult
    }

    public func load(completion: @escaping (Result<[Element], CoreError>) -> Void) {
        switch loadedState {
        case .loaded(let elements):
            completion(.success(elements))
        case .notLoaded(let associatedId, let associatedField):
            let predicate: QueryPredicate = field(associatedField) == associatedId
            Amplify.DataStore.query(Element.self, where: predicate) {
                switch $0 {
                case .success(let elements):
                    self.loadedState = .loaded(elements)
                    completion(.success(elements))
                case .failure(let error):
                    Amplify.DataStore.log.error(error: error)
                    completion(.failure(CoreError.listOperation("Failed to Query DataStore.",
                                                                "See underlying DataStoreError for more details.",
                                                                error)))
                }
            }
        }
    }

    public func hasNextPage() -> Bool {
        false
    }

    public func getNextPage(completion: (Result<List<Element>, CoreError>) -> Void) {
        completion(.failure(CoreError.clientValidation("There is no next page.",
                                                       "Only call `getNextPage()` when `hasNextPage()` is true.",
                                                       nil)))
    }
}

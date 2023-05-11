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

    var loadedState: ModelListProviderState<Element>

    init(associatedIdentifiers: [String],
         associatedField: String) {
        self.loadedState = .notLoaded(
            associatedIdentifiers: associatedIdentifiers,
            associatedField: associatedField)
    }

    init(_ elements: [Element]) {
        self.loadedState = .loaded(elements)
    }

    public func getState() -> ModelListProviderState<Element> {
        switch loadedState {
        case .notLoaded(let associatedIdentifiers, let associatedField):
            return .notLoaded(associatedIdentifiers: associatedIdentifiers, associatedField: associatedField)
        case .loaded(let elements):
            return .loaded(elements)
        }
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

    public func load(completion: (Result<[Element], CoreError>) -> Void) {
        switch loadedState {
        case .loaded(let elements):
            completion(.success(elements))
        case .notLoaded(let associatedIdentifiers, let associatedField):
            guard let associatedId = associatedIdentifiers.first else {
                let error = CoreError.listOperation("Unexpected identifiers.",
                                                    "See underlying DataStoreError for more details.", nil)
                completion(.failure(error))
                return
            }
            log.verbose("Loading List of \(Element.schema.name) by \(associatedField) == \(associatedId) ")
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

    public func encode(to encoder: Encoder) throws {
        fatalError("To be implemented")
    }
}

extension DataStoreListProvider: DefaultLogger { }

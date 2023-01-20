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
        self.loadedState = .notLoaded(associatedIdentifiers: associatedIdentifiers,
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
    
    public func load() async throws -> [Element] {
        switch loadedState {
        case .loaded(let elements):
            return elements
        case .notLoaded(let associatedIdentifiers, let associatedField):
            guard let associatedId = associatedIdentifiers.first else {
                throw CoreError.listOperation("Unexpected identifiers.",
                                              "See underlying DataStoreError for more details.", nil)
            }
            self.log.verbose("Loading List of \(Element.schema.name) by \(associatedField) == \(associatedId) ")
            let predicate: QueryPredicate = field(associatedField) == associatedId
            do {
                let elements = try await Amplify.DataStore.query(Element.self, where: predicate)
                self.loadedState = .loaded(elements)
                return elements
            } catch let error as DataStoreError {
                self.log.error(error: error)
                throw CoreError.listOperation("Failed to Query DataStore.",
                                              "See underlying DataStoreError for more details.",
                                              error)
            } catch {
                throw error
                
            }
        }
    }

    public func hasNextPage() -> Bool {
        false
    }
    
    public func getNextPage() async throws -> List<Element> {
        throw CoreError.clientValidation("There is no next page.",
                                         "Only call `getNextPage()` when `hasNextPage()` is true.",
                                         nil)
    }
    
    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded(let associatedIdentifiers,
                        let associatedField):
            
            if let associatedId = associatedIdentifiers.first {
                let metadata = DataStoreListDecoder.Meetadata(associatedId: associatedId,
                                                              associatedField: associatedField)
                var container = encoder.singleValueContainer()
                try container.encode(metadata)
            }
            
            
        case .loaded(let elements):
            try elements.encode(to: encoder)
        }
    }
}

extension DataStoreListProvider: DefaultLogger { }

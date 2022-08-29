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
        case notLoaded(associatedId: String, associatedField: String)

        case loaded([Element])
    }

    var loadedState: LoadedState

    init(associatedId: String,
         associatedField: String) {
        self.loadedState = .notLoaded(associatedId: associatedId,
                                      associatedField: associatedField)
    }

    init(_ elements: [Element]) {
        self.loadedState = .loaded(elements)
    }
    
    public func getState() -> ModelListProviderState<Element> {
        switch loadedState {
        case .notLoaded:
            return .notLoaded
        case .loaded(let elements):
            return .loaded(elements)
        }
    }
    
    public func load() async throws -> [Element] {
        switch loadedState {
        case .loaded(let elements):
            return elements
        case .notLoaded(let associatedId, let associatedField):
            let predicate: QueryPredicate = field(associatedField) == associatedId
            do {
                let elements = try await Amplify.DataStore.query(Element.self, where: predicate)
                self.loadedState = .loaded(elements)
                return elements
            } catch let error as DataStoreError {
                Amplify.DataStore.log.error(error: error)
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
}

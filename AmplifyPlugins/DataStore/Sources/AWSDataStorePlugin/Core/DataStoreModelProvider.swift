//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

public class DataStoreModelProvider<ModelType: Model>: ModelProvider {
    
    enum LoadedState {
        case notLoaded(identifiers: [String: String])
        case loaded(model: ModelType?)
    }
    
    var loadedState: LoadedState
    
    convenience init(metadata: DataStoreModelIdentifierMetadata) {
        
        self.init(identifiers: [ModelType.schema.primaryKey.sqlName: metadata.identifier])
    }
    
    init(model: ModelType?) {
        self.loadedState = .loaded(model: model)
    }
    
    init(identifiers: [String: String]) {
        self.loadedState = .notLoaded(identifiers: identifiers)
    }
    
    // MARK: - APIs
    
    public func load() async throws -> ModelType? {
        switch loadedState {
        case .notLoaded(let identifiers):
            guard let identifier = identifiers.first else {
                return nil
            }
            let queryPredicate: QueryPredicate = field(identifier.key).eq(identifier.value)
            let models = try await Amplify.DataStore.query(ModelType.self, where: queryPredicate)
            guard let model = models.first else {
                return nil
            }
            self.loadedState = .loaded(model: model)
            return model
        case .loaded(let model):
            return model
        }
    }
    
    public func getState() -> ModelProviderState<ModelType> {
        switch loadedState {
        case .notLoaded(let identifiers):
            return .notLoaded(identifiers: identifiers)
        case .loaded(let model):
            return .loaded(model)
        }
    }
}

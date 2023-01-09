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
    var loadedState: ModelProviderState<ModelType>
    
    // Create a "not loaded" model provider with the identifier metadata, useful for hydrating the model
    init(metadata: DataStoreModelDecoder.Metadata) {
        if let identifier = metadata.identifier {
            self.loadedState = .notLoaded(identifiers: [.init(name: ModelType.schema.primaryKey.sqlName, value: identifier)])
        } else {
            self.loadedState = .notLoaded(identifiers: nil)
        }
    }
    
    // Create a "loaded" model provider with the model instance
    init(model: ModelType?) {
        self.loadedState = .loaded(model: model)
    }
    
    // MARK: - APIs
    
    public func load() async throws -> ModelType? {
        switch loadedState {
        case .notLoaded(let identifiers):
            guard let identifiers = identifiers, let identifier = identifiers.first else {
                return nil
            }
            let queryPredicate: QueryPredicate = field(identifier.name).eq(identifier.value)
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
        loadedState
    }
}

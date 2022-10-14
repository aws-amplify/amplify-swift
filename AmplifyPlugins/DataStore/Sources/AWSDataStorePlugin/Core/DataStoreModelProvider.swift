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
    
    init(model: ModelType?) {
        self.loadedState = .loaded(model: model)
    }
    
    init(identifier: String) {
        let identifiers: [String: String] = ["id": identifier]
        self.loadedState = .notLoaded(identifiers: identifiers)
    }
    
    // MARK: - APIs
    
    public func load() async throws -> ModelType? {
        switch loadedState {
        case .notLoaded(let identifiers):
            // TODO: identifers should allow us to pass in just the `id` or the composite key ?
            // or directly query against using the `@@primaryKey` ?
            guard let identifier = identifiers.first else {
                return nil
            }
            let model = try await Amplify.DataStore.query(ModelType.self, byId: identifier.value)
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

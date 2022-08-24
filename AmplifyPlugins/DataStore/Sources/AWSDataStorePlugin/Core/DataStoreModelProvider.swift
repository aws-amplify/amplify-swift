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
        case notLoaded(identifier: String)
        case loaded(model: ModelType?)
    }
    
    var loadedState: LoadedState
    
    init(model: ModelType?) {
        self.loadedState = .loaded(model: model)
    }
    
    init(identifier: String) {
        self.loadedState = .notLoaded(identifier: identifier)
    }
    
    // MARK: - APIs
    
    public func load() async throws -> ModelType? {
        switch loadedState {
        case .notLoaded(let identifier):
            let model = try await Amplify.DataStore.query(ModelType.self, byId: identifier)
            self.loadedState = .loaded(model: model)
            return model
        case .loaded(let model):
            return model
        }
    }
    
    public func getState() -> ModelProviderState<ModelType> {
        switch loadedState {
        case .notLoaded(let identifier):
            return .notLoaded(identifier: identifier)
        case .loaded(let model):
            return .loaded(model)
        }
    }
}

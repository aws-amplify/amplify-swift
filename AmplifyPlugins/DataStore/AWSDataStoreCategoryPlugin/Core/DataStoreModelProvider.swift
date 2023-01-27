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

            if #available(iOS 13.0, *) {
                let models = try await query(ModelType.self, where: queryPredicate)
                guard let model = models.first else {
                    return nil
                }
                self.loadedState = .loaded(model: model)
                return model

            } else {
                // Fallback on earlier versions
                return nil
            }

        case .loaded(let model):
            return model
        }
    }

    public func getState() -> ModelProviderState<ModelType> {
        loadedState
    }

    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded(let identifiers):
            if let identifier = identifiers?.first {
                let metadata = DataStoreModelDecoder.Metadata(identifier: identifier.value)
                var container = encoder.singleValueContainer()
                try container.encode(metadata)
            }

        case .loaded(let element):
            try element.encode(to: encoder)
        }
    }

    @available(iOS 13.0, *)
    private func query<M: Model>(_ modelType: M.Type,
                                 where predicate: QueryPredicate? = nil) async throws -> [M] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[M], Error>)  in
            Amplify.DataStore.query(modelType, where: predicate) { result in
                continuation.resume(with: result)
            }
        }
    }
}

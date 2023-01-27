//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

public class AppSyncModelProvider<ModelType: Model>: ModelProvider {

    let apiName: String?

    var loadedState: ModelProviderState<ModelType>

    // Creates a "not loaded" provider
    init(metadata: AppSyncModelDecoder.Metadata) {
        self.loadedState = .notLoaded(identifiers: metadata.identifiers)
        self.apiName = metadata.apiName
    }

    // Creates a "loaded" provider
    init(model: ModelType?) {
        self.loadedState = .loaded(model: model)
        self.apiName = nil
    }

    // MARK: - APIs

    public func load() async throws -> ModelType? {

        switch loadedState {
        case .notLoaded(let identifiers):
            guard let identifiers = identifiers else {
                loadedState = .loaded(model: nil)
                return nil
            }
            let request = GraphQLRequest<ModelType?>.getRequest(ModelType.self,
                                                                byIdentifiers: identifiers,
                                                                apiName: apiName)
            log.verbose("Loading \(ModelType.modelName) with \(identifiers)")

            do {
                if #available(iOS 13.0, *) {
                    let model = try await query(request: request)
                    self.loadedState = .loaded(model: model)
                    return model
                } else {
                    // Fallback on earlier versions
                    return nil
                }
            } catch {
                log.error(error: error)
                throw error
            }
        case .loaded(let element):
            return element
        }
    }

    public func getState() -> ModelProviderState<ModelType> {
        loadedState
    }

    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded(let identifiers):
            var container = encoder.singleValueContainer()
            try container.encode(identifiers)
        case .loaded(let element):
            try element.encode(to: encoder)
        }
    }

    @available(iOS 13.0, *)
    private func query<R: Decodable>(request: GraphQLRequest<R?>) async throws -> R? {

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<R?, Error>)  in

            Amplify.API.query(request: request) { result in
                switch result {
                case .success(let graphQLResponse):
                    switch graphQLResponse {
                    case .success(let decodable):
                        continuation.resume(with: .success(decodable))
                    case .failure(let error):
                        continuation.resume(with: .failure(error))
                    }
                case .failure(let error):
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }
}

extension AppSyncModelProvider: DefaultLogger { }

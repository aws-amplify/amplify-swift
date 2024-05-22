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
    let authMode: AWSAuthorizationType?
    let source: String
    var loadedState: ModelProviderState<ModelType>

    // Creates a "not loaded" provider
    init(metadata: AppSyncModelDecoder.Metadata) {
        self.loadedState = .notLoaded(identifiers: metadata.identifiers)
        self.apiName = metadata.apiName
        self.source = metadata.source
        self.authMode = metadata.authMode
    }

    // Creates a "loaded" provider
    init(model: ModelType?) {
        self.loadedState = .loaded(model: model)
        self.apiName = nil
        self.authMode = nil
        self.source = ModelProviderRegistry.DecoderSource.appSync
    }

    // MARK: - APIs

    public func load() async throws -> ModelType? {

        switch loadedState {
        case .notLoaded(let identifiers):
            guard let identifiers = identifiers else {
                self.loadedState = .loaded(model: nil)
                return nil
            }
            let request = GraphQLRequest<ModelType?>.getRequest(ModelType.self,
                                                                byIdentifiers: identifiers,
                                                                apiName: apiName, 
                                                                authMode: authMode)
            log.verbose("Loading \(ModelType.modelName) with \(identifiers)")
            let graphQLResponse = try await Amplify.API.query(request: request)
            switch graphQLResponse {
            case .success(let model):
                self.loadedState = .loaded(model: model)
                return model
            case .failure(let graphQLError):
                self.log.error(error: graphQLError)
                throw graphQLError
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
            let metadata = AppSyncModelDecoder.Metadata(
                identifiers: identifiers ?? [],
                apiName: apiName,
                authMode: authMode,
                source: source)
            try metadata.encode(to: encoder)

        case .loaded(let element):
            try element.encode(to: encoder)
        }
    }
}

extension AppSyncModelProvider: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}

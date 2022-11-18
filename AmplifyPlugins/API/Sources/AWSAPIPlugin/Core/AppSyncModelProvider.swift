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
    
    enum LoadedState {
        case notLoaded(identifiers: [LazyReferenceIdentifier])
        case loaded(model: ModelType?)
    }
    
    var loadedState: LoadedState
    
    // init(AppSyncModelMetadata) creates a notLoaded provider
    convenience init(metadata: AppSyncModelIdentifierMetadata) {
        self.init(identifiers: metadata.identifiers,
                  apiName: metadata.apiName)
    }
    
    // Initializer for a loaded state
    init(model: ModelType?) {
        self.loadedState = .loaded(model: model)
        self.apiName = nil
    }
    
    // Initializer for not loaded state
    init(identifiers: [LazyReferenceIdentifier], apiName: String? = nil) {
        self.loadedState = .notLoaded(identifiers: identifiers)
        self.apiName = apiName
    }
    
    
    // MARK: - APIs
    
    public func load() async throws -> ModelType? {
        
        switch loadedState {
        case .notLoaded(let identifiers):
            let identifiers = identifiers.map { identifier in
                return (name: identifier.name, value: identifier.value)
            }
            let request = GraphQLRequest<ModelType?>.getRequest(ModelType.self,
                                                                byIdentifiers: identifiers,
                                                                apiName: apiName)
            do {
                log.verbose("Loading \(ModelType.modelName) with \(identifiers)")
                let graphQLResponse = try await Amplify.API.query(request: request)
                switch graphQLResponse {
                case .success(let model):
                    self.loadedState = .loaded(model: model)
                    return model
                case .failure(let graphQLError):
                    self.log.error(error: graphQLError)
                    throw CoreError.operation(
                        "The AppSync response returned successfully with GraphQL errors.",
                        "Check the underlying error for the failed GraphQL response.",
                        graphQLError)
                }
            } catch let apiError as APIError {
                self.log.error(error: apiError)
                throw CoreError.operation("The AppSync request failed",
                                          "See underlying `APIError` for more details.",
                                          apiError)
            } catch {
                throw error
            }
        case .loaded(let element):
            return element
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

extension AppSyncModelProvider: DefaultLogger { }

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
                self.loadedState = .loaded(model: nil)
                return nil
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
                    // TODO: May want to return DataError instead.
                    throw CoreError.operation(
                        "The AppSync response returned successfully with GraphQL errors.",
                        "Check the underlying error for the failed GraphQL response.",
                        graphQLError)
                }
            } catch let apiError as APIError {
                self.log.error(error: apiError)
                // TODO: May want to return DataError instead.
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
        loadedState
    }
}

extension AppSyncModelProvider: DefaultLogger { }

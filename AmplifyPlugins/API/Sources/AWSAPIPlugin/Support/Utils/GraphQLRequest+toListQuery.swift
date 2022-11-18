//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension GraphQLRequest {

    /// Retrieve a GraphQL List operation request
    static func listQuery<ResponseType: Decodable>(responseType: ResponseType.Type,
                                                   modelSchema: ModelSchema,
                                                   filter: [String: Any]? = nil,
                                                   limit: Int? = nil,
                                                   nextToken: String? = nil,
                                                   apiName: String? = nil) -> GraphQLRequest<ResponseType> {
        
        var primaryKeysOnly = false
        if let modelType = ModelRegistry.modelType(from: modelSchema.name), modelType.rootPath != nil {
            primaryKeysOnly = true
        }
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelSchema,
                                                               operationType: .query,
                                                               primaryKeysOnly: primaryKeysOnly)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        if let filter = filter {
            documentBuilder.add(decorator: FilterDecorator(filter: filter))
        }
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        let document = documentBuilder.build()
        return GraphQLRequest<ResponseType>(apiName: apiName,
                                            document: document.stringValue,
                                            variables: document.variables,
                                            responseType: responseType.self,
                                            decodePath: document.name)
    }
    
    static func getRequest<M: Model>(_ modelType: M.Type,
                                     byIdentifiers identifiers: [(name: String, value: String)],
                                     apiName: String?) -> GraphQLRequest<M?> {
        let primaryKeysOnly = (modelType.rootPath != nil) ? true : false
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .query,
                                                               primaryKeysOnly: primaryKeysOnly)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(identifiers: identifiers))
        
        let document = documentBuilder.build()
        
        return GraphQLRequest<M?>(apiName: apiName,
                                  document: document.stringValue,
                                  variables: document.variables,
                                  responseType: M?.self,
                                  decodePath: document.name)
    }
}

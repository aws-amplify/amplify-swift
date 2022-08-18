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
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelSchema, operationType: .query)
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
    
    static func getQuery<ResponseType: Decodable>(responseType: ResponseType.Type,
                                                  modelSchema: ModelSchema,
                                                  identifier: String,
                                                  apiName: String? = nil) -> GraphQLRequest<ResponseType> {
        
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelSchema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: identifier))
        
        let document = documentBuilder.build()
        return GraphQLRequest<ResponseType>(apiName: apiName,
                                            document: document.stringValue,
                                            variables: document.variables,
                                            responseType: responseType.self,
                                            decodePath: document.name)
    }
        
}

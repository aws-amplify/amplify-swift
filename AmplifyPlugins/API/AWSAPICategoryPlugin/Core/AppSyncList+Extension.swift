//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

extension AppSyncList {
    /// Represents the data state of the `AppSyncList`.
    internal enum LoadState {
        case pending
        case loaded
    }

    // This method will return a request to retrieve `ModelType` based on its `associatedField` by the `associatedId`.
    // For example, if this is a Comment, which belongs to Post, the associatedField is the Post and the associatedId is
    // the belonging to Post's ID. The request constructed will leverage existing GraphQLRequest document builders
    // and decorators to create
    // - A GraphQL `query` operation
    // - A `list` type query operation
    // - A filter on the associated field with `associatedId`
    func constructGraphQLRequestForFirstPage() -> GraphQLRequest<AppSyncList<ModelType>> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelType.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))

        if let associatedField = associatedField {
            var fieldName = associatedField.name
            if case let .belongsTo(_, targetName) = associatedField.association {
                // use the default service generated field name if the targetName does not exist
                fieldName = targetName ?? ModelType.modelName.camelCased() + associatedField.name.pascalCased() + "Id"
            }
            let predicate: QueryPredicate = field(fieldName) == associatedId
            documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        }

        documentBuilder.add(decorator: PaginationDecorator())
        let document = documentBuilder.build()
        return GraphQLRequest<AppSyncList<ModelType>>(document: document.stringValue,
                                                      variables: document.variables,
                                                      responseType: AppSyncList<ModelType>.self,
                                                      decodePath: document.name)
    }

    // This method will always successfully return a new GraphQLRequest with nextToken added to the input variables
    // It leverages the existing GraphQLRequest document builders and decorators to create
    // - A GraphQL `query` operation
    // - A `list` type query operation
    // - The nextToken added to the GraphQL request variables
    // If the existing `variables` from current list (`Self`) contains information such as a filter and limit, they are
    // extracted back out and added back onto the GraphQL request variables to maintain the expected behavior
    func reconstructGraphQLRequestForNextPage(nextToken: String) -> GraphQLRequest<AppSyncList<ModelType>> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelType.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))

        // Since the original request constructed with object of type `QueryPredicate`, and the type is lost when
        // translated to a GraphQLRequest. The following extracts the existing filter variables stored in the
        // GraphQLRequest's variables and uses FilterDecorator to re-create the proper document.
        if let storedVariables = variables,
           let filters = storedVariables["filter"],
           case let .object(filterValue) = filters {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
            guard let filterVariablesData = try? encoder.encode(filterValue),
                  let filterVariablesJSON = try? JSONSerialization.jsonObject(with: filterVariablesData)
                    as? [String: Any] else {
                fatalError("Filter variables is not valid JSON object")
            }
            documentBuilder.add(decorator: FilterDecorator(filter: filterVariablesJSON))
        }

        // Similar to the filter variables, limit is also stored in the variables and expected to be persisted
        // across multiple `fetch` calls, hence extract the limit from the variables if it exists
        if let storedVariables = variables,
           let limit = storedVariables["limit"],
           case let .number(limitValue) = limit {
            documentBuilder.add(decorator: PaginationDecorator(limit: Int(limitValue), nextToken: nextToken))
        } else {
            documentBuilder.add(decorator: PaginationDecorator(nextToken: nextToken))
        }

        let document = documentBuilder.build()
        return GraphQLRequest<AppSyncList<ModelType>>(document: document.stringValue,
                                                      variables: document.variables,
                                                      responseType: AppSyncList<ModelType>.self,
                                                      decodePath: document.name)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct AppSyncGraphQLRequest {

    /// Create a valid GraphQL search query against an Amplify provisioned AppSync service. The search API is available
    /// when the schema used to provision the API contains a model annotated with `@searchable`.
    /// This is an AppSync specific builder that exposes the fields directly from the service, such as `nextToken`,
    /// `from`, `limit`, etc, and provides a direct interface to the search query API to make successful requests to AppSync.
    /// For developers using the Model-based GraphQL APIs, use `Amplify.API.query(request: .search(modelType:where:limit:sort))` instead.
    ///
    /// TODO: Implement this using decorators and modify as needed to introduce a new case in `GraphQLQuery` search
    ///
    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public static func searchQuery<ResponseType: Decodable>(responseType: ResponseType.Type,
                                                            modelSchema: ModelSchema,
                                                            filter: [String: Any]? = nil,
                                                            from: Int? = nil,
                                                            limit: Int? = nil,
                                                            nextToken: String? = nil,
                                                            sort: QuerySortBy? = nil,
                                                            apiName: String? = nil) -> GraphQLRequest<ResponseType> {
        let name = modelSchema.name
        let documentName = "search" + name + "s"
        var variables = [String: Any]()
        if let filter = filter {
            variables.updateValue(filter, forKey: "filter")
        }
        if let from = from {
            variables.updateValue(from, forKey: "from")
        }
        if let limit = limit {
            variables.updateValue(limit, forKey: "limit")
        }
        if let nextToken = nextToken {
            variables.updateValue(nextToken, forKey: "nextToken")
        }
        if let sort = sort {
            switch sort {
            case .ascending(let field):
                let sort = [
                    "direction": "asc",
                    "field": field.stringValue
                ]
                variables.updateValue(sort, forKey: "sort")
            case .descending(let field):
                let sort = [
                    "direction": "desc",
                    "field": field.stringValue
                ]
                variables.updateValue(sort, forKey: "sort")
            }
        }
        let graphQLFields = modelSchema.sortedFields.filter { field in
            !field.hasAssociation || field.isAssociationOwner
        }.map { (field) -> String in
            field.name
        }.joined(separator: "\n      ")
        let document = """
        query \(documentName)($filter: Searchable\(name)FilterInput, $from: Int, $limit: Int, $nextToken: String, $sort: Searchable\(name)SortInput) {
          \(documentName)(filter: $filter, from: $from, limit: $limit, nextToken: $nextToken, sort: $sort) {
            items {
              \(graphQLFields)
              __typename
            }
            nextToken
            total
          }
        }
        """
        return GraphQLRequest<ResponseType>(apiName: apiName,
                                            document: document,
                                            variables: !variables.isEmpty ? variables : nil,
                                            responseType: ResponseType.self,
                                            decodePath: documentName)
    }
}

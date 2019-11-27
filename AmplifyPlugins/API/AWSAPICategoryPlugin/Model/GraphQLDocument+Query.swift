//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A concrete implementation of `GraphQLDocument` that represents a query operation.
/// Queries can either return a single (`.get`) or mutiple (`.list`) results
/// as defined by `GraphQLQueryType`.
public struct GraphQLQuery: GraphQLDocument {

    public let documentType = GraphQLDocumentType.query
    public let modelType: Model.Type
    public let predicate: QueryPredicate?
    public let queryType: GraphQLQueryType

    public init(from modelType: Model.Type,
                predicate: QueryPredicate? = nil,
                type queryType: GraphQLQueryType) {
        self.modelType = modelType
        self.predicate = predicate
        self.queryType = queryType
    }

    public var name: String {
        // Right now plural is not consistent on the GraphQL transformer. The `.list` queries
        // just append an "s" to resolve the plural. However, `.sync` queries use proper
        // plural resolution. Change this once the transformer fixes that behavior
        var modelName = modelType.schema.graphQLName
        if case .sync = queryType {
            modelName = modelType.schema.pluralName ?? (modelName + "s")
        } else if case .list = queryType {
            modelName += "s"
        }
        return queryType.rawValue + modelName
    }

    public var decodePath: String {
        return queryType == .list ? name + ".items" : name
    }

    public var stringValue: String {
        let schema = modelType.schema

        let input = queryType == .get ?
            "$id: ID!" :
            "$filter: Model\(schema.graphQLName)FilterInput, $limit: Int, $nextToken: String"
        let inputName = queryType == .get ?
            "id: $id" :
            "filter: $filter, limit: $limit, nextToken: $nextToken"

        let fields = selectionSetFields
        var documentFields = fields.joined(separator: "\n    ")
        if queryType != .get {
            documentFields =
            """
            items {
                  \(fields.joined(separator: "\n      "))
                }
                nextToken
            """
        }

        let queryName = name.pascalCased()

        return """
        \(documentType) \(queryName)(\(input)) {
          \(name)(\(inputName)) {
            \(documentFields)
          }
        }
        """
    }
}

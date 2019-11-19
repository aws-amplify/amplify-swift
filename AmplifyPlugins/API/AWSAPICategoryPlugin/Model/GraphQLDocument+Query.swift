//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Defines the type of query, either a `list` which returns multiple results
/// and can optionally use filters or a `get`, which aims to fetch one result
/// identified by its `id`.
public enum GraphQLQueryType: String {
    case get
    case list
}

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
        // TODO better plural handling? (check current CLI implementation)
        let suffix = queryType == .list ? "s" : ""
        let modelName = modelType.schema.graphQLName + suffix
        return queryType.rawValue + modelName
    }

    public var stringValue: String {
        let schema = modelType.schema

        let inputName = queryType == .get ? "id" : "filter"
        let inputType = queryType == .get ? "ID!" : "Model\(schema.graphQLName)FilterInput"

        let fields = schema.graphQLFields.map { $0.graphQLName }
        var documentFields = fields.joined(separator: "\n    ")
        if queryType == .list {
            documentFields = """
            items {
                  \(fields.joined(separator: "\n      "))
                }
            """
        }

        let queryName = name.toPascalCase()
        return """
        \(documentType) \(queryName)($\(inputName): \(inputType)) {
          \(name)(\(inputName): $\(inputName)) {
            \(documentFields)
          }
        }
        """
    }
}

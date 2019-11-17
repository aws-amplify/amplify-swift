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
enum GraphQLQueryType: String {
    case get
    case list
}

/// A concrete implementation of `GraphQLDocument` that represents a query operation.
/// Queries can either return a single (`.get`) or mutiple (`.list`) results
/// as defined by `GraphQLQueryType`.
struct GraphQLQuery<M: Model>: GraphQLDocument {

    let documentType: GraphQLDocumentType = .query
    let modelType: M.Type
    let queryType: GraphQLQueryType

    init(from modelType: M.Type, type queryType: GraphQLQueryType) {
        self.modelType = modelType
        self.queryType = queryType
    }

    var name: String {
        // TODO better plural handling? (check current CLI implementation)
        let suffix = queryType == .list ? "s" : ""
        let modelName = modelType.schema.graphQLName + suffix
        return queryType.rawValue + modelName
    }

    var stringValue: String {
        let schema = modelType.schema

        let queryName = name
        let documentName = queryName.prefix(1).uppercased() + queryName.dropFirst()

        let inputName = queryType == .get ? "id" : "filter"
        let inputType = queryType == .get ? "ID!" : "Model\(schema.graphQLName)FilterInput"

        var fields = schema.graphQLFields.joined(separator: "\n    ")
        if queryType == .list {
            fields = """
            items {
                  \(schema.graphQLFields.joined(separator: "\n      "))
                }
            """
        }

        return """
        \(documentType) \(documentName)($\(inputName): \(inputType)) {
          \(queryName)(\(inputName): $\(inputName)) {
            \(fields)
          }
        }
        """
    }
}

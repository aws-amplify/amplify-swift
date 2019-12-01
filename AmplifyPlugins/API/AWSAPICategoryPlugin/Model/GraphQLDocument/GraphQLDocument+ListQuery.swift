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
public class GraphQLListQuery: GraphQLDocument {

    public let documentType = GraphQLDocumentType.query
    public let modelType: Model.Type
    public let predicate: QueryPredicate?

    public init(from modelType: Model.Type,
                predicate: QueryPredicate? = nil) {
        self.modelType = modelType
        self.predicate = predicate
    }

    public var name: String {
        return "list" + modelType.schema.graphQLName + "s"
    }

    public var decodePath: String {
        return name + ".items"
    }

    public var stringValue: String {
        let schema = modelType.schema

        let input = "$filter: Model\(schema.graphQLName)FilterInput, $limit: Int, $nextToken: String"
        let inputName = "filter: $filter, limit: $limit, nextToken: $nextToken"

        let fields = selectionSetFields
        var documentFields = fields.joined(separator: "\n    ")
        documentFields =
        """
        items {
              \(fields.joined(separator: "\n      "))
            }
            nextToken
        """

        let queryName = name.pascalCased()

        return """
        \(documentType) \(queryName)(\(input)) {
          \(name)(\(inputName)) {
            \(documentFields)
          }
        }
        """
    }

    public var variables: [String: Any] {
        var variables = [String: Any]()

        if let predicate = predicate {
            variables.updateValue(predicate.graphQLFilterVariables, forKey: "filter")
        }

        // TODO: Remove this once we support limit and nextToken passed in from the developer
        variables.updateValue(1_000, forKey: "limit")

        return variables
    }
}

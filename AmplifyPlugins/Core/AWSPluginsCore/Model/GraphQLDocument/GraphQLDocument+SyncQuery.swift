//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class GraphQLSyncQuery: GraphQLListQuery {
    public let limit: Int?
    public let nextToken: String?
    public let lastSync: Int?

    public init(from modelType: Model.Type,
                predicate: QueryPredicate? = nil,
                limit: Int? = nil,
                nextToken: String? = nil,
                lastSync: Int? = nil) {
        self.limit = limit
        self.nextToken = nextToken
        self.lastSync = lastSync
        super.init(from: modelType, predicate: predicate)
    }

    public override var name: String {
        // Right now plural is not consistent on the GraphQL transformer.
        // `.sync` queries use proper plural resolution.
        // Change this once the transformer fixes that behavior
        var modelName = modelType.schema.graphQLName
        modelName = modelType.schema.pluralName ?? (modelName + "s")

        return "sync" + modelName
    }

    public override var decodePath: String {
        return name
    }

    public override var stringValue: String {
        let schema = modelType.schema

        let input = "$filter: Model\(schema.graphQLName)FilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp"

        let inputName = "filter: $filter, limit: $limit, nextToken: $nextToken, lastSync: $lastSync"

        let fields = selectionSetFields
        var documentFields = fields.joined(separator: "\n    ")
        documentFields =
        """
        items {
              \(fields.joined(separator: "\n      "))
            }
            nextToken
            startedAt
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

    public override var variables: [String: Any] {
        var variables = [String: Any]()
        if let predicate = predicate {
            variables.updateValue(predicate.graphQLFilterVariables, forKey: "filter")
        }

        if let limit = limit {
            variables.updateValue(limit, forKey: "limit")
        }

        if let nextToken = nextToken {
            variables.updateValue(nextToken, forKey: "nextToken")
        }

        if let lastSync = lastSync {
            variables.updateValue(lastSync, forKey: "lastSync")
        }

        return variables
    }
}

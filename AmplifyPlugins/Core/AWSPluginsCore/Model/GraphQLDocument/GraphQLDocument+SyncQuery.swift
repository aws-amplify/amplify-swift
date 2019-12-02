//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class GraphQLSyncQuery: GraphQLListQuery {
    public let lastSync: Int?

    public init(from modelType: Model.Type,
                predicate: QueryPredicate? = nil,
                lastSync: Int? = nil) {
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
        var variables = super.variables

        if let lastSync = lastSync {
            variables.updateValue(lastSync, forKey: "lastSync")
        }

        return variables
    }
}

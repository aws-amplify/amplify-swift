//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class GraphQLSyncQuery: GraphQLDocument {

    public let documentType = GraphQLDocumentType.query
    public let modelType: Model.Type
    public let predicate: QueryPredicate?
    public let limit: Int?
    public let nextToken: String?
    public let lastSync: Int?

    public init(from modelType: Model.Type,
                predicate: QueryPredicate? = nil,
                limit: Int? = nil,
                nextToken: String? = nil,
                lastSync: Int? = nil) {
        self.modelType = modelType
        self.predicate = predicate
        self.limit = limit
        self.nextToken = nextToken
        self.lastSync = lastSync
    }

    public var name: String {
        // Right now plural is not consistent on the GraphQL transformer.
        // `.sync` queries use proper plural resolution.
        // Change this once the transformer fixes that behavior
        var modelName = modelType.schema.graphQLName
        modelName = modelType.schema.pluralName ?? (modelName + "s")

        return "sync" + modelName
    }

    public var inputTypes: String? {
        let graphQLName = modelType.schema.graphQLName
        return "$filter: Model\(graphQLName)FilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp"
    }

    public var inputParameters: String? {
        "filter: $filter, limit: $limit, nextToken: $nextToken, lastSync: $lastSync"
    }

    public var selectionSetFields: [SelectionSetField] {
        return [SelectionSetField(value: "items",
                                  innerFields: modelType.schema.graphQLFields.toSelectionSets(syncEnabled: true)),
                SelectionSetField(value: "nextToken"),
                SelectionSetField(value: "startedAt")]
    }

    public var variables: [String: Any] {
        var variables = [String: Any]()

        if let predicate = predicate {
            variables.updateValue(predicate.graphQLFilterVariables, forKey: "filter")
        }

        if let limit = limit {
            variables.updateValue(limit, forKey: "limit")
        } else {
            // TODO: Remove this once we support limit and nextToken passed in from the developer
            variables.updateValue(1_000, forKey: "limit")
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

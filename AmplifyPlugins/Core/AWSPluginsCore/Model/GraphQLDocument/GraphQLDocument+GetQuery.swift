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
public struct GraphQLGetQuery: GraphQLDocument {

    public let documentType = GraphQLDocumentType.query
    public let modelType: Model.Type
    public let id: String
    public let syncEnabled: Bool

    public init(from modelType: Model.Type,
                id: String,
                syncEnabled: Bool = false) {
        self.modelType = modelType
        self.id = id
        self.syncEnabled = syncEnabled
    }

    public var name: String {
        return "get" + modelType.schema.graphQLName
    }

    public var decodePath: String {
        return name
    }

    public var hasSyncableModels: Bool {
        return syncEnabled
    }

    public var stringValue: String {

        let input = "$id: ID!"
        let inputName = "id: $id"

        let fields = selectionSetFields
        let documentFields = fields.joined(separator: "\n    ")
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
        return ["id": id]
    }
}

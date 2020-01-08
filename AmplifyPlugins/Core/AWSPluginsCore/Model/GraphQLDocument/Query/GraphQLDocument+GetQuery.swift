//
// Copyright 2018-2020 Amazon.com,
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

    public init(from modelType: Model.Type,
                id: String) {
        self.modelType = modelType
        self.id = id
    }

    public var name: String {
        "get" + modelType.schema.graphQLName
    }

    public var inputTypes: String? {
        "$id: ID!"
    }

    public var inputParameters: String? {
        "id: $id"
    }

    public var variables: [String: Any] {
        return ["id": id]
    }
}

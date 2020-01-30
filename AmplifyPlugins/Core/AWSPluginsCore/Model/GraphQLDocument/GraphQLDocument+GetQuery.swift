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
public class GraphQLGetQuery: ModelBasedGraphQLDocument {
    private let id: Model.Identifier

    public init(modelType: Model.Type, id: Model.Identifier) {
        self.id = id
        super.init(operationType: .query(.get), modelType: modelType)
    }

    public override var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        return ["id": GraphQLDocumentInput(type: "ID!", value: .value(id))]
    }
}

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class GraphQLListQuery: ModelBasedGraphQLDocument {

    private let limit: Int?
    private let nextToken: String?

    public init(modelType: Model.Type, limit: Int? = nil, nextToken: String? = nil) {
        self.limit = limit
        self.nextToken = nextToken
        super.init(operationType: .query(.list), modelType: modelType)
    }

    public override var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        var inputs = super.inputs

        if let limit = limit {
            inputs["limit"] = GraphQLDocumentInput(type: "Int", value: .value(limit))
        } else {
            inputs["limit"] = GraphQLDocumentInput(type: "Int", value: .value(1_000))
        }

        if let nextToken = nextToken {
            inputs["nextToken"] = GraphQLDocumentInput(type: "String", value: .value(nextToken))
        }

        return inputs
    }

    public override var selectionSetFields: [SelectionSetField] {
        super.selectionSetFields.paginated
    }
}

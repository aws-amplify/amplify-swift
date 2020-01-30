//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// GraphQLSyncQuery provides the minimal construct of a Sync Query.
public class GraphQLSyncQuery: ModelBasedGraphQLDocument {

    private let limit: Int?
    private let nextToken: String?
    private let lastSync: Int?

    public init(modelType: Model.Type, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
        self.limit = limit
        self.nextToken = nextToken
        self.lastSync = lastSync
        super.init(operationType: .query(.sync), modelType: modelType)
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

        if let lastSync = lastSync {
            inputs["lastSync"] = GraphQLDocumentInput(type: "AWSTimestamp", value: .value(lastSync))
        }

        return inputs
    }

    public override var selectionSetFields: [SelectionSetField] {
        var fields = super.selectionSetFields.syncEnabled.paginated
        fields.append(SelectionSetField(value: "startedAt"))
        return fields
    }
}

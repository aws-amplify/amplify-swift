//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A concrete implementation of `SingleDirectiveGraphQLDocument` that represents a subscription operation.
public struct GraphQLSubscription: SingleDirectiveGraphQLDocument {

    public init(operationType: GraphQLOperationType,
                name: String,
                inputs: [GraphQLParameterName: GraphQLDocumentInput],
                selectionSet: SelectionSet?) {
        self.operationType = operationType
        self.name = name
        self.inputs = inputs
        self.selectionSet = selectionSet
    }

    public init(modelType: Model.Type) {
        self.selectionSet = SelectionSet(fields: modelType.schema.graphQLFields)
    }

    public var operationType: GraphQLOperationType = .subscription

    public var name: String = ""

    public var inputs: [GraphQLParameterName: GraphQLDocumentInput] = [:]

    public var selectionSet: SelectionSet?
}

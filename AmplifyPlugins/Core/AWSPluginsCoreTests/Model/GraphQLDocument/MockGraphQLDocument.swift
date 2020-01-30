//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@testable import AWSPluginsCore

class MockGraphQLDocument: SingleDirectiveGraphQLDocument {
    var operationType: AWSPluginsCore.GraphQLOperationType
    var inputs: [GraphQLParameterName: GraphQLDocumentInput]
    var selectionSetFields: [SelectionSetField]
    var name: String
    var modelType: Model.Type

    init(operationType: AWSPluginsCore.GraphQLOperationType,
         name: String,
         inputs: [GraphQLParameterName: GraphQLDocumentInput] = [:],
         selectionSetFields: [SelectionSetField] = [SelectionSetField](),
         modelType: Model.Type) {
        self.operationType = operationType
        self.name = name
        self.inputs = inputs
        self.selectionSetFields = selectionSetFields
        self.modelType = modelType
    }
}

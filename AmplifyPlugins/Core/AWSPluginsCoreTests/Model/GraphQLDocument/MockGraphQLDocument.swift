//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@testable import AWSPluginsCore

class MockGraphQLDocument: GraphQLDocument {
    var documentType: GraphQLDocumentType
    var name: String
    var inputTypes: String?
    var inputParameters: String?
    var modelType: Model.Type

    init(documentType: GraphQLDocumentType,
         name: String,
         inputTypes: String? = nil,
         inputParameters: String? = nil,
         modelType: Model.Type) {
        self.documentType = documentType
        self.name = name
        self.inputTypes = inputTypes
        self.inputParameters = inputParameters
        self.modelType = modelType
    }
}

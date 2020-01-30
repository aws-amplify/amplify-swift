//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public extension ModelBasedGraphQLDocument {
    convenience init(type: GraphQLQueryType, modelType: Model.Type) {
        self.init(operationType: .query(type), modelType: modelType)
    }

    convenience init(type: GraphQLMutationType, modelType: Model.Type) {
        self.init(operationType: .mutation(type), modelType: modelType)
    }

    convenience init(type: GraphQLSubscriptionType, modelType: Model.Type) {
        self.init(operationType: .subscription(type), modelType: modelType)
    }
}

public class ModelBasedGraphQLDocument: SingleDirectiveGraphQLDocument {

    let modelType: Model.Type
    public let operationType: GraphQLOperationType

    public init(operationType: GraphQLOperationType,
                modelType: Model.Type) {
        self.operationType = operationType
        self.modelType = modelType
    }

    public var name: String {
        switch operationType {
        case .query(let queryType):
            return modelType.schema.graphQLName(type: queryType)
        case .mutation(let mutationType):
            return modelType.schema.graphQLName(type: mutationType)
        case .subscription(let subscriptionType):
            return modelType.schema.graphQLName(type: subscriptionType)
        }
    }

    public var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        [:]
    }

    public var selectionSetFields: [SelectionSetField] {
        modelType.schema.graphQLFields.toSelectionSet
    }
}

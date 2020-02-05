//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Holds all of the possible operations such as `.get`, `.list`, `.sync`, `create`, `update`, `delete`, `onCreate`,
/// `onUpdate`, `onDelete` defined, for each GraphQL operation type (query, mutation, subscription)
enum GraphQLOperationSubType {
    case query(GraphQLQueryType)
    case mutation(GraphQLMutationType)
    case subscription(GraphQLSubscriptionType)
}

/// Replaces the directive name of the GraphQL document based on Amplify GraphQL operation types such as "get", "list",
/// "sync", "create", "update", "delete", "onCreate", "onUpdate", and "onDelete". The GraphQL name is constructed based
/// on the data from the Model schema and the operation type.
public struct DirectiveDecorator: SingleDirectiveGraphQLDocumentDecorator {

    private let operationSubType: GraphQLOperationSubType

    public init(type: GraphQLQueryType) {
        self.operationSubType = .query(type)
    }

    public init(type: GraphQLSubscriptionType) {
        self.operationSubType = .subscription(type)
    }

    public init(type: GraphQLMutationType) {
        self.operationSubType = .mutation(type)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        return document.copy(name: modelType.schema.graphQLName(operationSubType: operationSubType))
    }
}

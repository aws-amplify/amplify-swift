//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Defines the type of a GraphQL subscription.
public enum GraphQLSubscriptionType: String {
    case onCreate
    case onDelete
    case onUpdate
}

/// A concrete implementation of `GraphQLDocument` that represents a subscription operation.
/// Subscriptions are triggered when specific operations happen on the defined `Model`.
/// These operations are defined by `GraphQLSubscriptionType`.
public struct GraphQLSubscription<M: Model>: GraphQLDocument {

    public let documentType = GraphQLDocumentType.subscription
    public let modelType: M.Type
    public let subscriptionType: GraphQLSubscriptionType

    public init(of modelType: M.Type, type subscriptionType: GraphQLSubscriptionType) {
        self.modelType = modelType
        self.subscriptionType = subscriptionType
    }

    public var name: String {
        subscriptionType.rawValue + modelType.schema.graphQLName
    }

    public var stringValue: String {
        let schema = modelType.schema

        let subscriptionName = name.toPascalCase()
        let fields = schema.graphQLFields.map { $0.graphQLName }
        return """
        \(documentType) \(subscriptionName) {
          \(name) {
            \(fields.joined(separator: "\n    "))
          }
        }
        """
    }

}

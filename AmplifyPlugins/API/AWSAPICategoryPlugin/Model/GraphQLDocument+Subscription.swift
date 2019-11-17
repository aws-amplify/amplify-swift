//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Defines the type of a GraphQL subscription.
enum GraphQLSubscriptionType: String {
    case onCreate
    case onDelete
    case onUpdate
}

/// A concrete implementation of `GraphQLDocument` that represents a subscription operation.
/// Subscriptions are triggered when specific operations happen on the defined `Model`.
/// These operations are defined by `GraphQLSubscriptionType`.
struct GraphQLSubscription<M: Model>: GraphQLDocument {

    let documentType: GraphQLDocumentType = .subscription
    let modelType: M.Type
    let subscriptionType: GraphQLSubscriptionType

    init(of modelType: M.Type, type subscriptionType: GraphQLSubscriptionType) {
        self.modelType = modelType
        self.subscriptionType = subscriptionType
    }

    var name: String {
        subscriptionType.rawValue + modelType.schema.graphQLName
    }

    var stringValue: String {
        let schema = modelType.schema
        let subscriptionName = name

        let documentName = subscriptionName.prefix(1).uppercased() + subscriptionName.dropFirst()
        return """
        \(documentType) \(documentName) {
          \(subscriptionName) {
            \(schema.graphQLFields.joined(separator: "\n    "))
          }
        }
        """
    }

}

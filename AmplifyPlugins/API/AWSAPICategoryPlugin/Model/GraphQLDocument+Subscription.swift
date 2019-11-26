//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A concrete implementation of `GraphQLDocument` that represents a subscription operation.
/// Subscriptions are triggered when specific operations happen on the defined `Model`.
/// These operations are defined by `GraphQLSubscriptionType`.
public struct GraphQLSubscription: GraphQLDocument {

    public let documentType = GraphQLDocumentType.subscription
    public let modelType: Model.Type
    public let subscriptionType: GraphQLSubscriptionType

    public init(of modelType: Model.Type,
                type subscriptionType: GraphQLSubscriptionType) {
        self.modelType = modelType
        self.subscriptionType = subscriptionType
    }

    public var name: String {
        subscriptionType.rawValue + modelType.schema.graphQLName
    }

    public var decodePath: String {
        name
    }

    public var stringValue: String {
        let schema = modelType.schema

        let subscriptionName = name.toPascalCase()
        var fields = schema.graphQLFields.map { $0.graphQLName }

        // TODO: Move these conflict resolution fields

        // All subscription documents should include typename in the selection set,
        // to support type-erased operations on the client
        fields.append("__typename")
        fields.append("_deleted")

        let document = """
        \(documentType) \(subscriptionName) {
          \(name) {
            \(fields.joined(separator: "\n    "))
          }
        }
        """

        return document
    }

}

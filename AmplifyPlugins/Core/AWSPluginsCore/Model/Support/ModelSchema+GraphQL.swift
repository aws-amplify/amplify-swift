//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Extension that adds GraphQL specific utilities to `ModelSchema`.
extension ModelSchema {

    /// The GraphQL directive name translated from the GraphQL operation and model schema data
    func graphQLName(operationSubType: GraphQLOperationSubType) -> String {
        let graphQLName: String
        switch operationSubType {
        case .mutation(let mutationType):
            graphQLName = mutationType.rawValue + name
        case .query(let queryType):
            switch queryType {
            case .list:
                graphQLName = queryType.rawValue + name + "s"
            case .sync:
                graphQLName = queryType.rawValue + (pluralName ?? (name + "s"))
            case .get:
                graphQLName = queryType.rawValue + name
            }
        case .subscription(let subscriptionType):
            graphQLName = subscriptionType.rawValue + name
        }

        return graphQLName
    }

    /// The list of fields formatted for GraphQL usage.
    var graphQLFields: [ModelField] {
        sortedFields.filter { field in
            !field.hasAssociation || field.isAssociationOwner
        }
    }
}

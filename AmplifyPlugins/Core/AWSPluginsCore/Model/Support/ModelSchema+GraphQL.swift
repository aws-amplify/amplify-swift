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

    public func graphQLName(type: GraphQLMutationType) -> String {
        return type.rawValue + name
    }

    public func graphQLName(type: GraphQLQueryType) -> String {
        switch type {
        case .get:
            return type.rawValue + name
        case .list:
            return type.rawValue + name + "s"
        case .sync:
            return type.rawValue + ( pluralName ?? ( name + "s" ))
        }
    }

    public func graphQLName(type: GraphQLSubscriptionType) -> String {
        return type.rawValue + name
    }

    /// The list of fields formatted for GraphQL usage.
    var graphQLFields: [ModelField] {
        sortedFields.filter { field in
            !field.hasAssociation || field.isAssociationOwner
        }
    }

}

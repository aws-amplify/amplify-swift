//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public enum GraphQLOperationType {
    case query(GraphQLQueryType)
    case mutation(GraphQLMutationType)
    case subscription(GraphQLSubscriptionType)

    var graphQLName: String {
        switch self {
        case .mutation:
            return "mutation"
        case .query:
            return "query"
        case .subscription:
            return "subscription"
        }
    }
}

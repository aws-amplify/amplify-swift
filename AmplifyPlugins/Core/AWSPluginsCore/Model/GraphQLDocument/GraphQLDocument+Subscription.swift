//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A concrete implementation of `GraphQLDocument` that represents a subscription operation.
/// Subscriptions are triggered when specific operations happen on the defined `Model`.
/// These operations are defined by `GraphQLSubscriptionType`.
public class GraphQLSubscription: ModelBasedGraphQLDocument {

    public init(modelType: Model.Type,
                type subscriptionType: GraphQLSubscriptionType) {
        super.init(operationType: .subscription(subscriptionType), modelType: modelType)
    }
}

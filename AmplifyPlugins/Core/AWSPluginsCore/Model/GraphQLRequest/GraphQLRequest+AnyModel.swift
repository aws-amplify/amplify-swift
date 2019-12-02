//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLRequest {
    /// Gets a GraphQLRequest for an `AnyModel`'s underlying instance type. The generated GraphQL document will reflect
    /// the structure and variables of `AnyModel.instance`, but the return value will be erased to `AnyModel`, allowing
    /// it to be collected.
    static func mutation(of anyModel: AnyModel,
                         type: GraphQLMutationType) -> GraphQLRequest<AnyModel> {
        let document = GraphQLMutation(of: anyModel, type: type)

        return GraphQLRequest<AnyModel>(document: document.stringValue,
                                        variables: document.variables,
                                        responseType: AnyModel.self,
                                        decodePath: document.decodePath)
    }

    static func subscription(toAnyModelType modelType: Model.Type,
                             subscriptionType: GraphQLSubscriptionType) -> GraphQLRequest<AnyModel> {
        let document = GraphQLSubscription(of: modelType, type: subscriptionType)
        return GraphQLRequest<AnyModel>(document: document.stringValue,
                                        responseType: AnyModel.self,
                                        decodePath: document.decodePath)

    }
}

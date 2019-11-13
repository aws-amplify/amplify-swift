//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryGraphQLBehavior {
    public func query<R: Decodable>(apiName: String? = nil,
                                    request: GraphQLRequest<R>,
                                    listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        plugin.query(apiName: apiName, request: request, listener: listener)
    }

    public func mutate<R: Decodable>(apiName: String? = nil,
                                     request: GraphQLRequest<R>,
                                     listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        plugin.mutate(apiName: apiName, request: request, listener: listener)
    }

    public func subscribe<R>(apiName: String? = nil,
                             request: GraphQLRequest<R>,
                             listener: SubscriptionGraphQLOperation<R>.EventListener?) -> SubscriptionGraphQLOperation<R> {
        plugin.subscribe(apiName: apiName, request: request, listener: listener)
    }
}

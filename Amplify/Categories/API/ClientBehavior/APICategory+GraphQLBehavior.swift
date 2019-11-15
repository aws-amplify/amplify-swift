//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryGraphQLBehavior {
    public func query<R: Decodable>(request: GraphQLRequest<R>,
                                    listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        plugin.query(request: request, listener: listener)
    }

    public func mutate<R: Decodable>(request: GraphQLRequest<R>,
                                     listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        plugin.mutate(request: request, listener: listener)
    }

    public func subscribe<R>(request: GraphQLRequest<R>,
                             listener: GraphQLSubscriptionOperation<R>.EventListener?) -> GraphQLSubscriptionOperation<R> {
        plugin.subscribe(request: request, listener: listener)
    }
}

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockAPICategoryPlugin {
    enum ResponderKeys {
        case queryRequestListener
        case subscribeRequestListener
        case mutateRequestListener
    }
    
    struct RESTResponders {
        var get: RESTResponder?
        var put: RESTResponder?
        var post: RESTResponder?
        var delete: RESTResponder?
        var head: RESTResponder?
        var patch: RESTResponder?
    }
}

typealias QueryRequestListenerResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>, GraphQLOperation<R>.ResultListener?),
    GraphQLOperation<R>?
>

typealias MutateRequestListenerResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>, GraphQLOperation<R>.ResultListener?),
    GraphQLOperation<R>?
>

typealias SubscribeRequestListenerResponder<R: Decodable> = MockResponder<
    (
    GraphQLRequest<R>,
    GraphQLSubscriptionOperation<R>.InProcessListener?,
    GraphQLSubscriptionOperation<R>.ResultListener?
    ),
    GraphQLSubscriptionOperation<R>?
>

typealias RESTResponder = (RESTRequest) -> RESTOperation.OperationResult

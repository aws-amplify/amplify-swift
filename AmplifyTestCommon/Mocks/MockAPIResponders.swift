//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockAPICategoryPlugin {
    enum ResponderKeys {
        case queryRequestListener
        case queryRequestResponse
        case subscribeRequestListener
        case mutateRequestListener
        case mutateRequestResponse
    }
}

typealias QueryRequestListenerResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>, GraphQLOperation<R>.ResultListener?),
    GraphQLOperation<R>?
>

typealias QueryRequestResponder<R: Decodable> = MockResponder<
    GraphQLRequest<R>,
    GraphQLOperation<R>.OperationResult
>

typealias MutateRequestListenerResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>, GraphQLOperation<R>.ResultListener?),
    GraphQLOperation<R>?
>

typealias MutateRequestResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>),
    GraphQLOperation<R>.OperationResult
>

typealias SubscribeRequestListenerResponder<R: Decodable> = MockResponder<
    (
    GraphQLRequest<R>,
    GraphQLSubscriptionOperation<R>.InProcessListener?,
    GraphQLSubscriptionOperation<R>.ResultListener?
    ),
    GraphQLSubscriptionOperation<R>?
>

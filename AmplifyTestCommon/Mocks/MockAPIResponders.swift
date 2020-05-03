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
}

typealias QueryRequestListenerResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>, GraphQLOperation<R>.ResultListener?),
    GraphQLOperation<R>?
>

typealias SubscribeRequestListenerResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>, GraphQLSubscriptionOperation<R>.ResultListener?),
    GraphQLSubscriptionOperation<R>?
>

typealias MutateRequestListenerResponder<R: Decodable> = MockResponder<
    (GraphQLRequest<R>,
    GraphQLOperation<R>.ResultListener?),
    GraphQLOperation<R>?
>

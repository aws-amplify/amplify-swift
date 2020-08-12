//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

open class GraphQLOperation<R: Decodable>: AmplifyOperation<
    GraphQLOperationRequest<R>,
    GraphQLResponse<R>,
    APIError
> { }

open class GraphQLSubscriptionOperation<R: Decodable>: AmplifyInProcessReportingOperation<
    GraphQLOperationRequest<R>,
    SubscriptionEvent<GraphQLResponse<R>>,
    Void,
    APIError
> { }

public extension HubPayload.EventName.API {
    /// eventName for HubPayloads emitted by this operation
    static let mutate = "API.mutate"
    static let query = "API.query"
    static let subscribe = "API.subscribe"
}

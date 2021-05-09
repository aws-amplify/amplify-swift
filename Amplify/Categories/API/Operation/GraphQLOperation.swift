//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
open class GraphQLOperation<R: Decodable>: AmplifyOperation<
    GraphQLOperationRequest<R>,
    GraphQLResponse<R>,
    APIError
> { }

/// <#Description#>
open class GraphQLSubscriptionOperation<R: Decodable>: AmplifyInProcessReportingOperation<
    GraphQLOperationRequest<R>,
    SubscriptionEvent<GraphQLResponse<R>>,
    Void,
    APIError
> { }

public extension HubPayload.EventName.API {
    /// eventName for HubPayloads emitted by this operation
    static let mutate = "API.mutate"

    /// <#Description#>
    static let query = "API.query"

    /// <#Description#>
    static let subscribe = "API.subscribe"
}

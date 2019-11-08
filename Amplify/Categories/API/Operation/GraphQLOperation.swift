//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol GraphQLOperation: AmplifyOperation<GraphQLRequest, Void, Decodable, APIError> { }

public extension HubPayload.EventName.API {
    /// eventName for HubPayloads emitted by this operation
    static let mutate = "API.mutate"
    static let query = "API.query"
    static let subscribe = "API.subscribe"
}

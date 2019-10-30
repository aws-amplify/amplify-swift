//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol GraphQLOperation: AmplifyOperation<GraphQLRequest, Void, Codable, StorageError> { }

public extension HubPayload.EventName.API {
    /// eventName for HubPayloads emitted by this operation
    static let graphql = "API.graphql"
}

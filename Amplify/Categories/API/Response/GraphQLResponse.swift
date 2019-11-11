//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A response from a GraphQL API
public enum GraphQLResponse<ResponseType: Decodable> {

    /// A successful response. The associated value will be the payload of the response
    case success(ResponseType)

    /// An error resposne. The associated value will be an array of JSONValues that contain service-specific error
    /// messages. https://graphql.github.io/graphql-spec/June2018/#sec-Errors
    case error([JSONValue])

    /// A partially-successful response. The `ResponseType` associated value will contain as much of the payload as the
    /// service was able to fulfill, and the errors will be an array of JSONValues that contain service-specific error
    /// messages.
    case partial(ResponseType, [JSONValue])
}

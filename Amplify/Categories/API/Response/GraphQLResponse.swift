//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Successful GraphQL response containing optional `data` and list of `errors`
public class GraphQLResponse<ResponseType: Decodable> {

    /// GraphQL response data deserialized to ResponseType
    public var data: ResponseType?

    /// GraphQL response errors deserialized to JSON
    public var errors: [JSONValue]

    public init(data: ResponseType?, errors: [JSONValue]) {
        self.data = data
        self.errors = errors
    }
}

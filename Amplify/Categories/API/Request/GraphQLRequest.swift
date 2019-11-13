//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct GraphQLRequest<R: Decodable> {

    public let document: String
    public let variables: [String: Any]?
    public let responseType: R.Type

    public init(document: String,
                variables: [String: Any]? = nil,
                responseType: R.Type) {
        self.document = document
        self.variables = variables
        self.responseType = responseType
    }
}

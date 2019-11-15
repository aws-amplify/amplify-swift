//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct GraphQLRequest<R: Decodable> {

    /// The name of graphQL API being invoked, as specified in `amplifyconfiguration.json`.
    /// Specify this parameter when more than one GraphQL API is configured.
    public let apiName: String?

    /// Query document
    public let document: String

    /// Query variables
    public let variables: [String: Any]?

    /// Type to decode the graphql response data object to
    public let responseType: R.Type

    public init(apiName: String? = nil,
                document: String,
                variables: [String: Any]? = nil,
                responseType: R.Type) {
        self.apiName = apiName
        self.document = document
        self.variables = variables
        self.responseType = responseType
    }
}

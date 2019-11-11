//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct GraphQLRequest: AmplifyOperationRequest {

    /// The name of the API to perform the request against
    public let apiName: String

    /// The GraphQL operation type
    public let operationType: GraphQLOperationType

    /// The GraphQL query document used for the operation
    public let document: String

    /// The GraphQL variables used for the operation
    public let variables: [String: Any]?

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(apiName: String,
                operationType: GraphQLOperationType,
                document: String,
                variables: [String: Any]? = nil,
                options: Options) {
        self.apiName = apiName
        self.operationType = operationType
        self.document = document
        self.variables = variables
        self.options = options
    }
}

public extension GraphQLRequest {
    struct Options {
        public init() { }
    }
}

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct GraphQLOperationRequest<R: Decodable>: AmplifyOperationRequest {

    /// The name of the API to perform the request against
    public let apiName: String?

    /// The GraphQL operation type
    public let operationType: GraphQLOperationType

    /// The GraphQL query document used for the operation
    public let document: String

    /// The GraphQL variables used for the operation
    public let variables: [String: Any]?

    /// responseTyp
    public let responseType: R.Type

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(apiName: String?,
                operationType: GraphQLOperationType,
                document: String,
                variables: [String: Any]? = nil,
                responseType: R.Type,
                options: Options) {
        self.apiName = apiName
        self.operationType = operationType
        self.document = document
        self.variables = variables
        self.responseType = responseType
        self.options = options
    }
}

public extension GraphQLOperationRequest {
    struct Options {
        public init() { }
    }
}

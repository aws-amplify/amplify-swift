//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct RESTRequest: AmplifyOperationRequest {
    /// The name of the API to perform the request against
    public let apiName: String

    public let operationType: RESTOperationType

    public let path: String

    public let body: Data?

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(apiName: String,
                operationType: RESTOperationType,
                path: String,
                body: Data? = nil,
                options: Options) {
        self.apiName = apiName
        self.operationType = operationType
        self.path = path
        self.body = body
        self.options = options
    }
}

public extension RESTRequest {
    struct Options {
        public init() { }
    }
}

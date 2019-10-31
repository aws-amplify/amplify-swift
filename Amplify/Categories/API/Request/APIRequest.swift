//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct APIRequest: AmplifyOperationRequest {
    /// The name of the API to perform the request against
    public let apiName: String

    public let operationType: APIOperationType

    public let path: String

    public let body: String?

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(apiName: String,
                operationType: APIOperationType,
                path: String,
                body: String? = nil,
                options: Options) {
        self.apiName = apiName
        self.operationType = operationType
        self.path = path
        self.body = body
        self.options = options
    }
}

public extension APIRequest {
    struct Options {
        public init() { }
    }
}

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct APIGetRequest: AmplifyOperationRequest {
    /// The name of the API to perform the request against
    public let apiName: String

    /// The path to the resource being requested
    public let path: String

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(apiName: String, path: String, options: Options) {
        self.apiName = apiName
        self.path = path
        self.options = options
    }
}

public extension APIGetRequest {
    struct Options {
        public init() { }
    }
}

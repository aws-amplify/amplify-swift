//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct GraphQLRequest: AmplifyOperationRequest {
    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(key: String, options: Options) {
        self.options = options
    }
}

public extension GraphQLRequest {
    struct Options {
        public init() { }
    }
}

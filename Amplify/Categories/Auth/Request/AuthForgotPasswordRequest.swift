//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthForgotPasswordRequest: AmplifyOperationRequest {

    public let username: String

    public var options: Options

    public init(username: String,
                options: Options) {
        self.username = username
        self.options = options
    }
}

public extension AuthForgotPasswordRequest {

    struct Options {

        public let metadata: [String: String]?

        public init(metadata: [String: String]? = nil) {
            self.metadata = metadata
        }
    }
}

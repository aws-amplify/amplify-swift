//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSignUpRequest: AmplifyOperationRequest {

    public let username: String

    public let password: String?

    public var options: Options

    public init(username: String, password: String?, options: Options) {
        self.username = username
        self.password = password
        self.options = options
    }
}

public extension AuthSignUpRequest {

    struct Options {

        public let userAttributes: [AuthUserAttribute]?

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(userAttributes: [AuthUserAttribute]? = nil,
                    pluginOptions: Any? = nil) {
            self.userAttributes = userAttributes
            self.pluginOptions = pluginOptions
        }
    }
}

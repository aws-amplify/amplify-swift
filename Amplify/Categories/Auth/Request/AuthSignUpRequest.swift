//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSignUpRequest: AmplifyOperationRequest {

    public let username: String

    public let password: String

    public var options: Options

    public init(username: String, password: String, options: Options) {
        self.username = username
        self.password = password
        self.options = options
    }
}

public extension AuthSignUpRequest {

    struct Options {

        public let userAttributes: [String: String]?
        public let validationData: [String: String]?
        public let metadata: [String: String]?

        public init(userAttributes: [String: String]? = nil,
                    validationData: [String: String]? = nil,
                    metadata: [String: String]? = nil) {
            self.userAttributes = userAttributes
            self.validationData = validationData
            self.metadata = metadata
        }
    }
}

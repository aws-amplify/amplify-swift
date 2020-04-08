//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthConfirmForgotPwdRequest: AmplifyOperationRequest {

    public let username: String

    public let newPassword: String

    public let confirmationCode: String

    public var options: Options

    public init(username: String,
                newPassword: String,
                confirmationCode: String,
                options: Options) {
        self.username = username
        self.newPassword = newPassword
        self.confirmationCode = confirmationCode
        self.options = options
    }
}

public extension AuthConfirmForgotPwdRequest {

    struct Options {

        public let metadata: [String: String]?

        public init(metadata: [String: String]? = nil) {
            self.metadata = metadata
        }
    }
}

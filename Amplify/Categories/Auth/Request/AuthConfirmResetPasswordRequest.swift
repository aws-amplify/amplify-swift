//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthConfirmResetPasswordRequest: AmplifyOperationRequest {

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

public extension AuthConfirmResetPasswordRequest {

    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(pluginOptions: Any? = nil) {
            self.pluginOptions = pluginOptions
        }
    }
}

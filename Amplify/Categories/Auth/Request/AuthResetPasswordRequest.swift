//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request to reset password of a user
public struct AuthResetPasswordRequest: AmplifyOperationRequest {

    public let username: String

    /// Extra request options defined in `AuthResetPasswordRequest.Options`
    public var options: Options

    public init(username: String,
                options: Options) {
        self.username = username
        self.options = options
    }
}

public extension AuthResetPasswordRequest {

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

extension AuthResetPasswordRequest.Options: @unchecked Sendable { }

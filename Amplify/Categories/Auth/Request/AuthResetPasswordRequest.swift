//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthResetPasswordRequest: AmplifyOperationRequest {

    /// <#Description#>
    public let username: String

    /// <#Description#>
    public var options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - username: <#username description#>
    ///   - options: <#options description#>
    public init(username: String,
                options: Options) {
        self.username = username
        self.options = options
    }
}

public extension AuthResetPasswordRequest {

    /// <#Description#>
    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        /// <#Description#>
        /// - Parameter pluginOptions: <#pluginOptions description#>
        public init(pluginOptions: Any? = nil) {
            self.pluginOptions = pluginOptions
        }
    }
}

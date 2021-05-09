//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthSignUpRequest: AmplifyOperationRequest {

    /// <#Description#>
    public let username: String

    /// <#Description#>
    public let password: String?

    /// <#Description#>
    public var options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - username: <#username description#>
    ///   - password: <#password description#>
    ///   - options: <#options description#>
    public init(username: String, password: String?, options: Options) {
        self.username = username
        self.password = password
        self.options = options
    }
}

public extension AuthSignUpRequest {

    /// <#Description#>
    struct Options {

        /// <#Description#>
        public let userAttributes: [AuthUserAttribute]?

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        /// <#Description#>
        /// - Parameters:
        ///   - userAttributes: <#userAttributes description#>
        ///   - pluginOptions: <#pluginOptions description#>
        public init(userAttributes: [AuthUserAttribute]? = nil,
                    pluginOptions: Any? = nil) {
            self.userAttributes = userAttributes
            self.pluginOptions = pluginOptions
        }
    }
}

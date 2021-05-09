//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthUpdateUserAttributesRequest: AmplifyOperationRequest {

    /// <#Description#>
    public let userAttributes: [AuthUserAttribute]

    /// <#Description#>
    public var options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - userAttributes: <#userAttributes description#>
    ///   - options: <#options description#>
    public init(userAttributes: [AuthUserAttribute],
                options: Options) {
        self.userAttributes = userAttributes
        self.options = options
    }
}

public extension AuthUpdateUserAttributesRequest {

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

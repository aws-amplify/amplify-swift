//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthConfirmUserAttributeRequest: AmplifyOperationRequest {

    /// <#Description#>
    public let attributeKey: AuthUserAttributeKey

    /// <#Description#>
    public let confirmationCode: String

    /// <#Description#>
    public var options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - attributeKey: <#attributeKey description#>
    ///   - confirmationCode: <#confirmationCode description#>
    ///   - options: <#options description#>
    public init(attributeKey: AuthUserAttributeKey,
                confirmationCode: String,
                options: Options) {
        self.attributeKey = attributeKey
        self.confirmationCode = confirmationCode
        self.options = options
    }
}

public extension AuthConfirmUserAttributeRequest {

    /// <#Description#>
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

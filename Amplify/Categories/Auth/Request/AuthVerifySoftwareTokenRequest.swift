//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request to confirm the signup flow
public struct AuthVerifySoftwareTokenRequest: AmplifyOperationRequest {

    public var verificationCode: String

    /// Extra request options defined in `AuthVerifySoftwareTokenRequest.Options`
    public var options: Options

    public init(
        verificationCode: String,
        options: Options) {
            self.verificationCode = verificationCode
            self.options = options
    }
}

public extension AuthVerifySoftwareTokenRequest {

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

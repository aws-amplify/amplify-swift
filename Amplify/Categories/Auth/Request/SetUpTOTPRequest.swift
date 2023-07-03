//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request to set up TOTP
public struct SetUpTOTPRequest: AmplifyOperationRequest {

    /// Extra request options defined in `SetUpTOTPRequest.Options`
    public var options: Options

    public init(options: Options) {
        self.options = options
    }
}

public extension SetUpTOTPRequest {

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

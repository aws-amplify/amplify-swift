//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthConfirmSignInRequest: AmplifyOperationRequest {

    public let challengeResponse: String

    public var options: Options

    public init(challengeResponse: String, options: Options) {
        self.challengeResponse = challengeResponse
        self.options = options
    }
}

public extension AuthConfirmSignInRequest {

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

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthConfirmUserAttributeRequest: AmplifyOperationRequest {

    public let attributeKey: AuthUserAttributeKey

    public let confirmationCode: String

    public var options: Options

    public init(attributeKey: AuthUserAttributeKey,
                confirmationCode: String,
                options: Options) {
        self.attributeKey = attributeKey
        self.confirmationCode = confirmationCode
        self.options = options
    }
}

public extension AuthConfirmUserAttributeRequest {

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

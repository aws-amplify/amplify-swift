//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// swiftlint:disable:next type_name
public struct AuthAttributeResendConfirmationCodeRequest: AmplifyOperationRequest {

    public let attributeKey: AuthUserAttributeKey

    public var options: Options

    public init(attributeKey: AuthUserAttributeKey,
                options: Options) {
        self.attributeKey = attributeKey
        self.options = options
    }
}

public extension AuthAttributeResendConfirmationCodeRequest {

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

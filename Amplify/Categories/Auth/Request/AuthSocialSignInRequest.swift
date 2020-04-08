//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSocialSignInRequest: AmplifyOperationRequest {

    public let provider: AuthSocialProvider

    public let token: String

    public var options: Options

    public init(provider: AuthSocialProvider, token: String, options: Options) {
        self.provider = provider
        self.token = token
        self.options = options
    }
}

public extension AuthSocialSignInRequest {

    struct Options {

        public let validationData: [String: String]?
        public let metadata: [String: String]?

        public init(validationData: [String: String]? = nil,
                    metadata: [String: String]? = nil) {
            self.validationData = validationData
            self.metadata = metadata
        }
    }
}

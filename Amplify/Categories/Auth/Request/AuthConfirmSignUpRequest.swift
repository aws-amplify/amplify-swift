//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthConfirmSignUpRequest: AmplifyOperationRequest {

    public let username: String

    public let code: String

    public var options: Options

    public init(username: String, code: String, options: Options) {
        self.username = username
        self.code = code
        self.options = options
    }
}

public extension AuthConfirmSignUpRequest {

    struct Options {
        //TODO: Add documetnation.
        public let forceAliasCreation: Bool
        public let validationData: [String: String]?
        public let metadata: [String: String]?

        public init(forceAliasCreation: Bool = false,
                    validationData: [String: String]? = nil,
                    metadata: [String: String]? = nil) {
            self.forceAliasCreation = forceAliasCreation
            self.validationData = validationData
            self.metadata = metadata
        }
    }
}

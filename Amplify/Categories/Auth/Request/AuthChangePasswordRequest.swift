//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthChangePasswordRequest: AmplifyOperationRequest {

    public let oldPassword: String

    public let newPassword: String

    public var options: Options

    public init(oldPassword: String,
                newPassword: String,
                options: Options) {
        self.oldPassword = oldPassword
        self.newPassword = newPassword
        self.options = options
    }
}

public extension AuthChangePasswordRequest {

    struct Options {

        public let metadata: [String: String]?

        public init(metadata: [String: String]? = nil) {
            self.metadata = metadata
        }
    }
}

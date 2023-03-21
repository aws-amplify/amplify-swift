//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request for change password operation
public struct AuthChangePasswordRequest: AmplifyOperationRequest {

    /// Old or existing password for the signed in user
    public let oldPassword: String

    /// New password for the user
    public let newPassword: String

    /// Extra request options defined in `AuthChangePasswordRequest.Options`
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

        // swiftlint:disable:next todo
        // TODO: Move this metadata to plugin options. All other request has the metadata
        // inside the plugin options.

        public let metadata: [String: String]?

        public init(metadata: [String: String]? = nil) {
            self.metadata = metadata
        }
    }
}

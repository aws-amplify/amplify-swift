//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthChangePasswordRequest: AmplifyOperationRequest {

    /// <#Description#>
    public let oldPassword: String

    /// <#Description#>
    public let newPassword: String

    /// <#Description#>
    public var options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - oldPassword: <#oldPassword description#>
    ///   - newPassword: <#newPassword description#>
    ///   - options: <#options description#>
    public init(oldPassword: String,
                newPassword: String,
                options: Options) {
        self.oldPassword = oldPassword
        self.newPassword = newPassword
        self.options = options
    }
}

public extension AuthChangePasswordRequest {

    /// <#Description#>
    struct Options {

        // TODO: Move this metadata to plugin options. All other request has the metadata
        // inside the plugin options.

        /// <#Description#>
        public let metadata: [String: String]?

        /// <#Description#>
        /// - Parameter metadata: <#metadata description#>
        public init(metadata: [String: String]? = nil) {
            self.metadata = metadata
        }
    }
}

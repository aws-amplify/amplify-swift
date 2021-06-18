//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request for sign out user
public struct AuthSignOutRequest: AmplifyOperationRequest {

    /// Extra request options defined in `AuthSignOutRequest.Options`
    public var options: Options

    public init(options: Options) {

        self.options = options
    }
}

public extension AuthSignOutRequest {

    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public let globalSignOut: Bool

        public init(globalSignOut: Bool = false,
                    pluginOptions: Any? = nil) {
            self.globalSignOut = globalSignOut
            self.pluginOptions = pluginOptions
        }
    }
}

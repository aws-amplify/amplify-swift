//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthSignOutRequest: AmplifyOperationRequest {

    /// <#Description#>
    public var options: Options

    /// <#Description#>
    /// - Parameter options: <#options description#>
    public init(options: Options) {

        self.options = options
    }
}

public extension AuthSignOutRequest {

    /// <#Description#>
    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        /// <#Description#>
        public let globalSignOut: Bool

        /// <#Description#>
        /// - Parameters:
        ///   - globalSignOut: <#globalSignOut description#>
        ///   - pluginOptions: <#pluginOptions description#>
        public init(globalSignOut: Bool = false,
                    pluginOptions: Any? = nil) {
            self.globalSignOut = globalSignOut
            self.pluginOptions = pluginOptions
        }
    }
}

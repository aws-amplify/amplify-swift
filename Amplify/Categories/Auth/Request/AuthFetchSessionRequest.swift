//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request to fetch the current auth session
public struct AuthFetchSessionRequest: AmplifyOperationRequest {

    /// Extra request options defined in `AuthFetchSessionRequest.Options`
    public var options: Options

    public init(options: Options) {

        self.options = options
    }
}

public extension AuthFetchSessionRequest {

    struct Options {

        public let forceRefresh: Bool

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(
            forceRefresh: Bool = false,
            pluginOptions: Any? = nil) {
            self.forceRefresh = forceRefresh
            self.pluginOptions = pluginOptions
        }
    }
}

extension AuthFetchSessionRequest.Options {
    public static func forceRefresh() -> AuthFetchSessionRequest.Options {
        return AuthFetchSessionRequest.Options(forceRefresh: true)
    }
}


//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request for listing WebAuthn Credentials
///
/// - Tag: AuthListWebAuthnCredentialsRequest
public struct AuthListWebAuthnCredentialsRequest: AmplifyOperationRequest {
    /// Extra request options
    ///
    /// - Tag: AuthListWebAuthnCredentialsRequest.options
    public let options: Options

    /// - Tag: AuthListWebAuthnCredentialsRequest.init
    public init(options: Options) {
        self.options = options
    }
}

public extension AuthListWebAuthnCredentialsRequest {
    /// Options available to callers of
    /// [AuthCategoryWebAuthnBehaviour.list](x-source-tag://AuthCategoryWebAuthnBehaviour.list).
    ///
    /// - Tag: AuthListWebAuthnCredentialsRequestOptions
    struct Options {
        /// Number between 1 and 20 that indicates the limit of how many credentials to retrieve
        ///
        /// - Tag: AuthListWebAuthnCredentialsRequestOptions.pageSize
        public let pageSize: UInt

        /// String indicating the page offset at which to resume a listing.
        ///
        /// This is usually a copy of the value from
        /// [AuthListWebAuthnCredentialsResult.nextToken](x-source-tag://AuthListWebAuthnCredentialsResult.nextToken).
        ///
        /// - Tag: AuthListWebAuthnCredentialsRequestOptions.nextToken
        public let nextToken: String?

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        ///
        /// - Tag: AuthListWebAuthnCredentialsRequestOptions.pluginOptions
        public let pluginOptions: Any?

        /// - Tag: AuthListWebAuthnCredentialsRequestOptions.init
        public init(
            pageSize: UInt = 20,
            nextToken: String? = nil,
            pluginOptions: Any? = nil
        ) {
            self.pageSize = pageSize
            self.nextToken = nextToken
            self.pluginOptions = pluginOptions
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request to sign in a user with Passwordless Magic Link flow
public struct AuthSignInWithMagicLinkRequest: AmplifyOperationRequest {

    /// User name for which the magic link was requested
    public let username: String

    /// The flow that the request should begin with.
    public let flow: AuthPasswordlessFlow

    /// The redirect url that the magic link will be configured with
    public let redirectURL: String
    
    /// Extra request options defined in `AuthSignInWithMagicLinkRequest.Options`
    public var options: Options

    public init(username: String, flow: AuthPasswordlessFlow, redirectURL: String, options: Options) {
        self.username = username
        self.flow = flow
        self.redirectURL = redirectURL
        self.options = options
    }
}

public extension AuthSignInWithMagicLinkRequest {

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

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request to sign in a user
public struct AuthSignInRequest: AmplifyOperationRequest {

    /// User name to use for the sign in flow
    public let username: String?

    /// Password to use for the sign in flow
    public let password: String?

    /// Extra request options defined in `AuthSignInRequest.Options`
    public var options: Options

    public init(username: String?, password: String?, options: Options) {
        self.username = username
        self.password = password
        self.options = options
    }
}

public extension AuthSignInRequest {

    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

#if os(iOS) || os(macOS) || os(visionOS)
        /// Provide a presentation anchor if you are signing in with WebAuthn. The WebAuthn assertion will be presented
        /// in the presentation anchor provided.
        public let presentationAnchorForWebAuthn: AuthUIPresentationAnchor?

        public init(
            presentationAnchorForWebAuthn: AuthUIPresentationAnchor? = nil,
            pluginOptions: Any? = nil
        ) {
            self.presentationAnchorForWebAuthn = presentationAnchorForWebAuthn
            self.pluginOptions = pluginOptions
        }
#else
        public init(pluginOptions: Any? = nil) {
            self.pluginOptions = pluginOptions
        }
#endif
    }
}

extension AuthSignInRequest.Options: @unchecked Sendable { }

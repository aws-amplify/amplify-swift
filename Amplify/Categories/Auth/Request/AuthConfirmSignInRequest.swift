//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request for confirming sign in flow
public struct AuthConfirmSignInRequest: AmplifyOperationRequest {

    /// Challenge response as part of sign in flow.
    ///
    /// The value of `challengeResponse` varies based on the sign in next step defined in `AuthSignInStep`
    public let challengeResponse: String

    /// Extra request options defined in `AuthConfirmSignInRequest.Options`
    public var options: Options

    public init(challengeResponse: String, options: Options) {
        self.challengeResponse = challengeResponse
        self.options = options
    }
}

public extension AuthConfirmSignInRequest {

    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

#if os(iOS) || os(macOS) || os(visionOS)
        /// Provide a presentation anchor if you are confirming sign in with WebAuthn. The WebAuthn assertion will be presented
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

extension AuthConfirmSignInRequest.Options: @unchecked Sendable { }

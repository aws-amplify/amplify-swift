//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

/// Request for creating a new WebAuthn Credential and associating it with the signed in user
public struct AuthAssociateWebAuthnCredentialRequest: AmplifyOperationRequest {
    /// Presentation anchor on which the credential request displayed
    public let presentationAnchor: AuthUIPresentationAnchor?

    /// Extra request options defined in `AuthAssociateWebAuthnCredentialRequest.Options`
    public let options: Options

    public init(
        presentationAnchor: AuthUIPresentationAnchor?,
        options: Options
    ) {
        self.presentationAnchor = presentationAnchor
        self.options = options
    }
}

public extension AuthAssociateWebAuthnCredentialRequest {
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
#endif

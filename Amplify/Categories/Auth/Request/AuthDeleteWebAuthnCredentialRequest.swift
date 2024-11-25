//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request for deleting a WebAuthn Credential
public struct AuthDeleteWebAuthnCredentialRequest: AmplifyOperationRequest {
    /// The ID for the credential that will be deleted
    public let credentialId: String

    /// Extra request options defined in `AuthDeleteWebAuthnCredentialRequest.Options`
    public let options: Options

    public init(
        credentialId: String,
        options: Options
    ) {
        self.credentialId = credentialId
        self.options = options
    }
}

public extension AuthDeleteWebAuthnCredentialRequest {
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

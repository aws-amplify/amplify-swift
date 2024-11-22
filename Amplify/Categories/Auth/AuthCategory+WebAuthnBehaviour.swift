//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: AuthCategoryWebAuthnBehaviour {
#if os(iOS) || os(macOS)
    @available(iOS 17.4, macOS 13.5, *)
    public func associateWebAuthnCredential(
        presentationAnchor: AuthUIPresentationAnchor? = nil,
        options: AuthAssociateWebAuthnCredentialRequest.Options? = nil
    ) async throws {
        try await plugin.associateWebAuthnCredential(
            presentationAnchor: presentationAnchor,
            options: options
        )
    }
#elseif os(visionOS)
    public func associateWebAuthnCredential(
        presentationAnchor: AuthUIPresentationAnchor,
        options: AuthAssociateWebAuthnCredentialRequest.Options? = nil
    ) async throws {
        try await plugin.associateWebAuthnCredential(
            presentationAnchor: presentationAnchor,
            options: options
        )
    }
#endif

    public func listWebAuthnCredentials(
        options: AuthListWebAuthnCredentialsRequest.Options? = nil
    ) async throws -> AuthListWebAuthnCredentialsResult {
        return try await plugin.listWebAuthnCredentials(
            options: options
        )
    }

    public func deleteWebAuthnCredential(
        credentialId: String,
        options: AuthDeleteWebAuthnCredentialRequest.Options? = nil
    ) async throws {
        try await plugin.deleteWebAuthnCredential(
            credentialId: credentialId,
            options: options
        )
    }
}

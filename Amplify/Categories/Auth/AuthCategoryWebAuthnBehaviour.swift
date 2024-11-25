//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthCategoryWebAuthnBehaviour: AnyObject {
#if os(iOS) || os(macOS)
    /// - Tag: AuthCategoryWebAuthnBehaviour.associate
    @available(iOS 17.4, macOS 13.5, *)
    func associateWebAuthnCredential(
        presentationAnchor: AuthUIPresentationAnchor?,
        options: AuthAssociateWebAuthnCredentialRequest.Options?
    ) async throws
#elseif os(visionOS)
    func associateWebAuthnCredential(
        presentationAnchor: AuthUIPresentationAnchor,
        options: AuthAssociateWebAuthnCredentialRequest.Options?
    ) async throws
#endif

    /// - Tag: AuthCategoryWebAuthnBehaviour.list
    func listWebAuthnCredentials(
        options: AuthListWebAuthnCredentialsRequest.Options?
    ) async throws -> AuthListWebAuthnCredentialsResult

    /// - Tag: AuthCategoryWebAuthnBehaviour.delete
    func deleteWebAuthnCredential(
        credentialId: String,
        options: AuthDeleteWebAuthnCredentialRequest.Options?
    ) async throws
}

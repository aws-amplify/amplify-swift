//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents the output of a call to
/// [`AuthCategoryWebAuthnBehaviour.listWebAuthnCredentials(options:)`](x-source-tag://AuthCategoryWebAuthnBehaviour.list)
///
/// - Tag: AuthListWebAuthnCredentialsResult
public struct AuthListWebAuthnCredentialsResult {
    /// The list of WebAuthn credentials
    ///
    /// - Tag: AuthListWebAuthnCredentialsResult.credentials
    public var credentials: [AuthWebAuthnCredential]

    /// String indicating the page offset at which to resume a listing.
    ///
    /// This value is usually copied to
    /// [AuthListWebAuthnCredentialsRequest.Options.nextToken](x-source-tag://AuthListWebAuthnCredentialsRequestOptions.nextToken).
    ///
    /// - Tag: AuthListWebAuthnCredentialsResult.nextToken
    public let nextToken: String?

    /// - Tag: AuthListWebAuthnCredentialsResult.init
    public init(
        credentials: [AuthWebAuthnCredential],
        nextToken: String?
    ) {
        self.credentials = credentials
        self.nextToken = nextToken
    }
}

/// Defines a WebAuthn credential
/// - Tag: AuthWebAuthnCredential
public protocol AuthWebAuthnCredential {
    /// The credential's ID
    var credentialId: String { get }

    /// The credential's creation date
    var createdAt: Date { get }

    /// The credential's relying party ID
    var relyingPartyId: String { get }

    /// The credential's friendly name
    var friendlyName: String? { get }
}

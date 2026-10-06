//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A WebAuthn credential (a passkey) registered for the signed-in user. Amplify's `AuthWebAuthnCredential`
/// (the plugin's `AWSCognitoWebAuthnCredential`), owned by the client.
@_spi(AmplifyExperimental)
public struct AuthClientWebAuthnCredential: Sendable, Equatable, Hashable {

    /// The credential's identifier, as `deleteWebAuthnCredential(credentialId:)` takes it.
    public let credentialId: String

    /// When the credential was registered.
    public let createdAt: Date

    /// The relying party the credential is registered for.
    public let relyingPartyId: String

    /// The credential's friendly name, or `nil` when it has none. An empty name is `nil`, as the plugin's.
    public let friendlyName: String?

    public init(credentialId: String, createdAt: Date, relyingPartyId: String, friendlyName: String? = nil) {
        self.credentialId = credentialId
        self.createdAt = createdAt
        self.relyingPartyId = relyingPartyId
        self.friendlyName = friendlyName
    }
}

/// Options for `listWebAuthnCredentials(options:)`. Amplify's `AuthListWebAuthnCredentialsRequest.Options`
/// without `pluginOptions`: the client has no plugin options.
@_spi(AmplifyExperimental)
public struct AuthClientListWebAuthnCredentialsOptions: Sendable, Equatable {

    /// The largest page size Cognito accepts (`MaxResults`), and the default.
    public static let maximumPageSize: UInt = 20

    /// How many credentials to return, from 1 to 20. Checked before any request: a value outside that range
    /// throws `AuthClientError.validation(field: "pageSize", …)`.
    public var pageSize: UInt

    /// Where to resume a listing: the `nextToken` of the previous page's result, or `nil` for the first page.
    public var nextToken: String?

    public init(pageSize: UInt = AuthClientListWebAuthnCredentialsOptions.maximumPageSize, nextToken: String? = nil) {
        self.pageSize = pageSize
        self.nextToken = nextToken
    }
}

/// One page of the signed-in user's WebAuthn credentials. Amplify's `AuthListWebAuthnCredentialsResult`.
@_spi(AmplifyExperimental)
public struct AuthClientListWebAuthnCredentialsResult: Sendable, Equatable {

    /// The credentials on this page. Entries Cognito returns without an identifier, a creation date or a
    /// relying party are left out, as the plugin does.
    public let credentials: [AuthClientWebAuthnCredential]

    /// Where the next page starts (pass it in `AuthClientListWebAuthnCredentialsOptions.nextToken`), or `nil`
    /// after the last page.
    public let nextToken: String?

    public init(credentials: [AuthClientWebAuthnCredential], nextToken: String? = nil) {
        self.credentials = credentials
        self.nextToken = nextToken
    }
}

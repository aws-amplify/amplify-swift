//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import Smithy
import SmithyIdentity

/// The AWS credential identity resolver of both Cognito SDK clients the client builds. It always throws.
///
/// Every Cognito operation the client calls is unsigned: `InitiateAuth`, `RespondToAuthChallenge`,
/// `GetTokensFromRefreshToken`, `RevokeToken`, `GlobalSignOut`, `DeleteUser`, `GetId`,
/// `GetCredentialsForIdentity` and the rest take no AWS credentials. So a request that asks for them is
/// a bug, and it fails here, loudly, before it is sent.
///
/// The plugin's resolver calls `Amplify.Auth.fetchAuthSession()`, a global the client must never
/// reach. The SDK's default resolver walks the default credential chain, which on a simulator or a Mac
/// can pick up a developer's `~/.aws` credentials and sign a request the client never meant to sign.
/// This resolver does neither.
///
/// The recovery advice depends on which SDK client asked. The user pool client has an escape hatch that can
/// install a resolver (`configureUserPoolClient`, which runs after this one is installed). The identity
/// client has none, so the advice there is to build a separate `CognitoIdentityClient`.
struct CognitoUnsignedOperationResolver: AWSCredentialIdentityResolver {

    /// Which of the session's SDK clients this resolver is installed on.
    enum Client: Sendable {
        case userPool
        case identity
    }

    let client: Client

    init(for client: Client) {
        self.client = client
    }

    func getIdentity(identityProperties: Smithy.Attributes?) async throws -> AWSCredentialIdentity {
        throw AuthClientError.configuration(
            "A Cognito operation that needs AWS credentials was called, and the client's Cognito SDK clients have none.",
            recoverySuggestion
        )
    }

    var recoverySuggestion: RecoverySuggestion {
        switch client {
        case .userPool:
            """
            Every operation AmplifyCognitoClient calls is unsigned. To call an operation that needs AWS credentials \
            through getUserPoolClient(), set awsCredentialIdentityResolver in Options.configureUserPoolClient.
            """
        case .identity:
            """
            Every operation AmplifyCognitoClient calls is unsigned, and getIdentityClient() has no way to add \
            credentials. To call an identity pool operation that needs AWS credentials, build your own \
            CognitoIdentityClient with the credentials it needs.
            """
        }
    }
}

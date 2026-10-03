//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Internal representation of Credentials Auth category maintain.
package enum AmplifyCredentials {

    case userPoolOnly(signedInData: SignedInData)

    case identityPoolOnly(
        identityID: String,
        credentials: EngineAWSCredentials
    )

    case identityPoolWithFederation(
        federatedToken: FederatedToken,
        identityID: String,
        credentials: EngineAWSCredentials
    )

    case userPoolAndIdentityPool(
        signedInData: SignedInData,
        identityID: String,
        credentials: EngineAWSCredentials
    )

    case noCredentials
}

extension AmplifyCredentials: Codable { }

extension AmplifyCredentials: Equatable { }

extension AmplifyCredentials: Sendable { }

extension AmplifyCredentials: CustomDebugStringConvertible {
    package var debugDescription: String {
        switch self {

        case .userPoolOnly:
            return "userPoolOnly"
        case .identityPoolOnly:
            return "identityPoolOnly"
        case .identityPoolWithFederation:
            return "identityPoolWithFederation"
        case .userPoolAndIdentityPool:
            return "userPoolAndIdentityPool"
        case .noCredentials:
            return "noCredentials"
        }
    }

}

package extension AmplifyCredentials {
    /// How long before expiry credentials count as expired: two minutes. Moved here from the plugin's
    /// `AmplifyCredentials+CognitoSession.swift`, which reads it too, because `InitializeRefreshSession` does.
    static let expiryBufferInSeconds: TimeInterval = 2 * 60

    /// Whether the credentials are usable at `now`: there are some, and none expires within
    /// `expiryBufferInSeconds` of it. Moved here from the plugin's `AmplifyCredentials+CognitoSession.swift`
    /// with an `at:` parameter, so the Cognito client can pass its own clock. The default,
    /// the current time, is what the plugin has always used.
    func areValid(at now: Date = Date()) -> Bool {
        return self != .noCredentials &&
        !doesExpire(in: Self.expiryBufferInSeconds, at: now)
    }

    private func doesExpire(in expiryBuffer: TimeInterval, at now: Date) -> Bool {
        switch self {
        case .userPoolOnly(signedInData: let data):
            return data.cognitoUserPoolTokens.doesExpire(in: expiryBuffer, at: now)

        case .identityPoolOnly(identityID: _, credentials: let awsCredentials):
            return awsCredentials.doesExpire(in: expiryBuffer, at: now)

        case .userPoolAndIdentityPool(
            signedInData: let data,
            identityID: _,
            credentials: let awsCredentials
        ):
            return data.cognitoUserPoolTokens.doesExpire(in: expiryBuffer, at: now) ||
                awsCredentials.doesExpire(in: expiryBuffer, at: now)

        case .identityPoolWithFederation(_, _, let awsCredentials):
            return awsCredentials.doesExpire(in: expiryBuffer, at: now)

        case .noCredentials:
            return true
        }
    }

    var hasUserPoolTokens: Bool {
        switch self {
        case .userPoolOnly, .userPoolAndIdentityPool:
            return true
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            return false
        }
    }
}

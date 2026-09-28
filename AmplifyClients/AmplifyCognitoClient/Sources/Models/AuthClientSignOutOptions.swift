//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Options for `AmplifyCognitoClient.signOut(options:)`.
///
/// The client's counterpart of Amplify core's `AuthSignOutRequest.Options`, plus `purgeStoredSession`. To
/// show the hosted UI's sign-out page, pass a window to `signOut(presentationAnchor:options:)`.
@_spi(AmplifyExperimental)
public struct AuthClientSignOutOptions {

    /// Signs the user out of every device, not just this session: Cognito revokes all of the user's
    /// refresh tokens. That is a server-side revocation scoped to the *user*, so another session holding
    /// the same user — in this app or elsewhere — finds out on its next refresh, as `sessionExpired`.
    public var globalSignOut: Bool

    /// Also removes the session's saved row, so `storedSessions(configuration:accessGroup:includingSignedOut:)`
    /// no longer lists it. By default a signed-out session keeps its row, so a picker that lists with
    /// `includingSignedOut: true` can offer to resume it. Deleting the row is not recoverable, so it is
    /// opt-in.
    public var purgeStoredSession: Bool

    /// - Parameters:
    ///   - globalSignOut: Whether to sign the user out of every device. `false` by default.
    ///   - purgeStoredSession: Whether to remove the session's saved row too. `false` by default.
    public init(globalSignOut: Bool = false, purgeStoredSession: Bool = false) {
        self.globalSignOut = globalSignOut
        self.purgeStoredSession = purgeStoredSession
    }
}

extension AuthClientSignOutOptions: Equatable {}

extension AuthClientSignOutOptions: Sendable {}

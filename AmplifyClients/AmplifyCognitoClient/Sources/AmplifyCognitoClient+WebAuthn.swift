//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
import Foundation
import InternalAWSCognitoAuth

// WebAuthn: passkeys registered, listed and deleted, and passkey sign-in.

#if os(iOS) || os(macOS) || os(visionOS)
/// WebAuthn with a passkey sheet: registering a passkey, and signing in with one. Each takes the window the
/// sheet attaches to, which the client never looks for itself.
///
/// **One sheet per process.** A passkey sheet and the hosted UI's browser share one process-wide lease: while
/// any session shows one, another session's (or this session's) passkey ceremony throws
/// `AuthClientError.browserBusy(holder:)` and presents nothing.
///
/// **Cancellation.** The user closing the sheet is `AuthClientError.userCancelled`. Cancelling the calling
/// task closes the sheet, and the call throws `CancellationError`.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Registers a passkey for this session's signed-in user: `StartWebAuthnRegistration`, the passkey sheet
    /// over `presentationAnchor`, then `CompleteWebAuthnRegistration`.
    ///
    /// Uses this session's access token, refreshed first if it needs it, and never changes the session's
    /// saved record or disturbs a sign-in waiting on a challenge.
    ///
    /// Unlike the plugin, the window is required: without one the plugin shows the sheet over a window of its
    /// own, which with several sessions could be another session's.
    ///
    /// - Parameter presentationAnchor: The window the passkey sheet attaches to, such as the active scene's
    ///   key window. It must stay open until the ceremony finishes.
    /// - Throws: `AuthClientError.configuration` without a user pool; `.notSignedIn` for a signed-out, guest
    ///   or federated session, and while a sign-in on this session waits on a challenge; `.sessionExpired`
    ///   when the refresh the session needed first failed for good; `.browserBusy(holder:)` while another
    ///   sheet is up; `.validation(field: "presentationAnchor")` if the window has gone when the ceremony
    ///   starts, before anything is presented; `.userCancelled` when the user closes the sheet;
    ///   `.webAuthnCeremonyFailed` when the device cannot create the passkey (`.credentialAlreadyExists` if
    ///   it already holds one for this user); `.notAuthorized` or `.service` as Cognito answers
    ///   (`.webAuthnNotEnabled` when the pool has no WebAuthn); `.invalidState` if a sign-out, purge or deletion of
    ///   this session stops it (a sign-out that shows the hosted UI's logout page does so first, even if the user
    ///   then closes the page); `.userCancelled` also when `cancelWebUISignIn()` or `resetSystemSheet()` closes its
    ///   sheet; `CancellationError` if the calling task is cancelled.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    @MainActor
    func associateWebAuthnCredential(presentationAnchor: AuthClientPresentationAnchor) async throws {
        let anchor = EnginePresentationAnchorBox(presentationAnchor)
        let core = core
        try await core.associateWebAuthnCredential(anchor: anchor)
    }

    /// `signIn(username:password:options:)`, with the window a passkey sheet attaches to.
    ///
    /// With `authFlowType: .userAuth(preferredFirstFactor: .webAuthn)` (and usually no password), the passkey
    /// sheet is shown over `presentationAnchor`, and the result is `.done`. Without a preference, a
    /// `.continueSignInWithFirstFactorSelection` step may offer `.webAuthn`; answer it with
    /// `confirmSignIn(challengeResponse: "WEB_AUTHN")`, which uses this window unless given its own. Any
    /// other factor signs in as `signIn(username:password:options:)` does, and never shows a sheet.
    ///
    /// A failed passkey step ends the sign-in: call `signIn` again to retry. The window is held weakly: if it
    /// has gone when the ceremony starts, nothing is presented.
    ///
    /// - Parameters:
    ///   - username: The user's username or alias.
    ///   - password: The password, or `nil` for a passwordless first factor.
    ///   - presentationAnchor: The window the passkey sheet attaches to.
    ///   - options: The flow and the client metadata.
    /// - Returns: as `signIn(username:password:options:)`.
    /// - Throws: as `signIn(username:password:options:)`, and for a passkey step: `.browserBusy(holder:)`
    ///   while another sheet is up; `.validation(field: "presentationAnchor")` if the window has gone;
    ///   `.userCancelled` when the user closes the sheet, or `cancelWebUISignIn()` or `resetSystemSheet()`
    ///   closes it; `.webAuthnCeremonyFailed` when the device cannot use a passkey; `.service` for Cognito's
    ///   WebAuthn answers; `CancellationError` if the calling task is cancelled while the sheet is up, or before
    ///   it would appear.
    @MainActor
    func signIn(
        username: String,
        password: String? = nil,
        presentationAnchor: AuthClientPresentationAnchor,
        options: AuthClientSignInOptions = AuthClientSignInOptions()
    ) async throws -> AuthClientSignInResult {
        let anchor = EnginePresentationAnchorBox(presentationAnchor)
        let core = core
        return try await core.signIn(username: username, password: password, options: options, presentationAnchor: anchor)
    }

    /// `confirmSignIn(challengeResponse:options:)`, with the window a `"WEB_AUTHN"` answer's passkey sheet
    /// attaches to, in place of the one given to `signIn`.
    ///
    /// - Parameters:
    ///   - challengeResponse: The answer; `"WEB_AUTHN"` (`AuthClientFactorType.webAuthn`) to a first-factor
    ///     selection shows the passkey sheet.
    ///   - presentationAnchor: The window the passkey sheet attaches to.
    ///   - options: User attributes, client metadata and, for a TOTP setup, the device name.
    /// - Returns: as `confirmSignIn(challengeResponse:options:)`.
    /// - Throws: as `confirmSignIn(challengeResponse:options:)`, and for a passkey step as
    ///   `signIn(username:password:presentationAnchor:options:)`.
    @MainActor
    func confirmSignIn(
        challengeResponse: String,
        presentationAnchor: AuthClientPresentationAnchor,
        options: AuthClientConfirmSignInOptions = AuthClientConfirmSignInOptions()
    ) async throws -> AuthClientSignInResult {
        let anchor = EnginePresentationAnchorBox(presentationAnchor)
        let core = core
        return try await core.confirmSignIn(challengeResponse: challengeResponse, options: options, presentationAnchor: anchor)
    }
}
#endif

/// WebAuthn credentials: the signed-in user's passkeys, listed and deleted, for this session's user only.
///
/// Each call uses this session's access token, refreshed first if it needs it, and never changes the
/// session's saved record or disturbs a sign-in waiting on a challenge. Neither presents anything, so neither
/// needs a window, and both are on every platform, as the plugin's are.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// One page of the signed-in user's WebAuthn credentials (passkeys).
    ///
    /// Pass the result's `nextToken` back in `options` for the next page. Entries Cognito returns without
    /// an identifier, a creation date or a relying party are left out, and an empty friendly name is `nil`,
    /// as the plugin does.
    ///
    /// - Parameter options: The page size (1…20, default 20) and where to resume.
    /// - Throws: `AuthClientError.validation(field: "pageSize", …)` for a page size outside 1…20, before
    ///   anything else; `.configuration` without a user pool; `.notSignedIn` for a signed-out, guest or
    ///   federated session, and while a sign-in on this session waits on a challenge; `.sessionExpired` when
    ///   the refresh the session needed first failed for good; `.storageUnavailable`; `.notAuthorized` when
    ///   Cognito refuses the access token (revoked, for example); `.service` for Cognito's other answers
    ///   (`.webAuthnNotEnabled` when the pool has no WebAuthn); `.unknown` for a failure the client does not
    ///   recognise; `CancellationError` if the calling task is cancelled.
    func listWebAuthnCredentials(
        options: AuthClientListWebAuthnCredentialsOptions = AuthClientListWebAuthnCredentialsOptions()
    ) async throws -> AuthClientListWebAuthnCredentialsResult {
        let range = 1 ... AuthClientListWebAuthnCredentialsOptions.maximumPageSize
        guard range.contains(options.pageSize) else {
            throw AuthClientError.webAuthnPageSizeOutOfRange
        }
        let pageSize = Int(options.pageSize)
        let nextToken = options.nextToken
        let core = core
        let page = try await core.signedInOperation("list the WebAuthn credentials") { engine, payload in
            try await engine.listWebAuthnCredentials(payload, pageSize: pageSize, nextToken: nextToken)
        }
        return AuthClientListWebAuthnCredentialsResult(page)
    }

    /// Deletes one of the signed-in user's WebAuthn credentials (passkeys).
    ///
    /// This removes the credential from the user pool, so it can no longer sign the user in. The passkey
    /// itself stays in the device's password manager until the user removes it there.
    ///
    /// - Parameter credentialId: The credential's `credentialId`, from `listWebAuthnCredentials(options:)`.
    /// - Throws: as `listWebAuthnCredentials(options:)`, without the page-size check.
    func deleteWebAuthnCredential(credentialId: String) async throws {
        let core = core
        try await core.signedInOperation("delete the WebAuthn credential") { engine, payload in
            try await engine.deleteWebAuthnCredential(payload, credentialId: credentialId)
        }
    }
}

extension AuthClientError {

    /// A list page size outside Cognito's `MaxResults`, 1…20. Checked by the client, where the plugin
    /// leaves it to Cognito's `InvalidParameterException`.
    static var webAuthnPageSizeOutOfRange: AuthClientError {
        let maximum = AuthClientListWebAuthnCredentialsOptions.maximumPageSize
        return .validation(
            field: "pageSize",
            "pageSize must be from 1 to \(maximum) to listWebAuthnCredentials",
            "Pass a pageSize from 1 to \(maximum), or leave the default of \(maximum)."
        )
    }
}

extension AuthClientListWebAuthnCredentialsResult {

    /// The engine's page, as the public result.
    init(_ page: EngineWebAuthnCredentialPage) {
        self.init(credentials: page.credentials.map(AuthClientWebAuthnCredential.init), nextToken: page.nextToken)
    }
}

extension AuthClientWebAuthnCredential {

    /// The engine's credential, as the public one. The engine has already made an empty name `nil`.
    init(_ credential: EngineWebAuthnCredential) {
        self.init(
            credentialId: credential.credentialId,
            createdAt: credential.createdAt,
            relyingPartyId: credential.relyingPartyId,
            friendlyName: credential.friendlyName
        )
    }
}

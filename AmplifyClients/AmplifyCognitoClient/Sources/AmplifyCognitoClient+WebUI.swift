//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation
import InternalAWSCognitoAuth

// The hosted UI: per session, each call acts on this client's `sessionId`. One system sheet is shown at a time per process, whichever session asks: see
// `WebUIOptions.whenBrowserBusy`.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Signs this session in through the hosted UI, in a browser sheet over `presentationAnchor`'s window.
    ///
    /// The whole round trip runs while this session holds the process's system sheet: the browser, then the
    /// exchange of the returned code for tokens, then the identity checks. The client checks that the tokens
    /// belong to this flow and this app, and to the user `options.identityExpectation` asks for; a failed check
    /// signs nobody in and stores nothing. A password sign-in waiting on a challenge is cancelled first.
    ///
    /// Private (ephemeral) by default, unlike the plugin: see `WebUIOptions.prefersEphemeralSession`.
    ///
    /// - Returns: `.done`. The result can carry a later step without an API change; the hosted UI has none today.
    /// - Throws:
    ///   - `invalidState` if this session is signed in or federated, or has no usable window (`invalidContext`);
    ///   - `configuration` without a user pool or a hosted UI (`auth.oauth`), or with a bad redirect URI;
    ///   - `browserBusy(holder:)` if the system sheet is held (by a hosted-UI sign-in or sign-out page, or a
    ///     passkey sheet, of another session or of this one), or this session already has a hosted-UI sign-in
    ///     in progress, or a `.wait(timeout:)` expired first;
    ///   - `validation(field: "presentationAnchor")` if the window has closed, before anything is shown;
    ///   - `userCancelled` if the user closed the browser, or `cancelWebUISignIn()` or `resetSystemSheet()` ran;
    ///   - `CancellationError` if the calling task was cancelled, which also dismisses the browser;
    ///   - `invalidState` ("The sign-in was cancelled…") if this session was signed out, purged or deleted
    ///     meanwhile;
    ///   - `unexpectedIdentity` if another user than the expected one came back;
    ///   - `service` for a response that could not be verified, and Cognito's and the browser's failures;
    ///   - `storageUnavailable` if storage could not be read, or the result could not be saved;
    ///   - `unknown` if the session's saved record cannot be read by this version, or for a failure the client
    ///     does not recognise.
    @MainActor
    func signInWithWebUI(
        presentationAnchor: AuthClientPresentationAnchor,
        options: WebUIOptions = WebUIOptions()
    ) async throws -> AuthClientSignInResult {
        let anchor = EnginePresentationAnchorBox(presentationAnchor)
        let core = core
        return try await core.signInWithWebUI(anchor: anchor, options: options)
    }

    /// Signs this session in through the hosted UI, straight to `provider`, skipping Cognito's provider picker:
    /// `signInWithWebUI(presentationAnchor:options:)` with `options.provider` set to `provider`. An
    /// `options.idpIdentifier` still wins over it, as with the plugin.
    @MainActor
    func signInWithWebUI(
        for provider: AuthClientProvider,
        presentationAnchor: AuthClientPresentationAnchor,
        options: WebUIOptions = WebUIOptions()
    ) async throws -> AuthClientSignInResult {
        var options = options
        options.provider = provider
        return try await signInWithWebUI(presentationAnchor: presentationAnchor, options: options)
    }

    /// Signs this session out, as `signOut(options:)` does, first showing the hosted UI's sign-out in
    /// `presentationAnchor`'s window if this session's sign-in shared the browser's cookies
    /// (`WebUIOptions.prefersEphemeralSession` off). That is what clears the hosted UI's cookie, so the next
    /// hosted-UI sign-in asks for credentials again. A private sign-in left no cookie, so nothing is shown.
    ///
    /// The sign-out page is shown at most once, while this session holds the system sheet. This session's
    /// refresh and other operations on its saved record wait until it closes; other sessions are unaffected.
    ///
    /// Before showing it, this cancels this session's passkey registration, if one is in flight (its call
    /// throws `invalidState`), even if the user then closes the page and stays signed in; and it waits up to
    /// 10 seconds for that passkey sheet to close. A sheet that does not close in time is reported as a held
    /// sheet, below.
    ///
    /// - Returns: as `signOut(options:)`. `.partial` with `hostedUIError` when the page could not be shown (the
    ///   sheet was held, the window closed, no hosted UI in the configuration, the browser failed): the session
    ///   is signed out on this device, but the browser keeps its sign-in.
    /// - Throws: `userCancelled` if the user closed the sign-out page: the session stays signed in, as with the
    ///   plugin. (A session whose refresh token is already dead signs out anyway, and reports it in
    ///   `.partial`.) Otherwise as `signOut(options:)`.
    @MainActor
    @discardableResult
    func signOut(
        presentationAnchor: AuthClientPresentationAnchor,
        options: AuthClientSignOutOptions = AuthClientSignOutOptions()
    ) async throws -> AuthClientSignOutResult {
        let window = SignOutWindow.anchor(EnginePresentationAnchorBox(presentationAnchor))
        let core = core
        return try await core.signOut(global: options.globalSignOut, purge: options.purgeStoredSession, window: window)
    }

    /// Cancels this session's hosted-UI sign-in, once it holds or is queued for the system sheet: the browser
    /// is dismissed and the call throws `userCancelled`. Idempotent; never throws; a no-op when there is none.
    ///
    /// A call still waiting behind another of this session's sign-ins (its sign-in lock) is not reached yet, and
    /// goes on; cancel its task to stop it there.
    ///
    /// It also closes this session's passkey sheet, but only **while the sheet is up**: the ceremony holds
    /// the system sheet from just before the sheet is presented until it answers. The passkey call then throws
    /// `userCancelled`. Before or after that window (the Cognito calls around the ceremony) there is nothing
    /// to cancel; cancel the call's task instead.
    func cancelWebUISignIn() async {
        let core = core
        await core.cancelWebUISignIn()
    }

    /// Frees the process's system sheet, whoever holds it: a recovery tool for a sign-in that has stopped
    /// responding. A hosted-UI sign-in or a passkey ceremony holding it throws `userCancelled` at once; a
    /// hosted-UI sign-out page holding it is closed, and its sign-out reports what it did. The next call may
    /// then show its sheet. In memory only.
    ///
    /// The system sheet is one per process, shared by every client's sessions, so this and
    /// `systemSheetHolder` see every session.
    ///
    /// - Returns: the session that was holding it, or `nil` if it was free.
    @discardableResult
    static func resetSystemSheet() async -> SessionID? {
        await SystemSheetLock.shared.reset()
    }

    /// The session holding the process's system sheet, or `nil`: for "Finish signing in to <name> first".
    static var systemSheetHolder: SessionID? {
        get async { await SystemSheetLock.shared.currentHolder }
    }
}
#endif

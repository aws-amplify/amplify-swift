//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation
import InternalAWSCognitoAuth

// The hosted UI: per session, each call acts on this client's `sessionId`. The client's sessions show one system sheet
// at a time per process, whichever session asks (the Auth plugin's sheets do not take part): see
// `WebUIOptions.whenBrowserBusy`.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Signs this session in through the hosted UI, in a browser sheet over `presentationAnchor`'s window.
    ///
    /// The whole round trip runs while this session holds the process's system sheet: the browser, then the
    /// exchange of the returned code for tokens, then the identity checks, and with an identity pool, its
    /// `GetId` and `GetCredentialsForIdentity` calls. So other sessions can get `browserBusy` for a moment
    /// after the browser has closed, and an interrupt then (`cancelWebUISignIn()`, `resetSystemSheet()`)
    /// revokes a sign-in the user has already finished. The client checks that the tokens belong to this flow
    /// and this app, and to the user `options.identityExpectation` asks for; a failed check signs nobody in and
    /// stores nothing. A password sign-in waiting on a challenge is cancelled once this session holds the
    /// sheet, so a refusal or a timeout leaves it waiting. Until then, with `.wait(timeout:)` for up to the whole
    /// wait, the challenge is still reported, but a `confirmSignIn` answering it queues behind this call, and fails
    /// with `invalidState` if this call then takes the sheet; `cancelWebUISignIn()`, or cancelling this call, ends
    /// the wait and keeps the challenge.
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
    /// If another session holds the system sheet, the sign-out is `.failed(.browserBusy(holder:))` at once, and
    /// this session's passkey registration, if one is in flight, is left running. Otherwise, before showing the
    /// page, this cancels that registration (its call throws `invalidState`), even if the user then closes the
    /// page and stays signed in; and it waits up to 10 seconds for that passkey sheet to close. A sheet that does
    /// not close in time is a held sheet, below.
    ///
    /// Never throws, as the plugin's `signOut` does not.
    ///
    /// - Returns: as `signOut(options:)`, and:
    ///   - `.failed(.userCancelled)` if the user closed the sign-out page: the session stays signed in, as with
    ///     the plugin. (A session whose refresh token is already dead signs out anyway, and reports it in
    ///     `.partial`.)
    ///   - `.failed` whenever the page could not be shown or completed, and the session stays signed in, with
    ///     nothing revoked, as with the plugin: `.configuration` if the configuration has no hosted UI, or no
    ///     sign-out redirect URI, to sign out of; `.browserBusy(holder:)` if another sheet holds the browser;
    ///     `.validation` if the window has closed; or the browser's own failure.
    @MainActor
    @discardableResult
    func signOut(
        presentationAnchor: AuthClientPresentationAnchor,
        options: AuthClientSignOutOptions = AuthClientSignOutOptions()
    ) async -> AuthClientSignOutResult {
        let window = SignOutWindow.anchor(EnginePresentationAnchorBox(presentationAnchor))
        let core = core
        return await core.signOut(global: options.globalSignOut, purge: options.purgeStoredSession, window: window)
    }

    /// Cancels this session's hosted-UI sign-in, once it holds or is queued for the system sheet: the browser
    /// is dismissed and the call throws `userCancelled` once the sign-in has released the sheet, so
    /// `systemSheetHolder` no longer names this session by then (it is `nil`, or a session that was queued behind
    /// it). If the sheet isn't released within a second (the browser is slow to close, or the code exchange was
    /// already running), the call throws anyway, and the sheet stays held until the sign-in's remaining calls
    /// finish. Idempotent; never throws; a no-op when there is none.
    ///
    /// It also closes this session's hosted-UI sign-out page, if one is showing: that sign-out is then
    /// `.failed(.userCancelled)` and the session stays signed in, as when the user closes the page (a session a
    /// refresh found expired signs out anyway, when the login signed out still has the refresh token found dead).
    ///
    /// A call still waiting behind another of this session's sign-ins (its sign-in lock) is not reached yet, and
    /// goes on; cancel its task to stop it there.
    ///
    /// It also closes this session's passkey sheet, but only **while the sheet is up**: the ceremony holds
    /// the system sheet from just before the sheet is presented until it answers. The passkey call then throws
    /// `userCancelled` once it has released the sheet. If the sheet isn't released within a second, the call throws
    /// anyway, and the sheet stays held until the passkey ceremony finishes. Before or after that window (the Cognito
    /// calls around the ceremony) there is nothing to cancel; cancel the call's task instead.
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
    /// `systemSheetHolder` see every session of every client. They do not see the Auth plugin's hosted UI or
    /// passkey sheets, which do not take part.
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

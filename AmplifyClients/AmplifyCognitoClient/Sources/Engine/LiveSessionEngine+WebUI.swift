//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// The hosted UI over the engine's own flow: the plugin's
/// `HostedUISignInHelper` and `AWSAuthSignOutTask`'s hosted-UI step, ported onto per-operation machines.
///
/// Each flow gets its own browser presenter, kept by the operation so a cancel can dismiss it, and
/// its own identity policy, which the environment carries. Neither outlives the operation.
extension LiveSessionEngine {

    // MARK: Pure

    nonisolated func signOutPresentsBrowser(_ payload: Data) throws -> Bool {
        switch try Self.credentials(in: payload) {
        case .userPoolOnly(let signedIn), .userPoolAndIdentityPool(let signedIn, _, _):
            return signedIn.signOutPresentsBrowser
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            return false
        }
    }

    // MARK: Sign-in

    func signInWithWebUI(_ request: EngineWebUISignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try requireUserPool()
        try requireHostedUI()
        #if os(iOS) || os(macOS) || os(visionOS)
        // Unboxed before anything is sent: a closed window is refused, and `nil` never reaches the presenter,
        // whose fallback would hunt for a window of its own.
        let box = request.anchor
        guard let anchor = await MainActor.run(body: { box.anchor }) else {
            throw Self.presentationAnchorGone()
        }
        try await beginSignIn(epoch: epoch)
        let presenter = resources.makeHostedUIPresenter()
        let operation = try resources.makeOperation(
            seed: current.flatMap(Self.guestSeed),
            presenter: presenter,
            identityPolicy: HostedUIIdentityPolicy(
                verifiesTokenClaims: true,
                expectedIdentity: request.identity.expectedIdentity,
                excludedSubjects: request.identity.excludedSubjects
            )
        )
        let options = HostedUIOptions(request.options, anchor: anchor, configuredScopes: configuredScopes)
        let resources = resources
        // Both handlers dismiss the browser: the outer one when the caller is cancelled (the core's lease
        // body, interrupted), which `run`'s unstructured task does not inherit; the inner one when
        // `cancelPendingSignIn` cancels that task.
        return try await withTaskCancellationHandler {
            try await run(epoch: epoch, on: operation) {
                try await withTaskCancellationHandler {
                    try await LiveHostedUISteps.signIn(options, on: operation, resources: resources)
                } onCancel: {
                    presenter.cancel()
                }
            }
        } onCancel: {
            presenter.cancel()
        }
        #else
        throw Self.hostedUIUnavailable()
        #endif
    }

    /// The configuration's OAuth scopes: what a request without its own asks for.
    private nonisolated var configuredScopes: [String] {
        resources.authConfiguration.getUserPoolConfiguration()?.hostedUIConfig?.oauth.scopes ?? []
    }

    // MARK: Sign-out

    /// The sign-out with the hosted UI's logout page shown first (`AWSAuthSignOutTask` with a window). The
    /// sign-in shared the browser's cookies, so the logout uses the same jar (the derived `inPrivate`).
    ///
    /// | The machine reaches | Result |
    /// |---|---|
    /// | signed out | the outcome, with any hosted-UI failure the engine continued past |
    /// | the hosted-UI step failed, `.cancelled` (the user closed the sheet) | throws `.userCancelled`, nothing revoked |
    /// | the hosted-UI step failed otherwise | reruns with the step skipped, and reports the failure in `hostedUIError` |
    ///
    /// A window that has gone is the last row without a browser: skipped, and `.validation` reported.
    nonisolated func revokePresenting(
        _ payload: Data,
        global: Bool,
        in box: EnginePresentationAnchorBox
    ) async throws -> EngineSignOutOutcome {
        #if os(iOS) || os(macOS) || os(visionOS)
        // The whole sign-out runs in a task of its own, which a caller's cancellation does not reach: the
        // caller's cancellation only dismisses the page. Once the page is closed, the machine either
        // stops (`.userCancelled`, nothing revoked) or goes on to revoke, and this returns what it really did,
        // rather than a `CancellationError` while the machine revokes on regardless. And a cancelled task's
        // events are dropped by the machine, so the rerun below must not run in one either.
        let presenter = resources.makeHostedUIPresenter()
        let flow = Task { [self] () -> EngineSignOutOutcome in
            guard let anchor = await MainActor.run(body: { box.anchor }) else {
                var outcome = try await revokeSkippingHostedUI(payload, global: global)
                outcome.hostedUIError = outcome.hostedUIError ?? Self.presentationAnchorGone()
                return outcome
            }
            let operation = try resources.makeOperation(seed: payload, presenter: presenter)
            try await operation.configure(resources.authConfiguration)
            let presented = try await operation.firstState(
                after: AuthenticationEvent(eventType: .signOutRequested(SignOutEventData(
                    globalSignOut: global,
                    presentationAnchor: anchor,
                    skipHostedUISignOut: false
                )))
            ) { state in
                try Self.presentedSignOutResult(at: state)
            }
            switch presented {
            case .signedOut(let outcome):
                return outcome
            case .hostedUIFailed(let failure):
                var outcome = try await revokeSkippingHostedUI(payload, global: global)
                outcome.hostedUIError = outcome.hostedUIError ?? failure
                return outcome
            }
        }
        return try await withTaskCancellationHandler {
            try await flow.value
        } onCancel: {
            presenter.cancel()
        }
        #else
        return try await revokeSkippingHostedUI(payload, global: global)
        #endif
    }

    /// Where a sign-out that showed the logout page ended.
    enum PresentedSignOut: Sendable {
        case signedOut(EngineSignOutOutcome)
        /// The browser step failed with something other than the user closing it.
        case hostedUIFailed(AuthClientError)
    }

    /// A presenting sign-out's result at `state`, or `nil` while it runs.
    static func presentedSignOutResult(at state: AuthState) throws -> PresentedSignOut? {
        guard case .configured(let authentication, _, _) = state else {
            return nil
        }
        switch authentication {
        case .signedOut(let signedOut):
            return .signedOut(outcome(of: signedOut))
        case .signingOut(.error(.hostedUI(let error))):
            let mapped = AuthClientError(engine: error.engineError)
            if case .cancelled = error {
                throw mapped
            }
            return .hostedUIFailed(mapped)
        case .signingOut(.error(let error)):
            throw AuthClientError(engine: error.engineError)
        default:
            return nil
        }
    }

    // MARK: Guards and errors

    /// The hosted UI needs `auth.oauth` with a sign-in and a sign-out redirect URI.
    nonisolated func requireHostedUI() throws {
        guard resources.authConfiguration.getUserPoolConfiguration()?.hostedUIConfig != nil else {
            throw Self.hostedUINotConfigured()
        }
    }

    static func hostedUINotConfigured() -> AuthClientError {
        .configuration(
            "The configuration has no hosted UI: auth.oauth, with a sign-in and a sign-out redirect URI, is missing.",
            "Add the hosted UI (oauth) settings to the configuration (the auth section of amplify_outputs.json)."
        )
    }

    static func presentationAnchorGone() -> AuthClientError {
        .validation(
            field: "presentationAnchor",
            "The window given as the presentation anchor has closed, so the browser could not be shown.",
            "Pass a window that is on screen."
        )
    }

    static func hostedUIUnavailable() -> AuthClientError {
        .invalidState(
            "The hosted UI is only available on iOS, macOS and visionOS.",
            "Sign in with signIn(username:password:options:) instead."
        )
    }
}

/// The hosted-UI sign-in step: `HostedUISignInHelper.doSignIn` over one operation's machine.
enum LiveHostedUISteps {

    /// Sends the hosted-UI sign-in and waits for its end. A cancelled wait returns the tokens already issued,
    /// for the core to revoke, as a password sign-in's does (`LiveSignInSteps.awaitStep`).
    static func signIn(
        _ options: HostedUIOptions,
        on operation: EngineOperation,
        resources: EngineResources
    ) async throws -> SignInStepOutcome {
        try await operation.configure(resources.authConfiguration)
        await operation.send(AuthenticationEvent(eventType: .signInRequested(SignInEventData(
            username: nil,
            password: nil,
            signInMethod: .hostedUI(options)
        ))))
        do {
            return try await operation.firstState { state in
                try progress(of: state, operation: operation)
            }
        } catch is CancellationError {
            if let issued = await LiveSignInSteps.issuedPayload(on: operation) {
                return .done(issued)
            }
            await LiveSignInSteps.cancelIfSigningIn(operation)
            throw CancellationError()
        } catch let failure as SignInStepFailure {
            await LiveSignInSteps.cancelIfSigningIn(operation)
            throw failure
        }
    }

    /// One state of the hosted-UI sign-in. A hosted-UI failure is mapped here, so an identity mismatch keeps
    /// its reason; everything else is the password sign-in's reading (`LiveSignInSteps.progress`), which also
    /// hands back tokens issued before an identity pool failure. A hosted-UI sign-in never stops on a
    /// challenge.
    static func progress(of state: AuthState, operation: EngineOperation) throws -> SignInStepOutcome? {
        if case .configured(.signingIn(.signingInWithHostedUI(.error(let error))), _, _) = state {
            throw LiveSignInSteps.dropping(AuthClientError(hostedUISignIn: error))
        }
        return try LiveSignInSteps.progress(of: state, operation: operation, confirming: false)
    }
}

extension AuthClientError {

    /// A hosted-UI sign-in failure. The identity checks' refusal becomes `.unexpectedIdentity` for a user who is
    /// not the one asked for, and `.service` naming the failed check for a response that is not attributable to
    /// this flow. Everything else maps as any engine error does.
    init(hostedUISignIn error: SignInError) {
        guard case .hostedUI(.unexpectedIdentity(let mismatch)) = error else {
            self.init(engine: error.engineError)
            return
        }
        self.init(hostedUIMismatch: mismatch)
    }

    /// The mismatch is the underlying error, so a caller can still read its reason. No string holds the
    /// returned identity: that is in `returned`.
    init(hostedUIMismatch mismatch: HostedUIIdentityMismatch) {
        let suggestion = HostedUIIdentityMismatch.recoverySuggestion
        guard mismatch.isIdentityMismatch else {
            self = .service(
                nil,
                "The hosted UI sign-in response could not be verified (\(Self.failedCheck(mismatch.reason))), so nobody was signed in.",
                suggestion,
                mismatch
            )
            return
        }
        // An identity reason always has the `sub`; the username falls back to it.
        let userId = mismatch.returnedUserId ?? ""
        self = .unexpectedIdentity(
            expected: mismatch.reason == .notExpectedIdentity ? mismatch.expected : nil,
            returned: AuthClientUser(username: mismatch.returnedUsername ?? userId, userId: userId),
            mismatch.errorDescription,
            suggestion,
            mismatch
        )
    }

    private static func failedCheck(_ reason: HostedUIIdentityMismatch.Reason) -> String {
        switch reason {
        case .tokenUse:
            return "its ID token is not an ID token"
        case .audience:
            return "its ID token was issued to another app client"
        case .issuer:
            return "its ID token was issued by another user pool"
        case .nonce:
            return "its ID token does not carry this sign-in's nonce"
        case .subject:
            return "its ID token and access token name different users"
        case .missingIdentity:
            return "its ID token names no user"
        case .notExpectedIdentity, .signedInToAnotherSession:
            return "the returned user was refused"
        }
    }
}

extension HostedUIOptions {

    /// The engine's options for one flow: the request's fields, the configuration's scopes when it asked for
    /// none, and the window the browser attaches to.
    init(_ options: EngineWebUIOptions, anchor: EnginePresentationAnchor?, configuredScopes: [String]) {
        self.init(
            scopes: options.scopes ?? configuredScopes,
            providerInfo: HostedUIProviderInfo(
                authProvider: options.provider.map(EngineAuthProvider.init),
                idpIdentifier: options.idpIdentifier
            ),
            presentationAnchor: anchor,
            preferPrivateSession: options.prefersEphemeralSession,
            nonce: options.nonce,
            language: options.language,
            loginHint: options.loginHint,
            prompt: options.prompt,
            resource: options.resource
        )
    }
}

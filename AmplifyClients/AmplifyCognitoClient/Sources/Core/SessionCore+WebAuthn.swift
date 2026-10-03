//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

/// WebAuthn in the core: the passkey sheet's lease, and associate.
///
/// **One lease per process.** Every passkey ceremony runs under the process-wide system-sheet lock
/// (`sheetLock`, which the hosted UI's browser shares), leased for this session with the `.fail` policy, from just
/// before the sheet is presented until the delegate answers. A second ceremony, from any session, while one is up
/// is refused with `.browserBusy(holder:)`. The lease's body returns the ceremony's payload and commits nothing
/// (`withLease`'s contract): the tokens come later, from Cognito, and a sign-in commits them after its step
/// returns, under the record gate, as any sign-in does.
///
/// **Lock order**: `signInLock` (this session) → the sheet lease (process). A sign-in step holds its
/// session's `signInLock` across its ceremony; associate never takes `signInLock`. Nothing holding the lease
/// waits for a `signInLock`, and sign-out, purge and deletion never wait for `signInLock`: they cancel through
/// `cancelPendingSignIns()`, which reaches a sign-in's ceremony through the engine (`EngineCeremonyContext.cancel`)
/// and a passkey registration through its registration.
///
/// **Who stopped a ceremony** decides what the call reports (the same rule as the hosted UI's sign-in):
///
/// | Stopped by | Sign-in | Associate |
/// |---|---|---|
/// | the user closing the sheet (the delegate's `.canceled`) | `.userCancelled` | `.userCancelled` |
/// | the caller cancelling its own task | `CancellationError` | `CancellationError` |
/// | a sign-out, purge or deletion of this session | the sign-in-cancelled `invalidState` | `passkeyRegistrationEnded()`, an `invalidState` |
/// | `cancelWebUISignIn()` or `resetSystemSheet()` | `.userCancelled` | `.userCancelled` |
extension SessionCore {

    /// Runs `body` with a fresh ceremony context for this call, on the platforms with a passkey sheet (else
    /// `nil`), and reports a stopped ceremony by who stopped it (the table above).
    ///
    /// - Parameters:
    ///   - anchor: the window, or `nil` for none (a confirmation without one uses its sign-in's).
    ///   - endsWithTheSession: whether a sign-out, purge or deletion of this session stops the call from here.
    ///     `true` for associate. A sign-in step is stopped through the engine instead, and the core reports it.
    nonisolated func withSheetCeremony<T: Sendable>(
        anchor: EnginePresentationAnchorBox?,
        endsWithTheSession: Bool = false,
        _ body: @Sendable (EngineCeremonyContext?) async throws -> T
    ) async throws -> T {
        #if os(iOS) || os(macOS) || os(visionOS)
        let flow = SystemSheetFlow()
        let context = flow.ceremonyContext(anchor: anchor, sheetLock: sheetLock, session: sessionId)
        let registration = endsWithTheSession ? await registerPasskeyRegistration { flow.cancel(.sessionEnded) } : nil
        defer {
            if let registration {
                // Fire-and-forget: `defer` cannot await. Keyed by the registration, so it never removes another.
                Task { await self.unregisterPasskeyRegistration(registration) }
            }
        }
        do {
            // Handler order: for associate the ceremony's own `run` also watches this task, and either
            // handler may fire first. Both only cancel, the flow's `cancel` is idempotent, and `run` records a
            // lock interrupt only while the calling task is not cancelled, so the order changes nothing.
            return try await withTaskCancellationHandler {
                try await body(context)
            } onCancel: {
                flow.cancel(.caller)
            }
        } catch {
            throw Self.ceremonyFailure(error, flow: flow, endsWithTheSession: endsWithTheSession)
        }
        #else
        return try await body(nil)
        #endif
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// What a call whose ceremony `flow` ran throws for `error`.
    private static func ceremonyFailure(_ error: Error, flow: SystemSheetFlow, endsWithTheSession: Bool) -> Error {
        // The first stop names the outcome: a caller who cancelled before the session ended gets
        // `CancellationError`, and a session that ended first reports that, whatever came after.
        switch flow.stoppedBy {
        case .caller? where flow.stopReachedWork:
            return CancellationError()
        case .sessionEnded? where endsWithTheSession:
            return passkeyRegistrationEnded()
        default:
            break
        }
        if flow.wasInterruptedByTheLock, !Task.isCancelled, error is CancellationError {
            return passkeySheetClosed()
        }
        return error
    }
    #endif

    /// Registers a passkey for this session's signed-in user: the signed-in route, the
    /// payload's access token, `StartWebAuthnRegistration`, the ceremony under the sheet lease, then
    /// `CompleteWebAuthnRegistration`. Takes no `signInLock` and writes nothing. A sign-out, purge or deletion
    /// of this session stops it, and closes its sheet.
    ///
    /// - Throws: as `signedInOperation`; `.browserBusy(holder:)` while another sheet is up;
    ///   `.validation(field: "presentationAnchor")` if the window has gone before the ceremony starts;
    ///   `.userCancelled` when the user closes the sheet, or `cancelWebUISignIn()`/`resetSystemSheet()` closes it;
    ///   `.webAuthnCeremonyFailed` for another ceremony failure; `passkeyRegistrationEnded()` when the session is
    ///   signed out, purged or deleted meanwhile; `CancellationError` if the calling task is cancelled.
    nonisolated func associateWebAuthnCredential(anchor: EnginePresentationAnchorBox) async throws {
        try await withSheetCeremony(anchor: anchor, endsWithTheSession: true) { [self] context in
            guard let context else {
                throw Self.webAuthnUnavailable()
            }
            try await signedInOperation("associate a WebAuthn credential") { engine, payload in
                try await engine.associateWebAuthnCredential(payload, context: context)
            }
        }
    }

    /// A WebAuthn step with no window to show the passkey sheet over: a sign-in asking for a WebAuthn first
    /// factor, or a `"WEB_AUTHN"` selection, with no `presentationAnchor` anywhere. Refused before anything is
    /// sent. The engine's description for the same refusal (a WebAuthn step Cognito started), with a recovery
    /// that names the overloads.
    static func presentationAnchorRequired() -> AuthClientError {
        .validation(
            field: WebAuthnCredentialOperations.presentationAnchorField,
            WebAuthnCredentialOperations.presentationAnchorMissingDescription,
            """
            Pass the window the passkey sheet attaches to: signIn(username:password:presentationAnchor:options:), \
            or confirmSignIn(challengeResponse:presentationAnchor:options:) for a WEB_AUTHN selection.
            """
        )
    }

    /// A passkey registration a sign-out, purge or deletion of this session ended, as the hosted UI reports a
    /// sign-in the session ended (`signInCancelled()`). A sign-out that shows the hosted UI's logout page stops
    /// the registration only once it holds the sheet, or to free the sheet the registration holds: taking the
    /// sheet is its busy check, so another session's sheet refuses it with nothing stopped. It may
    /// still leave the session signed in: the user may close the page, or the registration's own sheet may not
    /// close within `passkeySheetClosingTimeout` (the busy refusal). Worded for both outcomes.
    static func passkeyRegistrationEnded() -> AuthClientError {
        .invalidState(
            "The passkey registration was cancelled by a sign-out, purge or deletion of this session.",
            "If the session is still signed in, register the passkey again; otherwise sign in first."
        )
    }

    /// A passkey sheet `cancelWebUISignIn()` or `resetSystemSheet()` closed: the app's own close, reported as the
    /// user's, as the hosted UI's browser is.
    static func passkeySheetClosed() -> AuthClientError {
        .userCancelled(
            "The passkey sheet was closed before the ceremony finished.",
            "Try again when the user is ready."
        )
    }

    /// WebAuthn on a platform without the passkey sheet (tvOS, watchOS).
    static func webAuthnUnavailable() -> AuthClientError {
        .configuration(
            "WebAuthn is not available on this platform.",
            "Use WebAuthn on iOS 17.4, macOS 13.5 or visionOS 1.0 and later."
        )
    }
}

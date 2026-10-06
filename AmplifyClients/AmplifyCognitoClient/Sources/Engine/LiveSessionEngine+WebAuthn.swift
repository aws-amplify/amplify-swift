//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// WebAuthn credentials: associate, list and delete are the
/// engine's `WebAuthnCredentialOperations`, the same code the plugin's tasks call.
///
/// All three send the payload's access token **as it is**: the core's signed-in route has already refreshed
/// the payload if it needed it, and the engine never refreshes. None writes anything. Only associate
/// presents a sheet, and it runs its ceremony through the context's runner (the sheet lease).
extension LiveSessionEngine {

    /// `StartWebAuthnRegistration`, the registration ceremony through `context.ceremony` (the sheet lease),
    /// then `CompleteWebAuthnRegistration`, with the payload's access token both times
    /// (`AssociateWebAuthnCredentialTask`). The registrant is made on the main actor from the unboxed window
    /// when the ceremony starts, so a window that has gone is `.validation(field: "presentationAnchor")` and
    /// nothing is presented.
    ///
    /// **One access token for both calls.** The plugin asks for the
    /// token again before `CompleteWebAuthnRegistration`, which may refresh it; the seam forbids the engine a
    /// refresh (only the core's flight refreshes), so the payload's token is sent to both. A token that expires
    /// during the sheet makes `Complete` fail with `.notAuthorized`, and a retry, which refreshes first, works.
    ///
    /// - Throws: `notSignedIn` for a payload with no user pool tokens; the runner's own errors unchanged
    ///   (`.browserBusy(holder:)`); `CancellationError` if the calling task was cancelled; otherwise Cognito's
    ///   answer or the ceremony's failure as `AuthClientError(engine:)` maps it (`mappingSignedInFailures`).
    nonisolated func associateWebAuthnCredential(_ payload: Data, context: EngineCeremonyContext) async throws {
        #if os(iOS) || os(macOS) || os(visionOS)
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw SessionCore.webAuthnUnavailable()
        }
        let accessToken = try webAuthnAccessToken(in: payload, for: "associateWebAuthnCredential")
        let userPool = webAuthnUserPool
        let registrant = webAuthnCeremonies.registrant(logger: resources.logger)
        try await Self.mappingSignedInFailures {
            try await WebAuthnCredentialOperations.associate(
                accessToken: { accessToken },
                userPool: userPool,
                anchor: context.anchor,
                ceremony: context.ceremony,
                registrant: registrant
            )
        }
        #else
        throw SessionCore.webAuthnUnavailable()
        #endif
    }

    /// `ListWebAuthnCredentials` with the payload's access token (`ListWebAuthnCredentialsTask`). The engine
    /// drops entries missing `createdAt`, `credentialId` or `relyingPartyId`, and makes an empty friendly
    /// name `nil`.
    ///
    /// - Parameter pageSize: `MaxResults`; the facade has checked it is 1…20.
    /// - Throws: `notSignedIn` for a payload with no user pool tokens; `CancellationError` if the call was
    ///   cancelled; otherwise Cognito's answer as `AuthClientError(engine:)` maps it (`mappingSignedInFailures`).
    nonisolated func listWebAuthnCredentials(_ payload: Data, pageSize: Int, nextToken: String?) async throws -> EngineWebAuthnCredentialPage {
        guard let maxResults = UInt(exactly: pageSize) else {
            throw AuthClientError.webAuthnPageSizeOutOfRange
        }
        let accessToken = try webAuthnAccessToken(in: payload, for: "listWebAuthnCredentials")
        let userPool = webAuthnUserPool
        return try await Self.mappingSignedInFailures {
            try await WebAuthnCredentialOperations.list(
                accessToken: { accessToken },
                pageSize: maxResults,
                nextToken: nextToken,
                userPool: userPool
            )
        }
    }

    /// `DeleteWebAuthnCredential` with the payload's access token (`DeleteWebAuthnCredentialTask`).
    ///
    /// - Throws: as `listWebAuthnCredentials`.
    nonisolated func deleteWebAuthnCredential(_ payload: Data, credentialId: String) async throws {
        let accessToken = try webAuthnAccessToken(in: payload, for: "deleteWebAuthnCredential")
        let userPool = webAuthnUserPool
        try await Self.mappingSignedInFailures {
            try await WebAuthnCredentialOperations.delete(
                accessToken: { accessToken },
                credentialId: credentialId,
                userPool: userPool
            )
        }
    }

    // MARK: Support

    /// The payload's access token, unrefreshed.
    private nonisolated func webAuthnAccessToken(in payload: Data, for operation: String) throws -> String {
        try requireUserPool()
        guard let accessToken = try Self.credentials(in: payload).userPoolTokens?.accessToken else {
            throw AuthClientError.notSignedIn(
                "There is no user signed in to \(operation)",
                "Call signIn to sign in a user, then \(operation)."
            )
        }
        return accessToken
    }

    /// The session's user pool client, as the operations ask for it.
    private nonisolated var webAuthnUserPool: UserPoolEnvironment.CognitoUserPoolFactory {
        let services = resources.services
        return { try EngineResources.required(services.userPool, "user pool") }
    }
}

/// What presents the passkey sheet for the live engine: the platform's `PlatformWebAuthnCredentials` in the
/// app. A test replaces the factories with ones that present nothing (the ceremony's result, or its error).
struct LiveWebAuthnCeremonies: Sendable {

    #if os(iOS) || os(macOS) || os(visionOS)
    /// Makes the sign-in's asserter from the unboxed window, on the main actor; `nil` is the platform's. It
    /// must return a `CredentialAsserterProtocol`.
    var makeAsserter: (@MainActor @Sendable (EnginePresentationAnchor) -> any WebAuthnCredentialsProtocol)?
    /// Makes associate's registrant from the unboxed window, on the main actor; `nil` is the platform's. It
    /// must return a `CredentialRegistrantProtocol`.
    var makeRegistrant: (@MainActor @Sendable (EnginePresentationAnchor?) -> any WebAuthnCredentialsProtocol)?
    #endif

    static let platform = LiveWebAuthnCeremonies()

    /// The runner of a step the core gave no ceremony context: it refuses, since nothing would hold the lease.
    private static let noRunner: WebAuthnCredentialOperations.CeremonyRunner = { _ in
        throw SessionCore.presentationAnchorRequired()
    }

    /// A sign-in step's ceremony for the operation's slot (`WebAuthnSignInCeremonySlot`): over `anchor`,
    /// through the step's runner. Always set on the client's operations, so a step with no window is
    /// refused without presenting instead of taking the plugin's path, whose asserter would fall back to a
    /// window of its own.
    func signInCeremony(_ context: EngineCeremonyContext?, anchor: EnginePresentationAnchorBox?) -> WebAuthnSignInCeremonySlot.Ceremony {
        // With no context there is no runner to hold the sheet lease: only a step with no window gets here
        // from the core, which the ceremony refuses before running anything.
        let run = context?.ceremony ?? Self.noRunner
        #if os(iOS) || os(macOS) || os(visionOS)
        return WebAuthnSignInCeremonySlot.Ceremony(anchor: anchor, run: run, makeAsserter: makeAsserter)
        #else
        return WebAuthnSignInCeremonySlot.Ceremony(anchor: anchor, run: run)
        #endif
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// Associate's registrant factory, as the engine's operation takes it. The platform's logs through `logger`.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    func registrant(logger: any EngineScopedLogger) -> WebAuthnCredentialOperations.RegistrantFactory {
        guard let makeRegistrant else {
            return WebAuthnCredentialOperations.platformRegistrant(logger: logger)
        }
        return { anchor in
            guard let registrant = makeRegistrant(anchor) as? CredentialRegistrantProtocol else {
                preconditionFailure("LiveWebAuthnCeremonies.makeRegistrant must return a CredentialRegistrantProtocol")
            }
            return registrant
        }
    }
    #endif
}

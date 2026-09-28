//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

/// A WebAuthn credential registered for the signed-in user, as `ListWebAuthnCredentials` returns it.
package struct EngineWebAuthnCredential: Sendable, Equatable, Hashable {
    package let credentialId: String
    package let createdAt: Date
    package let relyingPartyId: String
    /// `nil` when Cognito returns no friendly name, or an empty one.
    package let friendlyName: String?

    package init(
        credentialId: String,
        createdAt: Date,
        relyingPartyId: String,
        friendlyName: String?
    ) {
        self.credentialId = credentialId
        self.createdAt = createdAt
        self.relyingPartyId = relyingPartyId
        self.friendlyName = friendlyName
    }
}

/// One page of `ListWebAuthnCredentials`.
package struct EngineWebAuthnCredentialPage: Sendable, Equatable {
    package let credentials: [EngineWebAuthnCredential]
    /// Where the next page starts, or `nil` after the last one.
    package let nextToken: String?

    package init(credentials: [EngineWebAuthnCredential], nextToken: String?) {
        self.credentials = credentials
        self.nextToken = nextToken
    }
}

/// The signed-in user's WebAuthn credential operations: associate, list and delete.
/// `AWSCognitoAuthPlugin`'s three WebAuthn tasks are thin callers of
/// these, and `AmplifyCognitoClient` will be too, so both share one implementation.
///
/// Each operation gets its access token and its user-pool client from the caller, through
/// `accessToken` and `userPool`, and calls them at the points the plugin's tasks did: associate asks for
/// both again after the ceremony, before `CompleteWebAuthnRegistration`.
///
/// **Errors.**
/// - An error thrown by `accessToken`, `userPool` or associate's `ceremony` runner is the caller's own,
///   and is rethrown **unchanged** (the plugin's token lookup throws Amplify's `AuthError`, which the
///   engine cannot name; the client's runner throws its lease refusal).
/// - Every other error is an `EngineAuthError`: an `EngineAuthErrorConvertible` error (a Cognito exception,
///   the ceremony's `WebAuthnError`) as its `engineError`; anything else as the `engineError` of
///   `WebAuthnError.unknown(message:error:)` with the operation's failure message.
///
/// That is the plugin's former conversion with its Amplify half left to the caller: `AuthError(converting:)`
/// of what these throw is the `AuthError` the plugin's tasks threw before.
package enum WebAuthnCredentialOperations {

    /// Returns the access token to send. Called once per Cognito request.
    package typealias AccessTokenProvider = () async throws -> String

    /// The `WebAuthnError.unknown` message for an error associate cannot convert.
    package static let associateFailureMessage = "Unable to associate WebAuthn credential"
    /// The `WebAuthnError.unknown` message for an error list cannot convert.
    package static let listFailureMessage = "Unable to list WebAuthn credentials"
    /// The `WebAuthnError.unknown` message for an error delete cannot convert.
    package static let deleteFailureMessage = "Unable to delete WebAuthn credential"

    /// Runs one ceremony: the caller's wrapper around it (the client takes the process-wide sheet lease
    /// for the session there). It must call `body` at most once and return its value. The same shape as
    /// the client seam's `EngineCeremonyContext.ceremony`.
    ///
    /// **Cancellation.** The runner must let the caller's cancellation reach the task running `body`:
    /// that is what cancels the kept `ASAuthorizationController` (`PlatformWebAuthnCredentials`). A
    /// runner may answer before `body` ends. The client's lease (`withLease`) runs `body` in its own
    /// task, and on the caller's cancellation cancels that task and answers at once with
    /// `CancellationError()`, which `associate` rethrows unchanged, as the runner's own error. The
    /// lease is released only when `body` ends (after the delegate's `.canceled`), so a retry in that
    /// window can be refused as busy.
    package typealias CeremonyRunner = @Sendable (
        _ body: @escaping @Sendable () async throws -> Data
    ) async throws -> Data

    /// A runner that holds nothing around the ceremony: the plugin's, whose task queue already runs one
    /// operation at a time.
    package static let runCeremonyDirectly: CeremonyRunner = { body in
        try await body()
    }

    /// The `.validation` field for a presentation anchor whose window has gone.
    package static let presentationAnchorField = "presentationAnchor"
    package static let presentationAnchorGoneDescription =
        "The presentation anchor's window no longer exists, so the WebAuthn sheet cannot be presented."
    package static let presentationAnchorGoneRecovery =
        "Pass a window that stays open until the WebAuthn ceremony finishes, such as the key window of the active scene."

#if os(iOS) || os(macOS) || os(visionOS)
    /// Makes the registrant for one ceremony, from the unboxed window (`nil`: no anchor was given).
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    package typealias RegistrantFactory = @MainActor @Sendable (
        _ anchor: EnginePresentationAnchor?
    ) -> CredentialRegistrantProtocol

    /// The platform registrant, `PlatformWebAuthnCredentials`.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    package static let platformRegistrant: RegistrantFactory = { anchor in
        PlatformWebAuthnCredentials(presentationAnchor: anchor)
    }

    /// `StartWebAuthnRegistration`, the registration ceremony, then `CompleteWebAuthnRegistration` with
    /// the credential it created.
    ///
    /// The ceremony runs inside `ceremony`. It first unboxes `anchor` on the main actor and makes the
    /// registrant from it there (`registrant`), then runs `create(with:)`:
    /// - a box whose window has gone throws `EngineAuthError.validation("presentationAnchor", …)`, and
    ///   no registrant is made, so nothing is presented;
    /// - no box (`nil`) makes the registrant with no window, whose own fallback applies (the plugin's
    ///   optional anchor; the client always passes a box).
    ///
    /// **Errors from the runner.** The ceremony body converts its own errors to `EngineAuthError` (as
    /// every other error here is converted) before they reach `ceremony`. So whatever `ceremony` throws is
    /// either one of those, already converted, or the runner's own error (the client's lease refusal),
    /// and both are rethrown unchanged, as the caller's errors are.
    ///
    /// - Parameters:
    ///   - anchor: the window the sheet attaches to, boxed on the main actor by the caller.
    ///   - ceremony: runs the ceremony body; `runCeremonyDirectly` holds nothing around it.
    ///   - registrant: makes the registrant on the main actor, at ceremony start.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    package static func associate(
        accessToken: AccessTokenProvider,
        userPool: UserPoolEnvironment.CognitoUserPoolFactory,
        anchor: EnginePresentationAnchorBox?,
        ceremony: CeremonyRunner,
        registrant: @escaping RegistrantFactory = platformRegistrant
    ) async throws {
        try await reexpressingErrors(failureMessage: associateFailureMessage) {
            let startToken = try await callerValue(accessToken)
            let startService = try callerValue(userPool)
            let result = try await startService.startWebAuthnRegistration(
                input: .init(accessToken: startToken)
            )

            let options = try CredentialCreationOptions(
                from: result.credentialCreationOptions?.asStringMap()
            )
            let credential = try await callerValue {
                try await ceremony {
                    try await registration(options: options, anchor: anchor, registrant: registrant)
                }
            }

            let completeToken = try await callerValue(accessToken)
            let completeService = try callerValue(userPool)
            _ = try await completeService.completeWebAuthnRegistration(
                input: .init(
                    accessToken: completeToken,
                    credential: .make(from: credential)
                )
            )
        }
    }

    /// The ceremony body: the registrant from the unboxed anchor, then the registration, as the
    /// credential's data. Every error is an `EngineAuthError` when it leaves.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    private static func registration(
        options: CredentialCreationOptions,
        anchor: EnginePresentationAnchorBox?,
        registrant makeRegistrant: RegistrantFactory
    ) async throws -> Data {
        do {
            let registrant = try await MainActor.run {
                try Self.registrant(from: anchor, makeRegistrant)
            }
            return try await registrant.create(with: options).asData()
        } catch {
            throw engineError(for: error, failureMessage: associateFailureMessage)
        }
    }

    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    @MainActor
    private static func registrant(
        from box: EnginePresentationAnchorBox?,
        _ makeRegistrant: RegistrantFactory
    ) throws -> CredentialRegistrantProtocol {
        guard let box else {
            return makeRegistrant(nil)
        }
        guard let window = box.anchor else {
            throw EngineAuthError.validation(
                presentationAnchorField,
                presentationAnchorGoneDescription,
                presentationAnchorGoneRecovery
            )
        }
        return makeRegistrant(window)
    }
#endif

    /// `ListWebAuthnCredentials`. Entries missing `createdAt`, `credentialId` or `relyingPartyId` are
    /// dropped, and an empty friendly name becomes `nil`. `pageSize` is sent as it is, unchecked.
    package static func list(
        accessToken: AccessTokenProvider,
        pageSize: UInt,
        nextToken: String?,
        userPool: UserPoolEnvironment.CognitoUserPoolFactory
    ) async throws -> EngineWebAuthnCredentialPage {
        try await reexpressingErrors(failureMessage: listFailureMessage) {
            let token = try await callerValue(accessToken)
            let service = try callerValue(userPool)
            let result = try await service.listWebAuthnCredentials(
                input: .init(
                    accessToken: token,
                    maxResults: Int(pageSize),
                    nextToken: nextToken
                )
            )

            let credentialDescriptions = result.credentials ?? []
            let credentials: [EngineWebAuthnCredential] = credentialDescriptions.compactMap { credential in
                // All of these are marked as required but the Swift SDK doesn't respect that and maps them to Optionals
                guard let createdAt = credential.createdAt,
                      let credentialId = credential.credentialId,
                      let relyingPartyId = credential.relyingPartyId else {
                    return nil
                }

                return EngineWebAuthnCredential(
                    credentialId: credentialId,
                    createdAt: createdAt,
                    relyingPartyId: relyingPartyId,
                    friendlyName: friendlyName(from: credential)
                )
            }

            return EngineWebAuthnCredentialPage(
                credentials: credentials,
                nextToken: result.nextToken
            )
        }
    }

    /// `DeleteWebAuthnCredential`.
    package static func delete(
        accessToken: AccessTokenProvider,
        credentialId: String,
        userPool: UserPoolEnvironment.CognitoUserPoolFactory
    ) async throws {
        try await reexpressingErrors(failureMessage: deleteFailureMessage) {
            let token = try await callerValue(accessToken)
            let service = try callerValue(userPool)
            _ = try await service.deleteWebAuthnCredential(
                input: .init(
                    accessToken: token,
                    credentialId: credentialId
                )
            )
        }
    }

    /// The engine error for an error an operation cannot pass through: its own `engineError` when it has
    /// one, else `WebAuthnError.unknown(message: failureMessage, error:)`'s.
    package static func engineError(for error: Error, failureMessage: String) -> EngineAuthError {
        if let convertible = error as? EngineAuthErrorConvertible {
            return convertible.engineError
        }
        return WebAuthnError.unknown(message: failureMessage, error: error).engineError
    }

    // MARK: - Private

    private static func friendlyName(
        from credential: CognitoIdentityProviderClientTypes.WebAuthnCredentialDescription
    ) -> String? {
        guard let friendlyName = credential.friendlyCredentialName, !friendlyName.isEmpty else {
            return nil
        }

        return friendlyName
    }

    /// Marks an error thrown by one of the caller's closures, so `reexpressingErrors` rethrows it as it is.
    private struct CallerError: Error {
        let error: Error
    }

    private static func callerValue<Value>(_ body: () async throws -> Value) async throws -> Value {
        do {
            return try await body()
        } catch {
            throw CallerError(error: error)
        }
    }

    private static func callerValue<Value>(_ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch {
            throw CallerError(error: error)
        }
    }

    private static func reexpressingErrors<Value>(
        failureMessage: String,
        _ body: () async throws -> Value
    ) async throws -> Value {
        do {
            return try await body()
        } catch let callerError as CallerError {
            throw callerError.error
        } catch {
            throw engineError(for: error, failureMessage: failureMessage)
        }
    }
}

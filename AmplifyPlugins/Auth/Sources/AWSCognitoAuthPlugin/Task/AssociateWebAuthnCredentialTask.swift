//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth
#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import AuthenticationServices
import AWSCognitoIdentityProvider
import Foundation

/// - Note: `final` and `@unchecked Sendable`: the task is constructed, run once, and discarded.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class AssociateWebAuthnCredentialTask: NSObject, AuthAssociateWebAuthnCredentialTask, DefaultLogger, @unchecked Sendable {
    private let request: AuthAssociateWebAuthnCredentialRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: UserPoolEnvironment.CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper
    private let credentialRegistrant: CredentialRegistrantProtocol

    let eventName: HubPayloadEventName = HubPayload.EventName.Auth.associateWebAuthnCredentialAPI

    init(
        request: AuthAssociateWebAuthnCredentialRequest,
        authStateMachine: AuthStateMachine,
        userPoolFactory: @escaping UserPoolEnvironment.CognitoUserPoolFactory,
        registrantFactory: (AuthUIPresentationAnchor?) -> CredentialRegistrantProtocol = { anchor in
            PlatformWebAuthnCredentials(presentationAnchor: anchor)
        }
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.credentialRegistrant = registrantFactory(request.presentationAnchor)
    }

    /// The engine's `WebAuthnCredentialOperations.associate` does the work. It rethrows the token lookup's
    /// `AuthError` unchanged and re-expresses every other error as an `EngineAuthError`, which
    /// `AuthError(converting:)` bridges back to the `AuthError` this task has always thrown.
    ///
    /// The anchor is strong here (`request` holds it for the whole task), so its weak box never empties,
    /// and the registrant stays the one made at init from that same anchor. The plugin takes no lease:
    /// its task queue already runs one operation at a time.
    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            let registrant = credentialRegistrant
            try await WebAuthnCredentialOperations.associate(
                accessToken: { try await self.taskHelper.getAccessToken() },
                userPool: userPoolFactory,
                anchor: await boxedPresentationAnchor(),
                ceremony: WebAuthnCredentialOperations.runCeremonyDirectly,
                registrant: { _ in registrant }
            )
        } catch {
            if let authError = AuthError(converting: error) {
                throw authError
            }
            let webAuthnError = WebAuthnError.unknown(
                message: WebAuthnCredentialOperations.associateFailureMessage,
                error: error
            )
            throw webAuthnError.authError
        }
    }

    /// `request`'s anchor in the engine's box, made on the main actor; `nil` when none was given.
    private func boxedPresentationAnchor() async -> EnginePresentationAnchorBox? {
        guard request.presentationAnchor != nil else {
            return nil
        }
        return await MainActor.run {
            self.request.presentationAnchor.map { EnginePresentationAnchorBox($0) }
        }
    }
}
#endif

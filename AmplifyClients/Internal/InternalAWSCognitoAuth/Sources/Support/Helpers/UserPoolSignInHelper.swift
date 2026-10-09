//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

/// The engine half of the sign-in helper: it turns a Cognito response into the next state-machine event.
/// The glue half, which builds `AuthSignInResult` from the state, is `UserPoolSignInHelper+AuthSignInResult.swift`.
package enum UserPoolSignInHelper {

    package static func sendRespondToAuth(
        request: RespondToAuthChallengeInput,
        for username: String,
        signInMethod: SignInMethod,
        inputUsername: String? = nil,
        environment: UserPoolEnvironment,
        logger: any EngineScopedLogger
    ) async throws -> StateMachineEvent {

            let client = try environment.cognitoUserPoolFactory()
            let response = try await client.respondToAuthChallenge(input: request)
            let event = parseResponse(
                response,
                for: username,
                signInMethod: signInMethod,
                inputUsername: inputUsername,
                logger: logger
            )
            return event
        }

    /// - Parameter logger: the caller's, which an unsupported MFA type in the response is logged through.
    package static func parseResponse(
        _ response: SignInResponseBehavior,
        for username: String,
        signInMethod: SignInMethod,
        presentationAnchor: EnginePresentationAnchor? = nil,
        srpStateData: SRPStateData? = nil,
        inputUsername: String? = nil,
        logger: any EngineScopedLogger
    ) -> StateMachineEvent {

            if let authenticationResult = response.authenticationResult,
               let idToken = authenticationResult.idToken,
               let accessToken = authenticationResult.accessToken,
               let refreshToken = authenticationResult.refreshToken {
                let userPoolTokens = EngineUserPoolTokens(
                    idToken: idToken,
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: authenticationResult.expiresIn
                )
                let signedInData = SignedInData(
                    signedInDate: Date(),
                    signInMethod: signInMethod,
                    deviceMetadata: authenticationResult.deviceMetadata,
                    cognitoUserPoolTokens: userPoolTokens,
                    inputUsername: inputUsername ?? username
                )

                switch signedInData.deviceMetadata {
                case .noData:
                    return SignInEvent(eventType: .finalizeSignIn(signedInData))
                case .metadata:
                    return SignInEvent(eventType: .confirmDevice(signedInData))
                }

            } else if let challengeName = response.challengeName {
                let parameters = response.challengeParameters
                let respondToAuthChallenge = RespondToAuthChallenge(
                    challenge: challengeName,
                    availableChallenges: response.availableChallenges ?? [],
                    username: username,
                    session: response.session,
                    parameters: parameters,
                    inputUsername: inputUsername ?? username
                )

                switch challengeName {
                case .smsMfa, .customChallenge, .newPasswordRequired, .softwareTokenMfa, .selectMfaType, .smsOtp, .emailOtp, .selectChallenge:
                    return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
                case .passwordVerifier:
                    guard let srpStateData else {
                        let message = "Unable to extract SRP state data to continue with password verification."
                        let error = SignInError.invalidServiceResponse(message: message)
                        return SignInEvent(eventType: .throwAuthError(error))
                    }
                    return SignInEvent(
                        eventType: .respondPasswordVerifier(srpStateData, response, [:])
                    )
                case .deviceSrpAuth:
                    // Carry the caller's `inputUsername` into the device SRP flow. It has to look
                    // the stored device metadata back up, and that's keyed on the username the
                    // caller signed in with (see `ConfirmDevice`). `username` here is the value
                    // Cognito echoed — the sub, on pools with alias sign-in — so using it makes the
                    // lookup miss and the request omits DEVICE_KEY, which Cognito rejects with
                    // "Missing required parameter DEVICE_KEY".
                    return SignInEvent(eventType: .initiateDeviceSRP(inputUsername ?? username, response))
                case .webAuthn:
                    let signInData = WebAuthnSignInData(
                        username: username,
                        presentationAnchor: presentationAnchor
                    )
                    return SignInEvent(eventType: .initiateWebAuthnSignIn(signInData, respondToAuthChallenge))
                case .mfaSetup:
                    let allowedMFATypesForSetup = respondToAuthChallenge.getAllowedMFATypesForSetup(logger: logger)
                    if allowedMFATypesForSetup.contains(.totp) && allowedMFATypesForSetup.contains(.email) {
                        return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
                    } else if allowedMFATypesForSetup.contains(.totp) {
                        return SignInEvent(eventType: .initiateTOTPSetup(username, respondToAuthChallenge))
                    } else if allowedMFATypesForSetup.contains(.email) {
                        return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
                    } else {
                        let message = "Cannot initiate MFA setup from available Types: \(EngineMFAType.legacyDescription(of: allowedMFATypesForSetup))"
                        let error = SignInError.invalidServiceResponse(message: message)
                        return SignInEvent(eventType: .throwAuthError(error))
                    }
                default:
                    let message = "Unsupported challenge response \(challengeName)"
                    let error = SignInError.unknown(message: message)
                    return SignInEvent(eventType: .throwAuthError(error))
                }
            } else {
                let message = "Response did not contain signIn info"
                let error = SignInError.invalidServiceResponse(message: message)
                return SignInEvent(eventType: .throwAuthError(error))
            }
        }
}

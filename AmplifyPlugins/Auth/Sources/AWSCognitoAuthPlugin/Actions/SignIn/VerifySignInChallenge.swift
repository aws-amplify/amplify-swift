//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifySignInChallenge: Action {

    var identifier: String = "VerifySignInChallenge"

    let challenge: RespondToAuthChallenge

    let confirmSignEventData: ConfirmSignInEventData

    let signInMethod: SignInMethod

    let currentSignInStep: AuthSignInStep

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let username = challenge.username
        var deviceMetadata = DeviceMetadata.noData

        do {
            if case .continueSignInWithMFASetupSelection = currentSignInStep {
                try await handleContinueSignInWithMFASetupSelection(
                    withDispatcher: dispatcher,
                    environment: environment,
                    username: username)
                return
            } else if case .continueSignInWithFirstFactorSelection = currentSignInStep,
                      let authFactorType = AuthFactorType(rawValue: confirmSignEventData.answer) {
                if (authFactorType == .password || authFactorType == .passwordSRP) {
                    try await handleContinueSignInWithPassword(
                        withDispatcher: dispatcher,
                        environment: environment,
                        username: username,
                        authFactorType: authFactorType)
                    return
                } else if isWebAuthn(authFactorType) {
                    let signInData = WebAuthnSignInData(
                        username: username,
                        presentationAnchor: confirmSignEventData.presentationAnchor
                    )
                    let event = SignInEvent(eventType: .initiateWebAuthnSignIn(signInData, challenge))
                    logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                    await dispatcher.send(event)
                    return
                }
            } else if case .confirmSignInWithPassword = currentSignInStep {
                try await handleConfirmSignInWithPassword(
                    withDispatcher: dispatcher,
                    environment: environment,
                    username: username)
                return
            }


            let userpoolEnv = try environment.userPoolEnvironment()
            let username = challenge.username
            let session = challenge.session
            let challengeType = challenge.challenge
            let responseKey = try challenge.getChallengeKey()

            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: environment.authEnvironment().credentialsClient)

            deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                            for: username,
                            with: environment)

            let input = await RespondToAuthChallengeInput.verifyChallenge(
                username: username,
                challengeType: challengeType,
                session: session,
                responseKey: responseKey,
                answer: confirmSignEventData.answer,
                clientMetadata: confirmSignEventData.metadata,
                asfDeviceId: asfDeviceId,
                attributes: confirmSignEventData.attributes,
                deviceMetadata: deviceMetadata,
                environment: userpoolEnv)

            let responseEvent = try await UserPoolSignInHelper.sendRespondToAuth(
                request: input,
                for: username,
                signInMethod: signInMethod,
                environment: userpoolEnv)
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)
        } catch let error where deviceNotFound(error: error, deviceMetadata: deviceMetadata) {
            logVerbose("\(#fileID) Received device not found \(error)", environment: environment)
            // Remove the saved device details and retry verify challenge
            await DeviceMetadataHelper.removeDeviceMetaData(for: username, with: environment)
            let event = SignInChallengeEvent(
                eventType: .retryVerifyChallengeAnswer(confirmSignEventData, currentSignInStep)
            )
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
        } catch let error as SignInError {
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.service(error: error)
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        }
    }

    func handleConfirmSignInWithPassword(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment,
        username: String
    ) async throws {

        let newDeviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
            for: username,
            with: environment)
        if challenge.challenge == .password {

            let event = SignInEvent(
                eventType: .initiateMigrateAuth(
                    .init(username: username,
                          password: confirmSignEventData.answer,
                          signInMethod: signInMethod),
                    newDeviceMetadata,
                    challenge))

            await dispatcher.send(event)
        } else if challenge.challenge == .passwordSrp {
            let event = SignInEvent(
                eventType: .initiateSignInWithSRP(
                    .init(username: username,
                          password: confirmSignEventData.answer,
                          signInMethod: signInMethod),
                    newDeviceMetadata,
                    challenge))
            await dispatcher.send(event)
        } else {
            throw SignInError.unknown(
                message: "confirmSignInWithPassword received an unknown challenge type. Received: \(challenge.challenge)")
        }
    }

    func handleContinueSignInWithPassword(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment,
        username: String,
        authFactorType: AuthFactorType
    ) async throws {

        let authFactorType = AuthFactorType(rawValue: confirmSignEventData.answer)
        var challengeType: CognitoIdentityProviderClientTypes.ChallengeNameType? = nil

        if case .password = authFactorType {
            challengeType = .password
        } else if case .passwordSRP = authFactorType {
            challengeType = .passwordSrp
        } else if isWebAuthn(authFactorType) {
            throw SignInError.unknown(
                message: "This code path only supports password and password SRP. Received: \(challenge.challenge)")
        }

        guard let challengeType = challengeType else {
            throw SignInError.unknown(
                message: "Unable to determine challenge type from \(String(describing: authFactorType))")
        }

        let newChallenge = RespondToAuthChallenge(
            challenge: challengeType,
            availableChallenges: [],
            username: challenge.username,
            session: challenge.session,
            parameters: [:])

        let event = SignInEvent(eventType: .receivedChallenge(newChallenge))
        logVerbose("\(#fileID) Sending event \(event)", environment: environment)
        await dispatcher.send(event)
    }

    func handleContinueSignInWithMFASetupSelection(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment,
        username: String
    ) async throws {
        let newChallenge = RespondToAuthChallenge(
            challenge: .mfaSetup,
            availableChallenges: [],
            username: challenge.username,
            session: challenge.session,
            parameters: ["MFAS_CAN_SETUP": "[\"\(confirmSignEventData.answer)\"]"])

        let event: SignInEvent
        guard let mfaType = MFAType(rawValue: confirmSignEventData.answer) else {
            throw SignInError.inputValidation(field: "Unknown MFA type")
        }

        switch mfaType {
        case .email:
            event = SignInEvent(eventType: .receivedChallenge(newChallenge))
        case .totp:
            event = SignInEvent(eventType: .initiateTOTPSetup(username, newChallenge))
        default:
            throw SignInError.unknown(message: "MFA Type not supported for setup")
        }

        logVerbose("\(#fileID) Sending event \(event)", environment: environment)
        await dispatcher.send(event)
    }

    func deviceNotFound(error: Error, deviceMetadata: DeviceMetadata) -> Bool {

        // If deviceMetadata was not send, the error returned is not from device not found.
        if case .noData = deviceMetadata {
            return false
        }

        return error is AWSCognitoIdentityProvider.ResourceNotFoundException
    }

    private func isWebAuthn(_ factorType: AuthFactorType?) -> Bool {
    #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, *) {
            return .webAuthn == factorType
        }
    #endif
        return false
    }
}

extension VerifySignInChallenge: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "challenge": challenge.debugDictionary
        ]
    }
}

extension VerifySignInChallenge: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

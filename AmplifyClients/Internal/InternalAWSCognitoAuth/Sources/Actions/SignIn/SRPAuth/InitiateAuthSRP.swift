//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import CryptoKit
import Foundation

package struct InitiateAuthSRP: Action {
    package let identifier = "InitiateAuthSRP"

    package let username: String
    package let password: String
    package let authFlowType: EngineAuthFlowType
    package let deviceMetadata: DeviceMetadata
    package let clientMetadata: [String: String]
    package let respondToAuthChallenge: RespondToAuthChallenge?

    package init(
        username: String,
        password: String,
        authFlowType: EngineAuthFlowType = .userSRP,
        deviceMetadata: DeviceMetadata = .noData,
        clientMetadata: [String: String] = [:],
        respondToAuthChallenge: RespondToAuthChallenge?
    ) {
        self.username = username
        self.password = password
        self.authFlowType = authFlowType
        self.deviceMetadata = deviceMetadata
        self.clientMetadata = clientMetadata
        self.respondToAuthChallenge = respondToAuthChallenge
    }

    package func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let authEnv = try environment.authEnvironment()
            let srpEnv = try environment.srpEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let nHexValue = srpEnv.srpConfiguration.nHexValue
            let gHexValue = srpEnv.srpConfiguration.gHexValue

            let srpClient = try SRPSignInHelper.srpClient(srpEnv)
            let srpKeyPair = srpClient.generateClientKeyPair()

            let srpStateData = SRPStateData(
                username: username,
                password: password,
                NHexValue: nHexValue,
                gHexValue: gHexValue,
                srpKeyPair: srpKeyPair,
                clientTimestamp: Date()
            )

            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient
            )

            let responseEvent: SignInEvent
            if case .userAuth = authFlowType,
               let session = respondToAuthChallenge?.session {
                let request = await RespondToAuthChallengeInput.srpInputForUserAuth(
                    username: username,
                    publicSRPAHexValue: srpKeyPair.publicKeyHexValue,
                    session: session,
                    clientMetadata: clientMetadata,
                    asfDeviceId: asfDeviceId,
                    deviceMetadata: deviceMetadata,
                    environment: userPoolEnv
                )

                responseEvent = try await sendRequest(
                    request: request,
                    environment: userPoolEnv,
                    srpStateData: srpStateData
                )
            } else {
                let request = await InitiateAuthInput.srpInput(
                    username: username,
                    publicSRPAHexValue: srpKeyPair.publicKeyHexValue,
                    authFlowType: authFlowType,
                    clientMetadata: clientMetadata,
                    asfDeviceId: asfDeviceId,
                    deviceMetadata: deviceMetadata,
                    environment: userPoolEnv
                )

                responseEvent = try await sendRequest(
                    request: request,
                    environment: userPoolEnv,
                    srpStateData: srpStateData
                )
            }


            logVerbose("\(#fileID) Sending event \(responseEvent)", environment: srpEnv)
            await dispatcher.send(responseEvent)

        } catch let error as SignInError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = SignInEvent(eventType: .throwAuthError(error))
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            await dispatcher.send(event)
        }

    }

    private func sendRequest(
        request: RespondToAuthChallengeInput,
        environment: UserPoolEnvironment,
        srpStateData: SRPStateData
    ) async throws -> SignInEvent {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let response = try await cognitoClient.respondToAuthChallenge(input: request)
        logVerbose("\(#fileID) InitiateAuth response success", environment: environment)
        return SignInEvent(eventType: .respondPasswordVerifier(srpStateData, response, clientMetadata))
    }

    private func sendRequest(
        request: InitiateAuthInput,
        environment: UserPoolEnvironment,
        srpStateData: SRPStateData
    ) async throws -> SignInEvent {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let response = try await cognitoClient.initiateAuth(input: request)
        logVerbose("\(#fileID) InitiateAuth response success", environment: environment)
        if case .customChallenge = response.challengeName {
            let parameters = response.challengeParameters
            let inputUsername = username
            let username = parameters?["USERNAME"] ?? username
            let respondToAuthChallenge = RespondToAuthChallenge(
                challenge: .customChallenge,
                availableChallenges: [],
                username: username,
                session: response.session,
                parameters: parameters,
                inputUsername: inputUsername
            )
            return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
        }
        return SignInEvent(eventType: .respondPasswordVerifier(srpStateData, response, clientMetadata))
    }
}

extension InitiateAuthSRP: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.maskedForLog(),
            "password": password.redactedForLog()
        ]
    }
}

extension InitiateAuthSRP: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

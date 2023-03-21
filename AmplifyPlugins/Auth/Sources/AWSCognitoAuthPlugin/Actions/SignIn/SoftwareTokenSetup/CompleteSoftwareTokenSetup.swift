//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct CompleteSoftwareTokenSetup: Action {

    var identifier: String = "CompleteSoftwareTokenSetup"

    let userSession: String

    let signInEventData: SignInEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        var deviceMetadata = DeviceMetadata.noData

        do {
            let authEnv = try environment.authEnvironment()
            let userpoolEnv = try environment.userPoolEnvironment()

            guard let username = signInEventData.username else {
                throw AuthError.unknown("", nil)
            }

            let session = userSession
            let challengeType: CognitoIdentityProviderClientTypes.ChallengeNameType = .mfaSetup

            deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: username,
                with: environment)

            var challengeResponses = [
                "USERNAME": username
            ]
            let userPoolClientId = userpoolEnv.userPoolConfiguration.clientId
            if let clientSecret = userpoolEnv.userPoolConfiguration.clientSecret {

                let clientSecretHash = ClientSecretHelper.clientSecretHash(
                    username: username,
                    userPoolClientId: userPoolClientId,
                    clientSecret: clientSecret
                )
                challengeResponses["SECRET_HASH"] = clientSecretHash
            }

            if case .metadata(let data) = deviceMetadata {
                challengeResponses["DEVICE_KEY"] = data.deviceKey
            }

            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient)
            var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
            if let encodedData = CognitoUserPoolASF.encodedContext(
                username: username,
                asfDeviceId: asfDeviceId,
                asfClient: userpoolEnv.cognitoUserPoolASFFactory(),
                userPoolConfiguration: userpoolEnv.userPoolConfiguration) {
                userContextData = .init(encodedData: encodedData)
            }

            let analyticsMetadata = userpoolEnv
                .cognitoUserPoolAnalyticsHandlerFactory()
                .analyticsMetadata()

            let input = RespondToAuthChallengeInput(
                analyticsMetadata: analyticsMetadata,
                challengeName: challengeType,
                challengeResponses: challengeResponses,
                clientId: userPoolClientId,
                session: session,
                userContextData: userContextData)

            let responseEvent = try await UserPoolSignInHelper.sendRespondToAuth(
                request: input,
                for: username,
                signInMethod: signInEventData.signInMethod,
                environment: userpoolEnv)
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)
//        } catch let error where deviceNotFound(error: error, deviceMetadata: deviceMetadata) {
//            logVerbose("\(#fileID) Received device not found \(error)", environment: environment)
//            // Remove the saved device details and retry verify challenge
//            await DeviceMetadataHelper.removeDeviceMetaData(for: username, with: environment)
//            let event = SignInChallengeEvent(
//                eventType: .retryVerifyChallengeAnswer(confirmSignEventData)
//            )
//            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
//            await dispatcher.send(event)
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

    func deviceNotFound(error: Error, deviceMetadata: DeviceMetadata) -> Bool {

        // If deviceMetadata was not send, the error returned is not from device not found.
        if case .noData = deviceMetadata {
            return false
        }

        if let serviceError: RespondToAuthChallengeOutputError = error.internalAWSServiceError(),
           case .resourceNotFoundException = serviceError {
            return true
        }
        return false
    }

}

extension CompleteSoftwareTokenSetup: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension CompleteSoftwareTokenSetup: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

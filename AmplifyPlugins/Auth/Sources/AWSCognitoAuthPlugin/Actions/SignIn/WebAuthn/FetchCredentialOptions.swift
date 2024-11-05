//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct FetchCredentialOptions: Action {
    let identifier = "FetchCredentialOptions"
    let username: String
    let respondToAuthChallenge: RespondToAuthChallenge
    let presentationAnchor: AuthUIPresentationAnchor?

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let authEnv = try environment.authEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient
            )
            let deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: username,
                with: environment
            )
            let request = await RespondToAuthChallengeInput.webAuthnInput(
                username: username,
                session: respondToAuthChallenge.session,
                asfDeviceId: asfDeviceId,
                deviceMetadata: deviceMetadata,
                environment: userPoolEnv
            )

            let cognitoClient = try userPoolEnv.cognitoUserPoolFactory()
            let response = try await cognitoClient.respondToAuthChallenge(input: request)
            guard let credentialOptions = response.challengeParameters?["CREDENTIAL_REQUEST_OPTIONS"],
                  let challengeName = response.challengeName else {
                let message = "Response did not contain SignIn info"
                let error = SignInError.invalidServiceResponse(message: message)
                let event = SignInEvent(eventType: .throwAuthError(error))
                await dispatcher.send(event)
                return
            }

            let options = try CredentialAssertionOptions(from: credentialOptions)
            let newRespondToAuthChallenge = RespondToAuthChallenge(
                challenge: challengeName,
                availableChallenges: [],
                username: username,
                session: response.session,
                parameters: response.challengeParameters
            )
            let event = WebAuthnEvent(
                eventType: .assertCredentials(options, .init(
                    username: username,
                    challenge: newRespondToAuthChallenge,
                    presentationAnchor: presentationAnchor
                ))
            )
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let webAuthnError = WebAuthnError.service(error: error)
            let event = WebAuthnEvent(
                eventType: .error(webAuthnError, respondToAuthChallenge)
            )
            await dispatcher.send(event)
        }
    }
}

extension FetchCredentialOptions: DefaultLogger { }

extension FetchCredentialOptions: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.masked(),
            "respondToAuthChallenge": respondToAuthChallenge.debugDictionary
        ]
    }
}

extension FetchCredentialOptions: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
#endif

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifyPasswordSRP: Action {
    let identifier = "VerifyPasswordSRP"

    let stateData: SRPStateData
    let authResponse: InitiateAuthOutputResponse

    init(stateData: SRPStateData,
         authResponse: InitiateAuthOutputResponse) {
        self.stateData = stateData
        self.authResponse = authResponse
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let environment = try SRPSignInHelper.srpEnvironment(environment)
            let srpClient = try SRPSignInHelper.srpClient(environment)
            let parameters = try challengeParameters()

            let inputUsername = stateData.username
            let username = parameters["USERNAME"] ?? inputUsername
            let userIdForSRP = parameters["USER_ID_FOR_SRP"] ?? inputUsername

            let saltHex = try saltHex(parameters)
            let secretBlockString = try secretBlockString(parameters)
            let secretBlock = try secretBlock(secretBlockString)
            let serverPublicB = try serverPublic(parameters)

            let signature = try signature(userIdForSRP: userIdForSRP,
                                          saltHex: saltHex,
                                          secretBlock: secretBlock,
                                          serverPublicBHexString: serverPublicB,
                                          srpClient: srpClient,
                                          environment: environment)
            let request = request(username: username,
                                  session: authResponse.session,
                                  secretBlock: secretBlockString,
                                  signature: signature,
                                  environment: environment)
            try sendRequest(request: request,
                            environment: environment) { responseEvent in
                logVerbose("\(#fileID) Sending event \(responseEvent)", environment: environment)
                dispatcher.send(responseEvent)
            }
        } catch let error as SRPSignInError {
            logVerbose("\(#fileID) SRPSignInError \(error)", environment: environment)
            let event = SRPSignInEvent(
                eventType: .throwPasswordVerifierError(error)
            )
            dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) SRPSignInError Generic \(error)", environment: environment)
            let authError = SRPSignInError.service(error: error)
            let event = SRPSignInEvent(
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
        }
    }

    private func request(username: String,
                         session: String?,
                         secretBlock: String,
                         signature: String,
                         environment: SRPAuthEnvironment)
    -> RespondToAuthChallengeInput {
        let dateStr = generateDateString(date: stateData.clientTimestamp)
        let userPoolClientId = environment.userPoolConfiguration.clientId
        var challengeResponses = ["USERNAME": username]
        if let clientSecret = environment.userPoolConfiguration.clientSecret {

            let clientSecretHash = SRPSignInHelper.clientSecretHash(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
            challengeResponses["SECRET_HASH"] = clientSecretHash
        }

        challengeResponses["TIMESTAMP"] = dateStr
        challengeResponses["PASSWORD_CLAIM_SECRET_BLOCK"] = secretBlock
        challengeResponses["PASSWORD_CLAIM_SIGNATURE"] = signature
        return RespondToAuthChallengeInput(
            analyticsMetadata: nil,
            challengeName: .passwordVerifier,
            challengeResponses: challengeResponses,
            clientId: userPoolClientId,
            clientMetadata: nil,
            session: session,
            userContextData: nil)
    }

    private func sendRequest(
        request: RespondToAuthChallengeInput,
        environment: SRPAuthEnvironment,
        callback: @escaping (StateMachineEvent) -> Void) throws {

            let client = try environment.cognitoUserPoolFactory()
            client.respondToAuthChallenge(input: request) { result in

                let event: StateMachineEvent!
                switch result {
                case .success(let response):
                    event = parseResponse(response)
                    callback(event)
                case .failure(let error):

                    let authError = SRPSignInError.service(error: error)
                    event = SRPSignInEvent(
                        eventType: .throwPasswordVerifierError(authError))
                    callback(event)
                }
            }
        }

    private func parseResponse(_ response: RespondToAuthChallengeOutputResponse) -> StateMachineEvent {

        if let authenticationResult = response.authenticationResult,
           let idToken = authenticationResult.idToken,
           let accessToken = authenticationResult.accessToken,
           let refreshToken = authenticationResult.refreshToken {

            let userPoolTokens = AWSCognitoUserPoolTokens(idToken: idToken,
                                                          accessToken: accessToken,
                                                          refreshToken: refreshToken,
                                                          expiresIn: authenticationResult.expiresIn)
            let signedInData = SignedInData(userId: "",
                                            userName: stateData.username,
                                            signedInDate: Date(),
                                            signInMethod: .srp,
                                            cognitoUserPoolTokens: userPoolTokens)
            return SRPSignInEvent(eventType: .finalizeSRPSignIn(signedInData))
            
        } else if let challengeName = response.challengeName,
                  let session = response.session {
            let parameters = response.challengeParameters
            let response = RespondToAuthChallenge(challenge: challengeName,
                                                  username: stateData.username,
                                                  session: session,
                                                  parameters: parameters)

            switch challengeName {
            case .smsMfa:

                return SignInEvent(eventType: .receivedSMSChallenge(response))
            default:
                let message = "UnSupported challenge response \(challengeName)"
                let error = SRPSignInError.invalidServiceResponse(message: message)
                return SRPSignInEvent(eventType: .throwPasswordVerifierError(error))
            }
        } else {
            let message = "Response did not contain signIn info"
            let error = SRPSignInError.invalidServiceResponse(message: message)
            return SRPSignInEvent(eventType: .throwPasswordVerifierError(error))
        }
    }
}

extension VerifyPasswordSRP: DefaultLogger { }

extension VerifyPasswordSRP: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "stateData": stateData.debugDictionary,
            "authResponse": authResponse
        ]
    }
}

extension VerifyPasswordSRP: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

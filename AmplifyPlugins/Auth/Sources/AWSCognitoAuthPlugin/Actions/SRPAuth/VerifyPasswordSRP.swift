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

        Amplify.Logging.verbose("Starting execution \(#fileID)")
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
                dispatcher.send(responseEvent)
                Amplify.Logging.verbose("sending event #file")
            }
        } catch let error as SRPSignInError {
            Amplify.Logging.verbose("SRPSignInError \(error) #file")
            let event = SRPSignInEvent(
                eventType: .throwPasswordVerifierError(error)
            )
            dispatcher.send(event)
        } catch {
            Amplify.Logging.verbose("Caught error \(error) #file")
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
        callback: @escaping (SRPSignInEvent) -> Void) throws {

            let client = try environment.cognitoUserPoolFactory()
            client.respondToAuthChallenge(input: request) { result in

                let event: SRPSignInEvent!
                switch result {
                case .success(let response):
                    guard let signedInData = parseResponse(response) else {
                        let message = "Response did not contain signIn info"
                        let error = SRPSignInError.invalidServiceResponse(
                            message: message
                        )
                        event = SRPSignInEvent(
                            eventType: .throwPasswordVerifierError(error)
                        )
                        callback(event)
                        return
                    }
                    event = SRPSignInEvent(
                        eventType: .finalizeSRPSignIn(signedInData))
                    callback(event)
                case .failure(let error):

                    let authError = SRPSignInError.service(error: error)
                    event = SRPSignInEvent(
                        eventType: .throwPasswordVerifierError(authError))
                    callback(event)
                }
            }
        }

    private func parseResponse(_ response: RespondToAuthChallengeOutputResponse)
    -> SignedInData? {
        guard let authResult = response.authenticationResult,
              let idToken = authResult.idToken,
              let accessToken = authResult.accessToken,
              let refreshToken = authResult.refreshToken
        else {
            return nil
        }
        let userPoolTokens = AWSCognitoUserPoolTokens(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: authResult.expiresIn)

        return SignedInData(
            userId: "",
            userName: stateData.username,
            signedInDate: Date(),
            signInMethod: .srp,
            cognitoUserPoolTokens: userPoolTokens)
    }
}

extension VerifyPasswordSRP: DefaultLogger { }

extension VerifyPasswordSRP: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "stateData": stateData.debugDictionary,
            "authResponse": authResponse
        ]
    }
}

extension VerifyPasswordSRP: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifyAuthChallenge: Action {
    let identifier = "VerifyAuthChallenge"

    let username: String
    let answer: String
    let session: String


    init(username: String, answer: String, session: String) {
        self.username = username
        self.answer = answer
        self.session = session
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        guard let environment = environment as? UserPoolEnvironment else {

            fatalError("TODO fix with right error")
        }
        do {

            let request = request(username: username,
                                  challengeAnswer: answer,
                                  session: session,
                                  environment: environment)
            try sendRequest(request: request,
                            environment: environment) { responseEvent in
                logVerbose("\(#fileID) Sending event \(responseEvent)", environment: environment)
                dispatcher.send(responseEvent)
            }
        } catch let error as SRPSignInError {
            logVerbose("\(#fileID) SignInError \(error)", environment: environment)
            fatalError()
        } catch {
            logVerbose("\(#fileID) SignInError Generic \(error)", environment: environment)
            fatalError()
        }

    }

    private func sendRequest(
        request: RespondToAuthChallengeInput,
        environment: UserPoolEnvironment,
        callback: @escaping (StateMachineEvent) -> Void) throws {

            let client = try environment.cognitoUserPoolFactory()
            client.respondToAuthChallenge(input: request) { result in

                let event: StateMachineEvent!
                switch result {
                case .success(let response):
                    print(response)
                case .failure(let error):

                    let authError = SRPSignInError.service(error: error)
                    event = SRPSignInEvent(
                        eventType: .throwPasswordVerifierError(authError))
                    callback(event)
                }
            }
        }

    private func request(username: String,
                         challengeAnswer: String,
                         session: String,
                         environment: UserPoolEnvironment)
    -> RespondToAuthChallengeInput {

        let userPoolClientId = environment.userPoolConfiguration.clientId
        var challengeResponses = ["USERNAME": username]
        challengeResponses["SMS_MFA_CODE"] = challengeAnswer
        if let clientSecret = environment.userPoolConfiguration.clientSecret {

            let clientSecretHash = SRPSignInHelper.clientSecretHash(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
            challengeResponses["SECRET_HASH"] = clientSecretHash
        }

        return RespondToAuthChallengeInput(
            analyticsMetadata: nil,
            challengeName: .smsMfa,
            challengeResponses: challengeResponses,
            clientId: userPoolClientId,
            clientMetadata: nil,
            session: session,
            userContextData: nil)
    }
}

extension VerifyAuthChallenge: DefaultLogger { }

extension VerifyAuthChallenge: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "answer": answer.masked(),
            "session": session.masked()
        ]
    }
}

extension VerifyAuthChallenge: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

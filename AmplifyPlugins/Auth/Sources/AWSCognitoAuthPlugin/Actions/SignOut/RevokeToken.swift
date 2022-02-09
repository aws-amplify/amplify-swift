//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

struct RevokeToken: Action {

    var identifier: String = "RevokeToken"
    let signedInData: SignedInData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        guard let environment = environment as? UserPoolEnvironment else {
            let error = AuthenticationError.configuration(message: "Environment configured incorrectly")
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(error))
            dispatcher.send(event)
            timer.stop("### sending \(event.type)")
            return
        }
        
        let client: CognitoUserPoolBehavior
        do {
            client = try environment.cognitoUserPoolFactory()
        } catch {
            let authError = AuthenticationError.configuration(message: "Failed to get CognitoUserPool client: \(error)")
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(authError))
            dispatcher.send(event)
            timer.stop("### sending \(event.type)")
            return
        }
        
        timer.note("### Starting revokeToken")
        let clientId = environment.userPoolConfiguration.clientId
        let clientSecret = environment.userPoolConfiguration.clientSecret
        let refreshToken = signedInData.cognitoUserPoolTokens.refreshToken
        
        let input = RevokeTokenInput(clientId: clientId, clientSecret: clientSecret, token: refreshToken)
        
        client.revokeToken(input: input) { result in
            // Log the result, but proceed to clear credential store regardless of revokeToken result.
            timer.note("### revokeToken response received")
            switch result {
            case .success:
                timer.note("### revokeToken succeeded")
            case .failure(let error):
                timer.note("### revokeToken failed with error: \(error)")
            }
            let event = SignOutEvent(eventType: .signOutLocally(signedInData))
            dispatcher.send(event)
            timer.stop("### sending \(event.type)")
        }
    }
}

extension RevokeToken: DefaultLogger { }

extension RevokeToken: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension RevokeToken: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}



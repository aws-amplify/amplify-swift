//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

struct SignOutGlobally: Action {

    var identifier: String = "SignOutGlobally"
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
            let event = SignOutEvent(eventType: .signedOutFailure(authError))
            dispatcher.send(event)
            timer.stop("### sending \(event.type)")
            return
        }
        
        timer.note("### Starting signOut")
        let input = GlobalSignOutInput(accessToken: signedInData.cognitoUserPoolTokens.accessToken)
        
        client.globalSignOut(input: input) { result in
            // Log the result, but proceed to attempt to revoke tokens regardless of globalSignOut result.
            timer.note("### globalSignOut response received")
            switch result {
            case .success:
                timer.note("### globalSignOut succeeded")
            case .failure(let error):
                timer.note("### globalSignOut failed with error: \(error)")
            }
            let event = SignOutEvent(eventType: .revokeToken(signedInData))
            dispatcher.send(event)
            timer.stop("### sending \(event.type)")
        }
    }
}

extension SignOutGlobally: DefaultLogger { }

extension SignOutGlobally: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension SignOutGlobally: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}


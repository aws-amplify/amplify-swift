//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct SetUpTOTP: Action {

    var identifier: String = "SetUpTOTP"
    let authResponse: SignInResponseBehavior
    let signInEventData: SignInEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let userpoolEnv = try environment.userPoolEnvironment()
            let client = try userpoolEnv.cognitoUserPoolFactory()
            let input = AssociateSoftwareTokenInput(session: authResponse.session)

            // Initiate Set Up TOTP
            let result = try await client.associateSoftwareToken(input: input)

            guard let username = signInEventData.username else {
                throw SignInError.unknown(message: "Unable unwrap username to for use during TOTP setup")
            }

            guard let session = result.session,
                  let secretCode = result.secretCode else {
                throw SignInError.unknown(message: "Error unwrapping result associateSoftwareToken result")
            }

            let responseEvent = SetUpTOTPEvent(eventType:
                    .waitForAnswer(.init(
                        secretCode: secretCode,
                        session: session,
                        username: username)))
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)
        } catch let error as SignInError {
            logError(error.authError.errorDescription, environment: environment)
            let errorEvent = SetUpTOTPEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.service(error: error)
            logError(error.authError.errorDescription, environment: environment)
            let errorEvent = SetUpTOTPEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        }
    }

}

extension SetUpTOTP: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "challengeName": authResponse.challengeName?.rawValue ?? "",
            "session": authResponse.session?.masked() ?? "",
            "challengeParameters": authResponse.challengeParameters ?? [:],
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension SetUpTOTP: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

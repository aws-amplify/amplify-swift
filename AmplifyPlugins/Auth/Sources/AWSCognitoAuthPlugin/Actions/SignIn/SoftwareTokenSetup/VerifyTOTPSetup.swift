//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifyTOTPSetup: Action {

    var identifier: String = "VerifyTOTPSetup"
    let session: String
    let totpCode: String
    let friendlyDeviceName: String?

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let userpoolEnv = try environment.userPoolEnvironment()
            let client = try userpoolEnv.cognitoUserPoolFactory()
            let input = VerifySoftwareTokenInput(
                friendlyDeviceName: friendlyDeviceName,
                session: session,
                userCode: totpCode)

            // Initiate TOTP verification
            let result = try await client.verifySoftwareToken(input: input)

            guard let session = result.session else {
                throw SignInError.unknown(message: "Unable to retrieve the session value from VerifySoftwareToken response")
            }

            let responseEvent = SetUpTOTPEvent(eventType:
                    .respondToAuthChallenge(session))
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

extension VerifyTOTPSetup: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "session": session.masked(),
            "totpCode": totpCode.redacted(),
            "friendlyDeviceName": friendlyDeviceName ?? ""
        ]
    }
}

extension VerifyTOTPSetup: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

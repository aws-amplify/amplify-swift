//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import Foundation
import Amplify
import ClientRuntime

struct FetchAuthAWSCredentials: Action {

    let identifier = "FetchAuthAwsCredentials"

    let loginsMap: [String: String]

    let identityID: String

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let authEnv = environment as? AuthEnvironment,
              let authZEnvironment = authEnv.authorizationEnvironment,
              let client = try? authZEnvironment.cognitoIdentityFactory()
        else {
            let authZError = FetchSessionError.noIdentityPool
            let event = FetchAuthSessionEvent(eventType: .throwError(authZError))
            dispatcher.send(event)
            return
        }

        let getCredentialsInput = GetCredentialsForIdentityInput(identityId: identityID,
                                                                 logins: loginsMap)

        Task {
            do {
                let response = try await client.getCredentialsForIdentity(input: getCredentialsInput)
                guard let identityId = response.identityId else {
                    let event = FetchAuthSessionEvent(eventType: .throwError(.invalidIdentityID))
                    dispatcher.send(event)
                    logVerbose("\(#fileID) Sending event \(event.type)",
                               environment: environment)
                    return
                }
                guard let awsCredentials = response.credentials,
                      let accessKey = awsCredentials.accessKeyId,
                      let secretKey = awsCredentials.secretKey,
                      let sessionKey = awsCredentials.sessionToken,
                      let expiration = awsCredentials.expiration
                else {
                    // TODO: Handle error
                   fatalError()
                }
                let awsCognitoCredentials = AuthAWSCognitoCredentials(accessKey: accessKey,
                                                                      secretKey: secretKey,
                                                                      sessionKey: sessionKey,
                                                                      expiration: expiration)
                let fetchedAWSCredentialEvent = FetchAuthSessionEvent(
                    eventType: .fetchedAWSCredentials(identityId, awsCognitoCredentials))
                logVerbose("\(#fileID) Sending event \(fetchedAWSCredentialEvent.type)",
                           environment: environment)
                dispatcher.send(fetchedAWSCredentialEvent)

            } catch {
                // TODO: Handle error
//                let sdkError = error as? SdkError<GetCredentialsForIdentityOutputError> ?? SdkError.unknown(error)
//                let authZError = AuthorizationError.service(error: error)
//                let event = FetchAWSCredentialEvent(eventType: .throwError(authZError))
//                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
//                dispatcher.send(event)
                fatalError()
            }
        }
    }
}

extension FetchAuthAWSCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthAWSCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

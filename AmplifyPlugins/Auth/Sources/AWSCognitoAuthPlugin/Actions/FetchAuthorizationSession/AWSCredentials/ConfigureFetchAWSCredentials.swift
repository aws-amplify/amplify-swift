//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Foundation

struct ConfigureFetchAWSCredentials: Action {

    let identifier = "ConfigureFetchAWSCredentials"

    let cognitoSession: AWSAuthCognitoSession

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {

        if case let .failure(error) = cognitoSession.identityIdResult {
            let authZError = AuthorizationError.service(error: error)
            let event = FetchAWSCredentialEvent(eventType: .throwError(authZError))
            dispatcher.send(event)

            let updatedSession = cognitoSession.copySessionByUpdating(awsCredentialsResult: .failure(error))
            let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(updatedSession))
            dispatcher.send(fetchedAuthSessionEvent)

            return
        }

        logVerbose("\(#fileID) Starting execution", environment: environment)

        let refreshInterval = AuthPluginConstants.sessionRefreshInterval
        if case let .success(awsCredentials) = cognitoSession.awsCredentialsResult,
           let cognitoAWSCredentials = awsCredentials as? AuthAWSCognitoCredentials,
           cognitoAWSCredentials.expiration.compare(Date().addingTimeInterval(refreshInterval)) == .orderedDescending {

            let fetchedCredentialsEvent = FetchAWSCredentialEvent(eventType: .fetched)
            logVerbose("\(#fileID) Sending event \(fetchedCredentialsEvent.type)", environment: environment)
            dispatcher.send(fetchedCredentialsEvent)

            let fetchAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(cognitoSession))
            logVerbose("\(#fileID) Sending event \(fetchAuthSessionEvent.type)", environment: environment)
            dispatcher.send(fetchAuthSessionEvent)
        } else {
            let fetchAWSCredentialEvent = FetchAWSCredentialEvent(eventType: .fetch(cognitoSession))
            logVerbose("\(#fileID) Sending event \(fetchAWSCredentialEvent.type)", environment: environment)
            dispatcher.send(fetchAWSCredentialEvent)
        }
    }
}

extension ConfigureFetchAWSCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureFetchAWSCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

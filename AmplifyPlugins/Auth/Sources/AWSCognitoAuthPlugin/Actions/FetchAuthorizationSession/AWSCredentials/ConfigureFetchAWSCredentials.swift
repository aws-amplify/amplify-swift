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

        let timer = LoggingTimer(identifier).start("### Starting execution")

        let refreshInterval = AuthPluginConstants.sessionRefreshInterval
        if case let .success(awsCredentials) = cognitoSession.awsCredentialsResult,
           let cognitoAWSCredentials = awsCredentials as? AuthAWSCognitoCredentials,
           cognitoAWSCredentials.expiration.compare(Date().addingTimeInterval(refreshInterval)) == .orderedDescending {

            let fetchedCredentialsEvent = FetchAWSCredentialEvent(eventType: .fetched)
            timer.note("### sending \(fetchedCredentialsEvent.type)")
            dispatcher.send(fetchedCredentialsEvent)

            let fetchAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(cognitoSession))
            timer.stop("### sending \(fetchAuthSessionEvent.type)")
            dispatcher.send(fetchAuthSessionEvent)
        } else {
            let fetchAWSCredentialEvent = FetchAWSCredentialEvent(eventType: .fetch(cognitoSession))
            timer.stop("### sending \(fetchAWSCredentialEvent.type)")
            dispatcher.send(fetchAWSCredentialEvent)
        }
    }
}

extension ConfigureFetchAWSCredentials: DefaultLogger { }

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

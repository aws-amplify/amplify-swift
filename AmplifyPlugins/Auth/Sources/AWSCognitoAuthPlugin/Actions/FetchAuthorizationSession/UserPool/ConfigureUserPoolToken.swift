//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ConfigureUserPoolToken: Action {

    let identifier = "ConfigureUserPoolToken"

    let cognitoSession: AWSAuthCognitoSession

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("Starting execution", environment: environment)

        switch cognitoSession.cognitoTokensResult {
        case .success(let cognitoUserPoolTokens):

            let refreshInterval = AuthPluginConstants.sessionRefreshInterval
            // If the session expires > 2 minutes return it
            if cognitoUserPoolTokens.expiration.compare(Date().addingTimeInterval(refreshInterval)) == .orderedDescending {

                let userPoolTokensEvent = FetchUserPoolTokensEvent(eventType: .fetched)
                logVerbose("Sending event \(userPoolTokensEvent.type)", environment: environment)
                dispatcher.send(userPoolTokensEvent)

                // User pool tokens are valid, move to fetching the identity
                let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(cognitoSession))
                logVerbose("Sending event \(fetchIdentityEvent.type)", environment: environment)
                dispatcher.send(fetchIdentityEvent)
            } else {
                let event = FetchUserPoolTokensEvent(eventType: .refresh(cognitoSession))
                logVerbose("Sending event \(event.type)", environment: environment)
                dispatcher.send(event)
            }

        case .failure(let error):
            let authError = AuthorizationError.service(error: error)
            let event = FetchUserPoolTokensEvent(eventType: .throwError(authError))
            dispatcher.send(event)

            // No User pool tokens, possibly a signed out state
            let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(cognitoSession))
            logVerbose("Sending event \(fetchIdentityEvent.type)", environment: environment)
            dispatcher.send(fetchIdentityEvent)
        }
    }
}

extension ConfigureUserPoolToken: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureUserPoolToken: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

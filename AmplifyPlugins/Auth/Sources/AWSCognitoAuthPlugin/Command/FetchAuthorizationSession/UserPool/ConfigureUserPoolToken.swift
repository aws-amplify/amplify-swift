//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct ConfigureUserPoolToken: Command {
    
    let identifier = "ConfigureUserPoolToken"
    
    let cognitoSession: AWSAuthCognitoSession
    
    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        switch cognitoSession.cognitoTokensResult {
        case .success(let cognitoUserPoolTokens):
            
            let refreshInterval = AuthPluginConstants.sessionRefreshInterval
            // If the session expires > 2 minutes return it
            if cognitoUserPoolTokens.expiration.compare(Date().addingTimeInterval(refreshInterval)) == .orderedDescending {
                
                let userPoolTokensEvent = FetchUserPoolTokensEvent(eventType: .fetched)
                timer.note("### sending event \(userPoolTokensEvent.type)")
                dispatcher.send(userPoolTokensEvent)
                
                // User pool tokens are valid, move to fetching the identity
                let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(cognitoSession))
                timer.stop("### sending event \(fetchIdentityEvent.type)")
                dispatcher.send(fetchIdentityEvent)
            } else {
                let event = FetchUserPoolTokensEvent(eventType: .refresh(cognitoSession))
                timer.stop("### sending event \(event.type)")
                dispatcher.send(event)
            }
            
        case .failure(let error):
            let authError = AuthorizationError.service(error: error)
            let event = FetchUserPoolTokensEvent(eventType: .throwError(authError))
            dispatcher.send(event)
            
            // No User pool tokens, possibly a signed out state
            let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(cognitoSession))
            timer.stop("### sending event \(fetchIdentityEvent.type)")
            dispatcher.send(fetchIdentityEvent)
        }

    }
}

extension ConfigureUserPoolToken: DefaultLogger { }

extension ConfigureUserPoolToken: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureUserPoolToken: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

struct LoadPersistedAuthentication: Action {
    let identifier = "LoadPersistedAuthentication"
    let configuration: AuthConfiguration

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        guard let credentialStoreEnvironment = (environment as? AuthEnvironment)?.credentialStoreEnvironment else {
            let event = AuthenticationEvent(
                eventType: .error(AuthenticationError.configuration(message: AuthPluginErrorConstants.configurationError)))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
            return
        }
        
        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()
        let storedCredentials = try? amplifyCredentialStore.retrieveCredential()
        
        let authenticationEvent: AuthenticationEvent
        
        if let userPoolTokens = storedCredentials?.userPoolTokens {
            let signedInData = SignedInData(userId: "",
                                            userName: "",
                                            signedInDate: Date(),
                                            signInMethod: .srp,
                                            cognitoUserPoolTokens: userPoolTokens)
            authenticationEvent = AuthenticationEvent(eventType: .initializedSignedIn(signedInData))
        } else {
            let signedOutData = SignedOutData(authenticationConfiguration: configuration, lastKnownUserName: nil)
            authenticationEvent = AuthenticationEvent(eventType: .initializedSignedOut(signedOutData))
        }
        timer.stop("### sending event \(authenticationEvent.type)")
        dispatcher.send(authenticationEvent)

        let authStateEvent = AuthEvent(eventType: .authenticationConfigured(configuration))
        timer.stop("### sending event \(authStateEvent.type)")
        dispatcher.send(authStateEvent)
    }
}

extension LoadPersistedAuthentication: DefaultLogger { }

extension LoadPersistedAuthentication: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration.debugDictionary
        ]
    }
}

extension LoadPersistedAuthentication: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

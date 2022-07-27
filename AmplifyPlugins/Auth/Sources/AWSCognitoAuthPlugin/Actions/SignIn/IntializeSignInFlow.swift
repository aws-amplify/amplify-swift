//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitializeSignInFlow: Action {

    var identifier: String = "IntializeSignInFlow"

    let signInEventData: SignInEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let authEnvironment = environment as? AuthEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let event = SignInEvent(eventType: .throwAuthError(.configuration(message: message)))
            dispatcher.send(event)
            return
        }

        let userPoolConfiguration = authEnvironment.userPoolConfiguration
        let authFlowFromConfig = userPoolConfiguration.authFlowType

        let event: SignInEvent
        switch signInEventData.signInMethod {

        case .apiBased(let authflowType):
            if authflowType != .unknown {
                event = signInEvent(for: authflowType)
            } else {
                event = signInEvent(for: authFlowFromConfig)
            }
        case .hostedUI(let hostedUIOptions):
            event = .init(eventType: .initiateHostedUISignIn(hostedUIOptions))
        case .federated:
            // TODO: Implementation pending
            fatalError("Not implemented")
        case .unknown:
            event = signInEvent(for: authFlowFromConfig)
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }

    func signInEvent(for authflow: AuthFlowType) -> SignInEvent {
        switch authflow {
        case .userSRP:
            return .init(eventType: .initiateSignInWithSRP(signInEventData))
        case .custom:
            return .init(eventType: .initiateCustomSignIn(signInEventData))
        case .customWithSRP:
            return .init(eventType: .initiateCustomSignInWithSRP(signInEventData))
        case .userPassword:
            return .init(eventType: .initiateMigrateAuth(signInEventData))
        case .unknown:
            // Default to SRP signIn if we could not figure out the authflow type
            return .init(eventType: .initiateSignInWithSRP(signInEventData))
        }
    }

}

extension InitializeSignInFlow: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeSignInFlow: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

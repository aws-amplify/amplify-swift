//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AuthenticationServices

class ShowHostedUISignIn: NSObject, Action {

    var identifier: String = "ShowHostedUISignIn"

    let signingInData: HostedUISigningInState

    var sessionAdapter: HostedUISessionBehavior? = nil

    init(signInData: HostedUISigningInState) {
        self.signingInData = signInData
    }

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIEnvironment = environment.hostedUIEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = AuthenticationEvent(eventType: .error(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        let hostedUIConfig = hostedUIEnvironment.configuration

        guard let callbackURL = URL(string: hostedUIConfig.oauth.signInRedirectURI),
              let callbackURLScheme = callbackURL.scheme else {
            let event = SignInEvent(eventType: .throwAuthError(.hostedUI(.signInURI)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        let url = signingInData.signInURL
        self.logVerbose("\(#fileID) Showing url \(url.absoluteString)", environment: environment)
        sessionAdapter = hostedUIEnvironment.hostedUISessionFactory()
        sessionAdapter?.showHostedUI(
            url: url,
            callbackScheme: callbackURLScheme,
            inPrivate: signingInData.options.preferPrivateSession,
            presentationAnchor: signingInData.presentationAnchor) { result in
                switch result {
                case .failure(let error):
                    self.logVerbose("\(#fileID) Received error \(error)", environment: environment)
                    let event = HostedUIEvent(eventType: .throwError(.hostedUI(error)))
                    self.logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                    dispatcher.send(event)
                case .success(let queryItems):
                    guard let code = queryItems.first(where: { $0.name == "code" })?.value,
                          let state = queryItems.first(where: { $0.name == "state" })?.value,
                          self.signingInData.state == state else {

                        let event = HostedUIEvent(eventType: .throwError(.hostedUI(.codeValidation)))
                        self.logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                        dispatcher.send(event)
                        return
                    }

                    let result = HostedUIResult(code: code,
                                                state: state,
                                                codeVerifier: self.signingInData.codeChallenge,
                                                options: self.signingInData.options)
                    let event = HostedUIEvent(eventType: .fetchToken(result))
                    self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                }
            }
    }

}

extension ShowHostedUISignIn: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ShowHostedUISignIn {
    override var debugDescription: String {
        debugDictionary.debugDescription
    }
}

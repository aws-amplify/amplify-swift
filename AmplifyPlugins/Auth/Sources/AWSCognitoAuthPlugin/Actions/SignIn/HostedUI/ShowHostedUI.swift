//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AuthenticationServices

class ShowHostedUI: NSObject, Action {

    var identifier: String = "ShowHostedUI"

    let signingInData: HostedUISigningInState

    init(signInData: HostedUISigningInState) {
        self.signingInData = signInData
    }

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIConfig = environment.userPoolConfiguration.hostedUIConfig else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = AuthenticationEvent(eventType: .error(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        guard let callbackURL = URL(string: hostedUIConfig.oauth.signInRedirectURI),
              let callbackURLScheme = callbackURL.scheme else {
            let event = SignInEvent(eventType: .throwAuthError(.hostedUI(.signInURI)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        let aswebAuthenticationSession = ASWebAuthenticationSession(
            url: signingInData.signInURL,
            callbackURLScheme: callbackURLScheme,
            completionHandler: { url, error in

                if let url = url {
                    let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let queryItems = urlComponents?.queryItems

                    if let error = queryItems?.first(where: { $0.name == "error" })?.value {
                        let event = HostedUIEvent(eventType: .throwError(.hostedUI(.serviceMessage(error))))
                        self.logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                        dispatcher.send(event)
                        return
                    }

                    guard let code = queryItems?.first(where: { $0.name == "code" })?.value,
                          let state = queryItems?.first(where: { $0.name == "state" })?.value,
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

                if let error = error {
                    let event = HostedUIEvent(eventType: .throwError(.service(error: error)))
                    self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                }

        })
        aswebAuthenticationSession.prefersEphemeralWebBrowserSession = signingInData
            .options
            .preferPrivateSession
        aswebAuthenticationSession.presentationContextProvider = self
        aswebAuthenticationSession.start()
    }

}

extension ShowHostedUI: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return signingInData.presentationAnchor
    }
}

extension ShowHostedUI: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ShowHostedUI {
    override var debugDescription: String {
        debugDictionary.debugDescription
    }
}

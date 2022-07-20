//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AuthenticationServices

class ShowHostedUISignOut: NSObject, Action {

    var identifier: String = "ShowHostedUISignOut"

    let signOutEvent: SignOutEventData
    let signInData: SignedInData

    init(signOutEvent: SignOutEventData, signInData: SignedInData) {
        self.signInData = signInData
        self.signOutEvent = signOutEvent
    }

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIConfig = environment.userPoolConfiguration.hostedUIConfig else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = SignOutEvent(eventType: .signedOutFailure(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        guard let callbackURL = URL(string: hostedUIConfig.oauth.signOutRedirectURI),
              let callbackURLScheme = callbackURL.scheme else {
            let error = AuthenticationError.configuration(message: "Callback URL could not be retrieved")
            let event = SignOutEvent(eventType: .signedOutFailure(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        let signOutURI = hostedUIConfig.oauth
            .signOutRedirectURI
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        let state = UUID().uuidString.lowercased()
        var components = URLComponents()
        components.scheme = "https"
        components.path = "/logout"
        components.host = hostedUIConfig.oauth.domain
        components.queryItems = [
            URLQueryItem(name: "client_id", value: hostedUIConfig.clientId),
            URLQueryItem(name: "logout_uri", value: signOutURI),
        ]

        guard let logutURL = components.url else {
            let error = AuthenticationError.configuration(message: "Could not create logout URL")
            let event = SignOutEvent(eventType: .signedOutFailure(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }


        let aswebAuthenticationSession = ASWebAuthenticationSession(
            url: logutURL,
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

                    let event: SignOutEvent
                    if self.signOutEvent.globalSignOut {
                        event = SignOutEvent(eventType: .signOutGlobally(self.signInData))
                    } else {
                        event = SignOutEvent(eventType: .revokeToken(self.signInData))
                    }
                    self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                }

                if let error = error {
                    let event = HostedUIEvent(eventType: .throwError(.service(error: error)))
                    self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                }

        })
        aswebAuthenticationSession.presentationContextProvider = self
        DispatchQueue.main.async {
            aswebAuthenticationSession.start()
        }
    }

}

extension ShowHostedUISignOut: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

extension ShowHostedUISignOut: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ShowHostedUISignOut {
    override var debugDescription: String {
        debugDictionary.debugDescription
    }
}

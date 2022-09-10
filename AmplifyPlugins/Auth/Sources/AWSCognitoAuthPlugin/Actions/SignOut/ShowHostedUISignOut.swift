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

    var sessionAdapter: HostedUISessionBehavior?

    init(signOutEvent: SignOutEventData, signInData: SignedInData) {
        self.signInData = signInData
        self.signOutEvent = signOutEvent
    }

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIEnvironment = environment.hostedUIEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
            return
        }
        let hostedUIConfig = hostedUIEnvironment.configuration

        guard let callbackURL = URL(string: hostedUIConfig.oauth.signOutRedirectURI),
              let callbackURLScheme = callbackURL.scheme else {
            let error = AuthenticationError.configuration(message: "Callback URL could not be retrieved")
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
            return
        }

        do {
            let logoutURL = try HostedUIRequestHelper.createSignOutURL(configuration: hostedUIConfig)
            _ = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<[URLQueryItem], Error>) in
                sessionAdapter = hostedUIEnvironment.hostedUISessionFactory()
                sessionAdapter?.showHostedUI(url: logoutURL,
                                             callbackScheme: callbackURLScheme,
                                             inPrivate: false,
                                             presentationAnchor: signOutEvent.presentationAnchor) {
                    result in
                    continuation.resume(with: result)
                }
            }

            await sendEvent(with: nil, dispatcher: dispatcher, environment: environment)

        } catch HostedUIError.signOutURI {
            let error = AuthenticationError.configuration(message: "Could not create logout URL")
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
            return
        } catch {
            self.logVerbose("\(#fileID) Received error \(error)", environment: environment)
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
        }
    }

    func sendEvent(with error: Error?,
                   dispatcher: EventDispatcher,
                   environment: Environment) async {

        var hostedUIError: AWSCognitoHostedUIError?
        if let hostedUIInternalError = error as? HostedUIError,
           case .cancelled = hostedUIInternalError {
           let event = SignOutEvent(eventType: .userCancelled)
            self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
            return
        }

        if let error = error as? AuthErrorConvertible {
            hostedUIError = AWSCognitoHostedUIError(error: error.authError)
        } else if let error = error {
            let serviceError = AuthError.service("HostedUI failed with error",
                                                 "", error)
            hostedUIError = AWSCognitoHostedUIError(error: serviceError)
        }
        let event: SignOutEvent
        if self.signOutEvent.globalSignOut {
            event = SignOutEvent(eventType: .signOutGlobally(self.signInData,
                                                             hostedUIError: hostedUIError))
        } else {
            event = SignOutEvent(eventType: .revokeToken(self.signInData,
                                                         hostedUIError: hostedUIError))
        }
        self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension ShowHostedUISignOut: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInData": signInData.debugDictionary,
            "signOutEvent": signOutEvent.debugDictionary
        ]
    }
}

extension ShowHostedUISignOut {
    override var debugDescription: String {
        debugDictionary.debugDescription
    }
}

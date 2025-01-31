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

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIEnvironment = environment.hostedUIEnvironment else {
            let error = HostedUIError.pluginConfiguration(AuthPluginErrorConstants.configurationError)
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
            return
        }
        let hostedUIConfig = hostedUIEnvironment.configuration
        guard let callbackURL = URL(string: hostedUIConfig.oauth.signOutRedirectURI),
              let callbackURLScheme = callbackURL.scheme else {
            await sendEvent(with: HostedUIError.signOutRedirectURI, dispatcher: dispatcher, environment: environment)
            return
        }

        do {
            let logoutURL = try HostedUIRequestHelper.createSignOutURL(configuration: hostedUIConfig)
            let sessionAdapter = hostedUIEnvironment.hostedUISessionFactory()
            _ = try await sessionAdapter.showHostedUI(
                url: logoutURL,
                callbackScheme: callbackURLScheme,
                inPrivate: false,
                presentationAnchor: signOutEvent.presentationAnchor)
            await sendEvent(with: nil, dispatcher: dispatcher, environment: environment)
        } catch HostedUIError.cancelled {
            if signInData.isRefreshTokenExpired == true {
                self.logVerbose("\(#fileID) Received user cancelled error, but session is expired and continue signing out.", environment: environment)
                await sendEvent(with: nil, dispatcher: dispatcher, environment: environment)
            } else {
                self.logVerbose("\(#fileID) Received error \(HostedUIError.cancelled)", environment: environment)
                await sendEvent(with: HostedUIError.cancelled, dispatcher: dispatcher, environment: environment)
            }
        } catch {
            self.logVerbose("\(#fileID) Received error \(error)", environment: environment)
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
        }
    }

    func sendEvent(with error: Error?,
                   dispatcher: EventDispatcher,
                   environment: Environment) async {

        let event: SignOutEvent
        if let hostedUIInternalError = error as? HostedUIError {
           event = SignOutEvent(eventType: .hostedUISignOutError(hostedUIInternalError))
        } else if let error = error as? AuthErrorConvertible {
            event = getEvent(for: AWSCognitoHostedUIError(error: error.authError))
        } else if let error = error {
            let serviceError = AuthError.service(
                "HostedUI failed with error", 
                "", 
                error
            )
            event = getEvent(for: AWSCognitoHostedUIError(error: serviceError))
        } else {
            event = getEvent(for: nil)
        }
        self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

    private func getEvent(for hostedUIError: AWSCognitoHostedUIError?) -> SignOutEvent {
        if self.signOutEvent.globalSignOut {
            return SignOutEvent(eventType: .signOutGlobally(self.signInData,
                                                             hostedUIError: hostedUIError))
        } else {
            return SignOutEvent(eventType: .revokeToken(self.signInData,
                                                         hostedUIError: hostedUIError))
        }
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

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
            let event = SignOutEvent(eventType: .signedOutFailure(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
            return
        }
        let hostedUIConfig = hostedUIEnvironment.configuration
        
        guard let callbackURL = URL(string: hostedUIConfig.oauth.signOutRedirectURI),
              let callbackURLScheme = callbackURL.scheme else {
            let error = AuthenticationError.configuration(message: "Callback URL could not be retrieved")
            let event = SignOutEvent(eventType: .signedOutFailure(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
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
            let event: SignOutEvent
            if self.signOutEvent.globalSignOut {
                event = SignOutEvent(eventType: .signOutGlobally(self.signInData))
            } else {
                event = SignOutEvent(eventType: .revokeToken(self.signInData))
            }
            self.logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
            
        } catch HostedUIError.signOutURI {
            let error = AuthenticationError.configuration(message: "Could not create logout URL")
            let event = SignOutEvent(eventType: .signedOutFailure(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
            return
        } catch {
            self.logVerbose("\(#fileID) Received error \(error)", environment: environment)
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

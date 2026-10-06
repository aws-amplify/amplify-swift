//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AuthenticationServices
import Foundation

/// - Note: `final` and `@unchecked Sendable` to satisfy `Action`'s `Sendable` requirement.
package final class ShowHostedUISignOut: NSObject, Action, @unchecked Sendable {

    package let identifier: String = "ShowHostedUISignOut"

    package let signOutEvent: SignOutEventData
    package let signInData: SignedInData

    package init(signOutEvent: SignOutEventData, signInData: SignedInData) {
        self.signInData = signInData
        self.signOutEvent = signOutEvent
    }

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIEnvironment = environment.hostedUIEnvironment
        else {
            let error = HostedUIError.pluginConfiguration(AuthPluginErrorConstants.configurationError)
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
            return
        }
        let hostedUIConfig = hostedUIEnvironment.configuration
        guard let callbackURL = URL(string: hostedUIConfig.oauth.signOutRedirectURI),
              let callbackURLScheme = callbackURL.scheme
        else {
            await sendEvent(with: HostedUIError.signOutRedirectURI, dispatcher: dispatcher, environment: environment)
            return
        }

        do {
            let logoutURL = try HostedUIRequestHelper.createSignOutURL(configuration: hostedUIConfig)
            let sessionAdapter = hostedUIEnvironment.hostedUISessionFactory()
            _ = try await sessionAdapter.showHostedUI(
                url: logoutURL,
                callbackScheme: callbackURLScheme,
                // The sign-in's own choice, so the logout sees the cookie jar the sign-in used.
                // `InitiateSignOut` branches on the state's copy of the sign-in and only comes here for one that
                // shared the browser's cookies; `signInData` is the stored copy of the same sign-in, whose method
                // a refresh keeps (`RefreshUserPoolTokens`). So this is `false` whenever it runs. Were the stored
                // record ever a different sign-in, the logout would follow the stored one: the session it clears.
                inPrivate: signInData.hostedUIPrefersPrivateSession ?? false,
                presentationAnchor: signOutEvent.presentationAnchor
            )
            await sendEvent(with: nil, dispatcher: dispatcher, environment: environment)
        } catch HostedUIError.cancelled {
            if signInData.isRefreshTokenExpired == true {
                logVerbose("\(#fileID) Received user cancelled error, but session is expired and continue signing out.", environment: environment)
                await sendEvent(with: nil, dispatcher: dispatcher, environment: environment)
            } else {
                logVerbose("\(#fileID) Received error \(HostedUIError.cancelled)", environment: environment)
                await sendEvent(with: HostedUIError.cancelled, dispatcher: dispatcher, environment: environment)
            }
        } catch {
            logVerbose("\(#fileID) Received error \(error)", environment: environment)
            await sendEvent(with: error, dispatcher: dispatcher, environment: environment)
        }
    }

    package func sendEvent(
        with error: Error?,
        dispatcher: EventDispatcher,
        environment: Environment
    ) async {

        let event: SignOutEvent
        if let hostedUIInternalError = error as? HostedUIError {
           event = SignOutEvent(eventType: .hostedUISignOutError(hostedUIInternalError))
        } else if let error = error as? EngineAuthErrorConvertible {
            event = getEvent(for: EngineHostedUISignOutFailure(error: error.engineError))
        } else if let error {
            let serviceError = EngineAuthError.service(
                "HostedUI failed with error",
                "",
                error
            )
            event = getEvent(for: EngineHostedUISignOutFailure(error: serviceError))
        } else {
            event = getEvent(for: nil)
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

    private func getEvent(for hostedUIError: EngineHostedUISignOutFailure?) -> SignOutEvent {
        if signOutEvent.globalSignOut {
            return SignOutEvent(eventType: .signOutGlobally(
                signInData,
                hostedUIError: hostedUIError
            ))
        } else {
            return SignOutEvent(eventType: .revokeToken(
                signInData,
                hostedUIError: hostedUIError
            ))
        }
    }
}

extension ShowHostedUISignOut: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInData": signInData.debugDictionary,
            "signOutEvent": signOutEvent.debugDictionary
        ]
    }
}

package extension ShowHostedUISignOut {
    override var debugDescription: String {
        debugDictionary.debugDescription
    }
}

package extension SignedInData {

    /// The hosted-UI sign-in's `preferPrivateSession`, or `nil` for a sign-in that did not use the hosted UI.
    var hostedUIPrefersPrivateSession: Bool? {
        guard case .hostedUI(let options) = signInMethod else {
            return nil
        }
        return options.preferPrivateSession
    }

    /// Whether signing this session out presents the browser, to clear the hosted UI's cookie: only after a
    /// hosted-UI sign-in that shared the browser's cookies. The same test as `InitiateSignOut`'s branch, before
    /// any skip the caller asks for. A private sign-in left no shared cookie, so its sign-out shows nothing.
    var signOutPresentsBrowser: Bool {
        hostedUIPrefersPrivateSession == false
    }
}

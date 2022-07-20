//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import CryptoKit

struct InitializeHostedUISignIn: Action {

    var identifier: String = "InitializeHostedUISignIn"

    let options: HostedUIOptions

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

        guard let presentationAnchor = options.presentationAnchor else {
            fatalError("""
        Should not happen, initialize hostedUISignIn should always start with presentationanchor
        """)
        }

        let hostedUIConfig = hostedUIEnvironment.configuration
        let randomGenerator = hostedUIEnvironment.randomStringFactory()
        let state = randomGenerator.generateUUID()
        guard let proofKey = randomGenerator.generateRandom(byteSize: 32) else {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(.proofCalculation)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        do {
            let url = try HostedUIRequestHelper.createSignInURL(state: state,
                                                                proofKey: proofKey,
                                                                configuration: hostedUIConfig,
                                                                options: options)
            let signInData = HostedUISigningInState(signInURL: url,
                                                    state: state,
                                                    codeChallenge: proofKey,
                                                    presentationAnchor: presentationAnchor,
                                                    options: options)
            let event = HostedUIEvent(eventType: .showHostedUI(signInData))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch let error as HostedUIError {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(error)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        } catch {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(.signInURI)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }
    }
}

extension InitializeHostedUISignIn: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeHostedUISignIn: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

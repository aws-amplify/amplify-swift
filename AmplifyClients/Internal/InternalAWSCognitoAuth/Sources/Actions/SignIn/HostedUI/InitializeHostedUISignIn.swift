//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CryptoKit
import Foundation

package struct InitializeHostedUISignIn: Action {

    package var identifier: String = "InitializeHostedUISignIn"

    package let options: HostedUIOptions

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIEnvironment = environment.hostedUIEnvironment
        else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = AuthenticationEvent(eventType: .error(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
            return
        }

        await initializeHostedUI(
            presentationAnchor: options.presentationAnchor,
            environment: environment,
            hostedUIEnvironment: hostedUIEnvironment,
            dispatcher: dispatcher
        )
    }

    package func initializeHostedUI(
        presentationAnchor: EnginePresentationAnchor?,
        environment: AuthEnvironment,
        hostedUIEnvironment: HostedUIEnvironment,
        dispatcher: EventDispatcher
    ) async {
        let username = "unknown"
        let hostedUIConfig = hostedUIEnvironment.configuration
        let randomGenerator = hostedUIEnvironment.randomStringFactory()
        let state = randomGenerator.generateUUID()
        guard let proofKey = randomGenerator.generateRandom(byteSize: 32) else {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(.proofCalculation)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
            return
        }

        do {
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: environment.credentialsClient
            )
            let encodedData = await CognitoUserPoolASF.encodedContext(
                username: username,
                asfDeviceId: asfDeviceId,
                asfClient: environment.cognitoUserPoolASFFactory(),
                userPoolConfiguration: environment.userPoolConfiguration
            )

            let url = try HostedUIRequestHelper.createSignInURL(
                state: state,
                proofKey: proofKey,
                userContextData: encodedData,
                configuration: hostedUIConfig,
                options: options
            )
            let signInData = HostedUISigningInState(
                signInURL: url,
                state: state,
                codeChallenge: proofKey,
                presentationAnchor: presentationAnchor,
                options: options
            )
            let event = HostedUIEvent(eventType: .showHostedUI(signInData))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch let error as HostedUIError {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(error)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
            return
        } catch {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(.signInURI)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
            return
        }
    }
}

extension InitializeHostedUISignIn: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeHostedUISignIn: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

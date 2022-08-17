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

        Task {
            let signInEvent = await createSignInEvent(from: environment)
            logVerbose("\(#fileID) Sending event \(signInEvent.type)", environment: environment)
            dispatcher.send(signInEvent)
        }
    }

    func createSignInEvent(from environment: Environment) async -> SignInEvent {

        guard let authEnvironment = environment as? AuthEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let event = SignInEvent(eventType: .throwAuthError(.configuration(message: message)))
            return event
        }

        let userPoolConfiguration = authEnvironment.userPoolConfiguration
        let authFlowFromConfig = userPoolConfiguration.authFlowType

        var deviceMetadata = DeviceMetadata.noData
        if let username = signInEventData.username {
            deviceMetadata = await getDeviceMetadata(
                for: environment,
                with: username)
        }

        let event: SignInEvent
        switch signInEventData.signInMethod {

        case .apiBased(let authflowType):
            if authflowType != .unknown {
                event = signInEvent(for: authflowType, with: deviceMetadata)
            } else {
                event = signInEvent(for: authFlowFromConfig, with: deviceMetadata)
            }
        case .hostedUI(let hostedUIOptions):
            event = .init(eventType: .initiateHostedUISignIn(hostedUIOptions))
        case .unknown:
            event = signInEvent(for: authFlowFromConfig, with: deviceMetadata)
        }

        return event
    }

    func signInEvent(for authflow: AuthFlowType,
                     with deviceMetadata: DeviceMetadata) -> SignInEvent {
        switch authflow {
        case .userSRP:
            return .init(eventType: .initiateSignInWithSRP(signInEventData, deviceMetadata))
        case .custom:
            return .init(eventType: .initiateCustomSignIn(signInEventData, deviceMetadata))
        case .customWithSRP:
            return .init(eventType: .initiateCustomSignInWithSRP(signInEventData, deviceMetadata))
        case .userPassword:
            return .init(eventType: .initiateMigrateAuth(signInEventData, deviceMetadata))
        case .unknown:
            // Default to SRP signIn if we could not figure out the authflow type
            return .init(eventType: .initiateSignInWithSRP(signInEventData, deviceMetadata))
        }
    }

    func getDeviceMetadata(
        for environment: Environment,
        with username: String) async -> DeviceMetadata {
            let credentialStoreClient = (environment as? AuthEnvironment)?.credentialStoreClientFactory()
            do {
                let data = try await credentialStoreClient?.fetchData(type: .deviceMetadata(username: username))

                if case .deviceMetadata(let fetchedMetadata, _) = data {
                    return fetchedMetadata
                } else {
                    return .noData
                }
            } catch {
                logError("Unable to fetch device metadata with error: \(error)",
                         environment: environment)
                return .noData
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

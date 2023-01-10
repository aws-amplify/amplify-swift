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

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let signInEvent = await createSignInEvent(from: environment)
        logVerbose("\(#fileID) Sending event \(signInEvent.type)", environment: environment)
        await dispatcher.send(signInEvent)
    }

    func createSignInEvent(from environment: Environment) async -> SignInEvent {

        guard let authEnvironment = environment as? AuthEnvironment,
              authEnvironment.configuration.getUserPoolConfiguration() != nil else {
            let message = AuthPluginErrorConstants.configurationError
            let event = SignInEvent(eventType: .throwAuthError(.configuration(message: message)))
            return event
        }
        
        var deviceMetadata = DeviceMetadata.noData
        if let username = signInEventData.username {
            deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: username,
                environment: environment)
        }

        let event: SignInEvent
        switch signInEventData.signInMethod {

        case .apiBased(let authflowType):
            event = signInEvent(for: authflowType, with: deviceMetadata)
        case .hostedUI(let hostedUIOptions):
            event = .init(eventType: .initiateHostedUISignIn(hostedUIOptions))
        }

        return event
    }

    func signInEvent(for authflow: AuthFlowType,
                     with deviceMetadata: DeviceMetadata) -> SignInEvent {
        switch authflow {
        case .userSRP:
            return .init(eventType: .initiateSignInWithSRP(signInEventData, deviceMetadata))
        case .customWithoutSRP:
            return .init(eventType: .initiateCustomSignIn(signInEventData, deviceMetadata))
        case .customWithSRP:
            return .init(eventType: .initiateCustomSignInWithSRP(signInEventData, deviceMetadata))
        case .userPassword:
            return .init(eventType: .initiateMigrateAuth(signInEventData, deviceMetadata))
        // Using `custom` here to keep the legacy behaviour from V1 intact,
        // which is custom flow type will start with SRP_A flow.
        case .custom:
            return .init(eventType: .initiateCustomSignInWithSRP(signInEventData, deviceMetadata))

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

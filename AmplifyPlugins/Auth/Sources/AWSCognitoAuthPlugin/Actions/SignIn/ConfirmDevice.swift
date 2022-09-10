//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider
import Foundation

struct ConfirmDevice: Action {

    var identifier: String = "ConfirmDevice"

    let signedInData: SignedInData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let userpoolEnv = try environment.userPoolEnvironment()
            let client = try userpoolEnv.cognitoUserPoolFactory()
            let srpEnv = try environment.srpEnvironment()
            guard case .metadata(let deviceMetadata) = signedInData.deviceMetadata else {
                let event = SignInEvent(eventType: .finalizeSignIn(signedInData))
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                await dispatcher.send(event)
                return
            }

            let srpClient = try SRPSignInHelper.srpClient(srpEnv)

            let passwordVerifier = srpClient.generateDevicePasswordVerifier(
                deviceGroupKey: deviceMetadata.deviceGroupKey,
                deviceKey: deviceMetadata.deviceKey,
                password: deviceMetadata.deviceSecret)

            let deviceName = DeviceInfo.current.name

            let base64EncodedVerifier = passwordVerifier.passwordVerifier.base64EncodedString()
            let base64EncodedSalt = passwordVerifier.salt.base64EncodedString()
            let verifier = CognitoIdentityProviderClientTypes.DeviceSecretVerifierConfigType(
                passwordVerifier: base64EncodedVerifier,
                salt: base64EncodedSalt)
            let input = ConfirmDeviceInput(
                accessToken: signedInData.cognitoUserPoolTokens.accessToken,
                deviceKey: deviceMetadata.deviceKey,
                deviceName: deviceName,
                deviceSecretVerifierConfig: verifier)

            let response = try await client.confirmDevice(input: input)
            logVerbose("Successfully completed device confirmation with result \(response)",
                       environment: environment)

            // Save the device metadata to keychain
            let credentialStoreClient = (environment as? AuthEnvironment)?.credentialStoreClientFactory()
            _ = try await credentialStoreClient?.storeData(
                data: .deviceMetadata(signedInData.deviceMetadata, signedInData.userName))
            logVerbose("Successfully stored the device metadata in the keychain ",
                       environment: environment)
        } catch {
            logError("Failed to confirm the device \(error)",
                     environment: environment)
        }

        let event = SignInEvent(eventType: .finalizeSignIn(signedInData))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)

    }
}

extension ConfirmDevice: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "newDeviceMetadata": signedInData.deviceMetadata
        ]
    }
}

extension ConfirmDevice: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyBigInteger
import AWSCognitoIdentityProvider
import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct ConfirmDevice: Action {

    var identifier: String = "ConfirmDevice"

    let signedInData: SignedInData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        Task {
            do {
                let userpoolEnv = try environment.userPoolEnvironment()
                let client = try userpoolEnv.cognitoUserPoolFactory()
                let srpEnv = try environment.srpEnvironment()
                guard case .metadata(let deviceMetadata) = signedInData.deviceMetadata else {
                    let event = SignInEvent(eventType: .finalizeSignIn(signedInData))
                    logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                    return
                }

                let srpClient = try SRPSignInHelper.srpClient(srpEnv)

                let devicePasswordVerifierConfig = srpClient.generateDevicePasswordVerifier(
                    deviceGroupKey: deviceMetadata.deviceGroupKey,
                    deviceKey: deviceMetadata.deviceKey,
                    password: deviceMetadata.deviceSecret)

                let verifierData = Data(AmplifyBigIntHelper.getSignedData(
                    num: devicePasswordVerifierConfig.passwordVerifier))
                let saltData = Data(AmplifyBigIntHelper.getSignedData(
                    num: devicePasswordVerifierConfig.salt))

                let base64EncodedVerifier = verifierData.base64EncodedString()
                let base64EncodedSalt = saltData.base64EncodedString()
                let verifier = CognitoIdentityProviderClientTypes.DeviceSecretVerifierConfigType(
                    passwordVerifier: base64EncodedVerifier,
                    salt: base64EncodedSalt)
                let input = ConfirmDeviceInput(
                    accessToken: signedInData.cognitoUserPoolTokens.accessToken,
                    deviceKey: deviceMetadata.deviceKey,
                    deviceName: getCurrentDeviceName(),
                    deviceSecretVerifierConfig: verifier)

                let response = try await client.confirmDevice(input: input)
                logVerbose("Successfully completed device confirmation with result \(response)",
                           environment: environment)

                // Save the device metadata to keychain
                let credentialStoreClient = (environment as? AuthEnvironment)?.credentialStoreClientFactory()
                let _ = try await credentialStoreClient?.storeData(
                    data: .deviceMetadata(signedInData.deviceMetadata, signedInData.userName))
                logVerbose("Successfully stored the device metadata in the keychain ",
                           environment: environment)
            }
            catch {
                logError("Failed to confirm the device \(error)",
                         environment: environment)
            }


            let event = SignInEvent(eventType: .finalizeSignIn(signedInData))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }

    }

    func getCurrentDeviceName() -> String {
#if canImport(UIKit)
        return UIDevice.current.name
#else
        // TODO: Get a device name implementation for all apple platforms
        return ""
#endif
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



//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import CryptoKit
import AWSCognitoIdentityProvider

struct InitiateAuthSRP: Action {
    let identifier = "InitiateAuthSRP"

    let username: String
    let password: String
    let authFlowType: AuthFlowType
    let deviceMetadata: DeviceMetadata
    let clientMetadata: [String: String]

    init(username: String,
         password: String,
         authFlowType: AuthFlowType = .userSRP,
         deviceMetadata: DeviceMetadata = .noData,
         clientMetadata: [String: String] = [:]) {
        self.username = username
        self.password = password
        self.authFlowType = authFlowType
        self.deviceMetadata = deviceMetadata
        self.clientMetadata = clientMetadata
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        Task {
            do {
                let srpEnv = try environment.srpEnvironment()
                let userPoolEnv = try environment.userPoolEnvironment()
                let nHexValue = srpEnv.srpConfiguration.nHexValue
                let gHexValue = srpEnv.srpConfiguration.gHexValue

                let srpClient = try SRPSignInHelper.srpClient(srpEnv)
                let srpKeyPair = srpClient.generateClientKeyPair()

                let srpStateData = SRPStateData(
                    username: username,
                    password: password,
                    NHexValue: nHexValue,
                    gHexValue: gHexValue,
                    srpKeyPair: srpKeyPair,
                    deviceMetadata: deviceMetadata,
                    clientTimestamp: Date())

                let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                    for: username,
                    environment: environment as! AuthEnvironment)
                let request = InitiateAuthInput.srpInput(
                    username: username,
                    publicSRPAHexValue: srpKeyPair.publicKeyHexValue,
                    authFlowType: authFlowType,
                    clientMetadata: clientMetadata,
                    asfDeviceId: asfDeviceId,
                    deviceMetadata: deviceMetadata,
                    environment: userPoolEnv)

                let responseEvent = try await sendRequest(request: request,
                                                          environment: userPoolEnv,
                                                          srpStateData: srpStateData)
                logVerbose("\(#fileID) Sending event \(responseEvent)", environment: srpEnv)
                dispatcher.send(responseEvent)

            } catch let error as SignInError {
                logVerbose("\(#fileID) Raised error \(error)", environment: environment)
                let event = SignInEvent(eventType: .throwAuthError(error))
                dispatcher.send(event)
            } catch {
                logVerbose("\(#fileID) Caught error \(error)", environment: environment)
                let authError = SignInError.service(error: error)
                let event = SignInEvent(
                    eventType: .throwAuthError(authError)
                )
                dispatcher.send(event)
            }
        }

    }

    private func sendRequest(request: InitiateAuthInput,
                             environment: UserPoolEnvironment,
                             srpStateData: SRPStateData) async throws -> SignInEvent {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let response = try await cognitoClient.initiateAuth(input: request)
        logVerbose("\(#fileID) InitiateAuth response success", environment: environment)
        return SignInEvent(eventType: .respondPasswordVerifier(srpStateData, response))
    }
}

extension InitiateAuthSRP: DefaultLogger { }

extension InitiateAuthSRP: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.masked(),
            "password": password.redacted()
        ]
    }
}

extension InitiateAuthSRP: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

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

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let srpEnv = try environment.srpEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let nHexValue = srpEnv.srpConfiguration.nHexValue
            let gHexValue = srpEnv.srpConfiguration.gHexValue

            let srpClient = try SRPSignInHelper.srpClient(srpEnv)
            let srpKeyPair = srpClient.generateClientKeyPair()

            let srpStateData = SRPStateData(username: username,
                                            password: password,
                                            NHexValue: nHexValue,
                                            gHexValue: gHexValue,
                                            srpKeyPair: srpKeyPair,
                                            clientTimestamp: Date())
            let request = request(environment: userPoolEnv,
                                  publicHexValue: srpKeyPair.publicKeyHexValue)

            try sendRequest(request: request,
                            environment: userPoolEnv,
                            srpStateData: srpStateData) { responseEvent in
                logVerbose("\(#fileID) Sending event \(responseEvent)", environment: srpEnv)
                dispatcher.send(responseEvent)

            }

        } catch let error as SRPSignInError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = SRPSignInEvent(eventType: .throwAuthError(error))
            dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let authError = SRPSignInError.service(error: error)
            let event = SRPSignInEvent(
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
        }
    }

    private func request(environment: UserPoolEnvironment,
                         publicHexValue: String) -> InitiateAuthInput {
        let userPoolClientId = environment.userPoolConfiguration.clientId
        var authParameters = [
            "USERNAME": username,
            "SRP_A": publicHexValue
        ]

        if let clientSecret = environment.userPoolConfiguration.clientSecret {
            let clientSecretHash = SRPSignInHelper.clientSecretHash(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
            authParameters["SECRET_HASH"] = clientSecretHash
        }

        if let deviceId = Self.getDeviceId() {
            authParameters["DEVICE_KEY"] = deviceId
        }

        return InitiateAuthInput(analyticsMetadata: nil,
                                 authFlow: .userSrpAuth,
                                 authParameters: authParameters,
                                 clientId: userPoolClientId,
                                 clientMetadata: nil,
                                 userContextData: nil)
    }

    private func sendRequest(request: InitiateAuthInput,
                             environment: UserPoolEnvironment,
                             srpStateData: SRPStateData,
                             callback: @escaping (SRPSignInEvent) -> Void) throws {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)

        Task {
            let event: SRPSignInEvent!
            do {
                let response = try await cognitoClient.initiateAuth(input: request)
                logVerbose("\(#fileID) InitiateAuth response success", environment: environment)
                event = SRPSignInEvent(eventType: .respondPasswordVerifier(srpStateData, response))
            } catch {
                let authError = SRPSignInError.service(error: error)
                event = SRPSignInEvent(eventType: .throwAuthError(authError))
            }
            callback(event)
        }
    }

    // TODO: Implement this
    private static func getDeviceId() -> String? {
        return nil
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

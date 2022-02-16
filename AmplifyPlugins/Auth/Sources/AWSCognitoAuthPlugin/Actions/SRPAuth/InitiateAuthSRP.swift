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
                 environment: Environment)
    {

        Amplify.Logging.verbose("Starting execution \(#fileID)")
        do {
            let environment = try SRPSignInHelper.srpEnvironment(environment)
            let nHexValue = environment.srpConfiguration.nHexValue
            let gHexValue = environment.srpConfiguration.gHexValue

            let srpClient = try SRPSignInHelper.srpClient(environment)
            let srpKeyPair = srpClient.generateClientKeyPair()

            let srpStateData = SRPStateData(username: username,
                                            password: password,
                                            NHexValue: nHexValue,
                                            gHexValue: gHexValue,
                                            srpKeyPair: srpKeyPair,
                                            clientTimestamp: Date())
            let request = request(environment: environment,
                                  publicHexValue: srpKeyPair.publicKeyHexValue)

            try sendRequest(request: request,
                            environment: environment,
                            srpStateData: srpStateData) { responseEvent in
                dispatcher.send(responseEvent)
                Amplify.Logging.verbose("sending event #file")
            }

        } catch let error as SRPSignInError {
            Amplify.Logging.verbose("SRPSignInError \(error) #file")
            let event = SRPSignInEvent(eventType: .throwAuthError(error))
            dispatcher.send(event)
        } catch {
            Amplify.Logging.verbose("Caught error \(error) #file")
            let authError = SRPSignInError.service(error: error)
            let event = SRPSignInEvent(
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
        }
    }

    private func request(environment: SRPAuthEnvironment,
                         publicHexValue: String) -> InitiateAuthInput
    {
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
                     environment: SRPAuthEnvironment,
                     srpStateData: SRPStateData,
                     callback: @escaping (SRPSignInEvent) -> Void) throws
    {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        Amplify.Logging.verbose("Starting initiateAuth #file")
        cognitoClient.initiateAuth(input: request) { result in
            Amplify.Logging.verbose("initiateAuth response received #file")
            let event: SRPSignInEvent!
            switch result {
            case .success(let response):
                event = SRPSignInEvent(
                    eventType: .respondPasswordVerifier(srpStateData, response)
                )
            case .failure(let error):
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

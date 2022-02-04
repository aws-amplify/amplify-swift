//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import CryptoKit

struct InitiateAuthSRP: Action {
    let identifier = "InitiateAuthSRP"

    let username: String
    let password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        guard let environment = environment as? SRPAuthEnvironment else {
            let authError = SRPSignInError.configuration(message: "Environment configured incorrectly")
            let event = SRPSignInEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }

        guard let srpClient = try? environment.srpClientFactory(environment.srpConfiguration.nHexValue,
                                                                environment.srpConfiguration.gHexValue)
        else {
            fatalError("TODO: Replace this with a dispatcher.send()")
        }

        let srpKeyPair = srpClient.generateClientKeyPair()

        let clientTimeStamp = Date()
        let srpStateData = SRPStateData(username: username,
                                        password: password,
                                        NHexValue: environment.srpConfiguration.nHexValue,
                                        gHexValue: environment.srpConfiguration.gHexValue,
                                        srpKeyPair: srpKeyPair,
                                        clientTimestamp: clientTimeStamp)

        let userPoolClientId = environment.userPoolConfiguration.clientId
        let publicHexValue = srpKeyPair.publicKeyHexValue
        var authParameters = [
            "USERNAME": username,
            "SRP_A": publicHexValue
        ]

        if let clientSecret = environment.userPoolConfiguration.clientSecret {
            let clientSecretHash = InitiateAuthSRP.getClientSecretHashBase64String(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
            authParameters["SECRET_HASH"] = clientSecretHash
        }

        if let deviceId = InitiateAuthSRP.getDeviceId() {
            authParameters["DEVICE_KEY"] = deviceId
        }

        let input = InitiateAuthInput(analyticsMetadata: nil,
                                      authFlow: .userSrpAuth,
                                      authParameters: authParameters,
                                      clientId: userPoolClientId,
                                      clientMetadata: nil,
                                      userContextData: nil)
        do {
            let client = try environment.cognitoUserPoolFactory()
            timer.note("### Starting initiateAuth")
            client.initiateAuth(input: input) { result in
                timer.note("### initiateAuth response received")
                switch result {
                case .success(let response):
                    let event = SRPSignInEvent(
                        id: environment.eventIDFactory(),
                        eventType: .respondPasswordVerifier(srpStateData, response),
                        time: Date()
                    )
                    dispatcher.send(event)
                case .failure(let error):
                    let authError = SRPSignInError.service(error: error)
                    let event = SRPSignInEvent(
                        id: environment.eventIDFactory(),
                        eventType: .throwAuthError(authError)
                    )
                    dispatcher.send(event)
                }
                timer.stop("### sending SRPSignInEvent.initiateAuthResponseReceived")
            }
        } catch {
            let authError = SRPSignInError.service(error: error)
            let event = SRPSignInEvent(
                id: environment.eventIDFactory(),
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
        }
    }

    private static func getClientSecretHashBase64String(
        username: String,
        userPoolClientId: String,
        clientSecret: String
    ) -> String {
        let clientSecretData = clientSecret.data(using: .utf8)!
        let clientSecretByteArray = [UInt8](clientSecretData)
        let key = SymmetricKey(data: clientSecretByteArray)

        let clientData = (username + userPoolClientId).data(using: .utf8)!

        let mac = HMAC<SHA256>.authenticationCode(for: clientData, using: key)
        let macBase64 = Data(mac).base64EncodedString()
        return macBase64
    }

    // TODO: Implement this
    private static func getDeviceId() -> String? {
        return nil
    }

}

extension InitiateAuthSRP: DefaultLogger { }

extension InitiateAuthSRP: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.masked(),
            "password": password.redacted()
        ]
    }
}

extension InitiateAuthSRP: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}

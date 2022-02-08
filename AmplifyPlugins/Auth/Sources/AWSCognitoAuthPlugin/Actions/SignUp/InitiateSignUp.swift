//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit
import AWSCognitoIdentityProvider
import Amplify

struct InitiateSignUp: Action {
    let identifier = "InitiateSignUp"

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
        guard let environment = environment as? UserPoolEnvironment else {
            let authError = AuthenticationError.configuration(message: "Environment configured incorrectly")
            let event = SignUpEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try environment.cognitoUserPoolFactory()
        } catch {
            let authError = AuthenticationError.configuration(message: "Failed to get CognitoUserPool client: \(error)")
            let event = SignUpEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }

        let input = SignUpInput(username: username, password: password, userPoolConfiguration: environment.userPoolConfiguration)
        timer.note("### Starting signUp")
        client.signUp(input: input) { result in
            timer.note("### signUp response received")
            let event: SignUpEvent
            switch result {
            case .success(let response):
                event = SignUpEvent(eventType: .initiateSignUpSuccess(username: username, signUpResponse: response))
            case .failure(let error):
                // error is SignUpOutputError
                // https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_SignUp.html#API_SignUp_Errors
                let error = SignUpError.service(error: error)
                event = SignUpEvent(eventType: .initiateSignUpFailure(error: error))
            }
            dispatcher.send(event)
            timer.stop("### sending SignUpEvent.initiateSignUpResponseReceived")
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif

extension SignUpInput {
    init(username: String, password: String, userPoolConfiguration: UserPoolConfigurationData) {
        let secretHash = Self.calculateSecretHash(username: username, userPoolConfiguration: userPoolConfiguration)
        let validationData = Self.getValidationData()

        self.init(clientId: userPoolConfiguration.clientId,
                  password: password,
                  secretHash: secretHash,
                  username: username,
                  validationData: validationData)
    }

    private static func calculateSecretHash(username: String, userPoolConfiguration: UserPoolConfigurationData) -> String? {
        guard let clientSecret = userPoolConfiguration.clientSecret,
              !clientSecret.isEmpty,
              let clientSecretData = clientSecret.data(using: .utf8) else {
            return nil
        }

        guard let data = (username + userPoolConfiguration.clientId).data(using: .utf8) else {
            return nil
        }

        let clientSecretByteArray = [UInt8](clientSecretData)
        let key = SymmetricKey(data: clientSecretByteArray)

        let mac = HMAC<SHA256>.authenticationCode(for: data, using: key)
        let macBase64 = Data(mac).base64EncodedString()
        return macBase64
    }

    private static func getValidationData() -> [CognitoIdentityProviderClientTypes.AttributeType]? {
        cognitoValidationData
    }

    private static var cognitoValidationData: [CognitoIdentityProviderClientTypes.AttributeType]? {
        #if canImport(UIKit)
        let device = UIDevice.current
        let bundle = Bundle.main
        let bundleVersion = bundle.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as? String
        let bundleShortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        return [
            .init(name: "cognito:iOSVersion", value: device.systemVersion),
            .init(name: "cognito:systemName", value: device.systemName),
            .init(name: "cognito:deviceName", value: device.name),
            .init(name: "cognito:model", value: device.model),
            .init(name: "cognito:idForVendor", value: device.identifierForVendor?.uuidString ?? ""),
            .init(name: "cognito:bundleId", value: bundle.bundleIdentifier),
            .init(name: "cognito:bundleVersion", value: bundleVersion ?? ""),
            .init(name: "cognito:bundleShortV", value: bundleShortVersion ?? "")
        ]
        #else
        return nil
        #endif
    }
}

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

    let signUpEventData: SignUpEventData

    init(signUpEventData: SignUpEventData) {
        self.signUpEventData = signUpEventData
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        logVerbose("Starting execution", environment: environment)
        guard let environment = environment as? UserPoolEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthenticationError.configuration(message: message)
            let event = SignUpEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try createIdentityProviderClient(key: signUpEventData.key,
                                                      environment: environment)
        } catch {
            let authError = AuthenticationError.configuration(message: "Failed to get CognitoUserPool client: \(error)")
            let event = SignUpEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }

        let input = SignUpInput(username: signUpEventData.username,
                                password: signUpEventData.password,
                                attributes: signUpEventData.attributes,
                                userPoolConfiguration: environment.userPoolConfiguration)
        logVerbose("Starting signup", environment: environment)
        client.signUp(input: input) { result in
            logVerbose("SignUp received", environment: environment)
            let event: SignUpEvent
            switch result {
            case .success(let response):
                event = SignUpEvent(eventType: .initiateSignUpSuccess(
                    username: signUpEventData.username,
                    signUpResponse: response)
                )
            case .failure(let error):
                let error = SignUpError.service(error: error)
                event = SignUpEvent(eventType: .initiateSignUpFailure(error: error))
            }
            logVerbose("Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif

extension SignUpInput {
    typealias CognitoAttributeType = CognitoIdentityProviderClientTypes.AttributeType
    init(username: String,
         password: String,
         attributes: [String: String],
         userPoolConfiguration: UserPoolConfigurationData)
    {
        let secretHash = Self.calculateSecretHash(username: username, userPoolConfiguration: userPoolConfiguration)
        let validationData = Self.getValidationData()
        let convertedAttributes = Self.convertAttributes(attributes)
        self.init(clientId: userPoolConfiguration.clientId,
                  password: password,
                  secretHash: secretHash,
                  userAttributes: convertedAttributes,
                  username: username,
                  validationData: validationData)
    }

    private static func calculateSecretHash(username: String, userPoolConfiguration: UserPoolConfigurationData) -> String? {
        guard let clientSecret = userPoolConfiguration.clientSecret,
              !clientSecret.isEmpty,
              let clientSecretData = clientSecret.data(using: .utf8)
        else {
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

    private static func convertAttributes(_ attributes: [String: String]) -> [CognitoIdentityProviderClientTypes.AttributeType] {

     return attributes.reduce(into: [CognitoIdentityProviderClientTypes.AttributeType]()) {
            $0.append(CognitoIdentityProviderClientTypes.AttributeType(name: $1.key,
                                                                       value: $1.value))
        }
    }
}

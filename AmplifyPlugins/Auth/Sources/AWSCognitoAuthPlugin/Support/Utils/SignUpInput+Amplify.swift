//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
#if canImport(UIKit)
import UIKit
#endif

extension SignUpInput {
    typealias CognitoAttributeType = CognitoIdentityProviderClientTypes.AttributeType
    init(username: String,
         password: String,
         clientMetadata: [String: String]?,
         validationData: [String: String]?,
         attributes: [String: String],
         asfDeviceId: String? = nil,
         environment: UserPoolEnvironment) {

        let configuration = environment.userPoolConfiguration
        let secretHash = Self.calculateSecretHash(username: username,
                                                  userPoolConfiguration: configuration)
        let validationData = Self.getValidationData(with: validationData)
        let convertedAttributes = Self.convertAttributes(attributes)
        var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
        if let asfDeviceId = asfDeviceId,
           let encodedData = CognitoUserPoolASF.encodedContext(
            username: username,
            asfDeviceId: asfDeviceId,
            asfClient: environment.cognitoUserPoolASFFactory(),
            userPoolConfiguration: environment.userPoolConfiguration) {
            userContextData = .init(encodedData: encodedData)
        }
        let analyticsMetadata = environment
            .cognitoUserPoolAnalyticsHandlerFactory()
            .analyticsMetadata()
        self.init(analyticsMetadata: analyticsMetadata,
                  clientId: configuration.clientId,
                  clientMetadata: clientMetadata,
                  password: password,
                  secretHash: secretHash,
                  userAttributes: convertedAttributes,
                  userContextData: userContextData,
                  username: username,
                  validationData: validationData)
    }

    private static func calculateSecretHash(
        username: String,
        userPoolConfiguration: UserPoolConfigurationData) -> String? {
            let userPoolClientId = userPoolConfiguration.clientId
            if let clientSecret = userPoolConfiguration.clientSecret {

                return SRPSignInHelper.clientSecretHash(
                    username: username,
                    userPoolClientId: userPoolClientId,
                    clientSecret: clientSecret
                )
            }
            return nil
        }

    private static func getValidationData(with devProvidedData: [String: String]?)
    -> [CognitoIdentityProviderClientTypes.AttributeType]? {

        if let devProvidedData = devProvidedData {
            return devProvidedData.compactMap { (key, value) in
                return CognitoIdentityProviderClientTypes.AttributeType(name: key, value: value)
            } + (cognitoValidationData ?? [])
        }
        return cognitoValidationData
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

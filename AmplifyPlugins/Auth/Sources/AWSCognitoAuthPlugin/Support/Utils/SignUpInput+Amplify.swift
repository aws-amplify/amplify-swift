//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#endif

extension SignUpInput {
    typealias CognitoAttributeType = CognitoIdentityProviderClientTypes.AttributeType
    init(username: String,
         password: String,
         clientMetadata: [String: String]?,
         validationData: [String: String]?,
         attributes: [String: String],
         asfDeviceId: String?,
         environment: UserPoolEnvironment) async {

        let configuration = environment.userPoolConfiguration
        let secretHash = ClientSecretHelper.calculateSecretHash(username: username,
                                                  userPoolConfiguration: configuration)
        let validationData = await Self.getValidationData(with: validationData)
        let convertedAttributes = Self.convertAttributes(attributes)
        var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
        if let asfDeviceId = asfDeviceId,
           let encodedData = await CognitoUserPoolASF.encodedContext(
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

    private static func getValidationData(with devProvidedData: [String: String]?)
    async -> [CognitoIdentityProviderClientTypes.AttributeType]? {

        if let devProvidedData = devProvidedData {
            return devProvidedData.compactMap { (key, value) in
                return CognitoIdentityProviderClientTypes.AttributeType(name: key, value: value)
            } + (await cognitoValidationData ?? [])
        }
        return await cognitoValidationData
    }

    private static var cognitoValidationData: [CognitoIdentityProviderClientTypes.AttributeType]? {
        get async {
            #if canImport(WatchKit)
            let device = WKInterfaceDevice.current()
            #elseif canImport(UIKit)
            let device = await UIDevice.current
            #endif

            #if canImport(WatchKit) || canImport(UIKit)
            let bundle = Bundle.main
            let bundleVersion = bundle.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as? String
            let bundleShortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            let systemVersion = await device.systemVersion
            let systemName = await device.systemName
            let name = await device.name
            let model = await device.model
            let idForVendor = await device.identifierForVendor?.uuidString ?? ""
            return [
                .init(name: "cognito:iOSVersion", value: systemVersion),
                .init(name: "cognito:systemName", value: systemName),
                .init(name: "cognito:deviceName", value: name),
                .init(name: "cognito:model", value: model),
                .init(name: "cognito:idForVendor", value: idForVendor),
                .init(name: "cognito:bundleId", value: bundle.bundleIdentifier),
                .init(name: "cognito:bundleVersion", value: bundleVersion ?? ""),
                .init(name: "cognito:bundleShortV", value: bundleShortVersion ?? "")
            ]
            #else
                    return nil
            #endif
        }
    }

    private static func convertAttributes(_ attributes: [String: String]) -> [CognitoIdentityProviderClientTypes.AttributeType] {

        return attributes.reduce(into: [CognitoIdentityProviderClientTypes.AttributeType]()) {
            $0.append(CognitoIdentityProviderClientTypes.AttributeType(name: $1.key,
                                                                       value: $1.value))
        }
    }
}

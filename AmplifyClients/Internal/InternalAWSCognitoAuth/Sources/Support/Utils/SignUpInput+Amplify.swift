//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

extension SignUpInput {
    package typealias CognitoAttributeType = CognitoIdentityProviderClientTypes.AttributeType
    package init(
        username: String,
        password: String?,
        clientMetadata: [String: String]?,
        validationData: [String: String]?,
        attributes: [String: String],
        asfDeviceId: String?,
        environment: UserPoolEnvironment
    ) async {

        let configuration = environment.userPoolConfiguration
        let secretHash = ClientSecretHelper.calculateSecretHash(
            username: username,
            userPoolConfiguration: configuration
        )
        let asfClient = environment.cognitoUserPoolASFFactory()
        let device = asfClient.device(id: asfDeviceId ?? "")
        let validationData = await Self.getValidationData(with: validationData, device: device)
        let convertedAttributes = Self.convertAttributes(attributes)
        var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
        if let asfDeviceId,
           let encodedData = await CognitoUserPoolASF.encodedContext(
               username: username,
               asfDeviceId: asfDeviceId,
               asfClient: asfClient,
               userPoolConfiguration: environment.userPoolConfiguration
           ) {
            userContextData = .init(encodedData: encodedData)
        }
        let analyticsMetadata = await environment
            .cognitoUserPoolAnalyticsHandlerFactory()
            .analyticsMetadata()
        self.init(
            analyticsMetadata: analyticsMetadata,
            clientId: configuration.clientId,
            clientMetadata: clientMetadata,
            password: password,
            secretHash: secretHash,
            userAttributes: convertedAttributes,
            userContextData: userContextData,
            username: username,
            validationData: validationData
        )
    }

    private static func getValidationData(
        with devProvidedData: [String: String]?,
        device: ASFDeviceBehavior
    ) async -> [CognitoIdentityProviderClientTypes.AttributeType]? {

        // swiftformat:disable all
        if let devProvidedData {
            return devProvidedData.compactMap { key, value in
                return CognitoIdentityProviderClientTypes.AttributeType(name: key, value: value)
            } + (await cognitoValidationData(device: device) ?? [])
        }
        // swiftformat:enable all
        return await cognitoValidationData(device: device)
    }

    /// The device's attributes, read from `device`: its `version`, `platform`, `name`, `model` and
    /// `thirdPartyId` are the system's version, system name, name, model and vendor ID
    /// (`EngineDeviceInfo`), on watchOS as on UIKit platforms.
    private static func cognitoValidationData(
        device: ASFDeviceBehavior
    ) async -> [CognitoIdentityProviderClientTypes.AttributeType]? {
        #if canImport(WatchKit) || canImport(UIKit)
        let bundle = Bundle.main
        let bundleVersion = bundle.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as? String
        let bundleShortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let systemVersion = await device.version
        let systemName = await device.platform
        let name = await device.name
        let model = await device.model
        let idForVendor = await device.thirdPartyId ?? ""
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

    private static func convertAttributes(_ attributes: [String: String]) -> [CognitoIdentityProviderClientTypes.AttributeType] {

        return attributes.reduce(into: [CognitoIdentityProviderClientTypes.AttributeType]()) {
            $0.append(CognitoIdentityProviderClientTypes.AttributeType(
                name: $1.key,
                value: $1.value
            ))
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CryptoKit
import Foundation

package struct CognitoUserPoolASF: AdvancedSecurityBehavior {

    package static let appNameKey = "ApplicationName"
    package static let targetSDKKey = "ApplicationTargetSdk"
    package static let appVersionKey = "ApplicationVersion"
    package static let deviceFingerPrintKey = "DeviceFingerprint"
    package static let deviceNameKey = "DeviceName"
    package static let buildTypeKey = "BuildType"
    package static let releaseVersionKey = "DeviceOsReleaseVersion"
    package static let deviceIdKey = "DeviceId"
    package static let thirdPartyDeviceIdKey = "ThirdPartyDeviceId"
    package static let platformKey = "Platform"
    package static let timezoneKey = "ClientTimezone"
    package static let deviceHeightKey = "ScreenHeightPixels"
    package static let deviceWidthKey = "ScreenWidthPixels"
    package static let deviceLanguageKey = "DeviceLanguage"
    package static let phoneTypeKey = "PhoneType"
    package static let asfVersion = "IOS20171114"

    package init() {}

    package func userContextData(
        for username: String = "unknown",
        deviceInfo: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior,
        configuration: UserPoolConfigurationData
    ) async throws -> String {

        let contextData = await prepareUserContextData(deviceInfo: deviceInfo, appInfo: appInfo)
        let payload = try prepareJsonPayload(
            username: username,
            contextData: contextData,
            userPoolId: configuration.poolId
        )
        let signature = try calculateSecretHash(
            contextJson: payload,
            clientId: configuration.clientId
        )
        let result = try prepareJsonResult(payload: payload, signature: signature)
        return result
    }

    package func prepareUserContextData(
        deviceInfo: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior
    ) async -> [String: String] {
        var build = "release"
#if DEBUG
        build = "debug"
#endif
        let fingerPrint = await deviceInfo.deviceInfo()
        var contextData: [String: String] = await [
            Self.targetSDKKey: appInfo.targetSDK,
            Self.appVersionKey: appInfo.version,
            Self.deviceNameKey: deviceInfo.name,
            Self.phoneTypeKey: deviceInfo.type,
            Self.deviceIdKey: deviceInfo.id,
            Self.releaseVersionKey: deviceInfo.version,
            Self.platformKey: deviceInfo.platform,
            Self.buildTypeKey: build,
            Self.timezoneKey: timeZoneOffet(),
            Self.deviceHeightKey: deviceInfo.height,
            Self.deviceWidthKey: deviceInfo.width,
            Self.deviceLanguageKey: deviceInfo.locale,
            Self.deviceFingerPrintKey: fingerPrint
        ]
        if let appName = appInfo.name {
            contextData[Self.appNameKey] = appName
        }
        if let thirdPartyDeviceIdKey = await deviceInfo.thirdPartyId {
            contextData[Self.thirdPartyDeviceIdKey] = thirdPartyDeviceIdKey
        }
        return contextData
    }

    package func prepareJsonPayload(
        username: String,
        contextData: [String: String],
        userPoolId: String
    ) throws -> String {
        let timestamp = String(format: "%lli", Int64(Date().timeIntervalSince1970 * 1_000))
        let payload = [
            "contextData": contextData,
            "username": username,
            "userPoolId": userPoolId,
            "timestamp": timestamp
        ] as [String: Any]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ASFError.stringConversion
        }
        return jsonString
    }

    package func timeZoneOffet(seconds: Int = TimeZone.current.secondsFromGMT()) -> String {

        let hours = seconds / 3_600
        let minutes = abs(seconds / 60) % 60
        return String(format: "%+.2d:%.2d", hours, minutes)
    }

    package func calculateSecretHash(contextJson: String, clientId: String) throws -> String {
        guard let keyData = clientId.data(using: .ascii) else {
            throw ASFError.hashKey
        }
        let key = SymmetricKey(data: keyData)
        let content = "\(Self.asfVersion)\(contextJson)"
        let data = Data(content.utf8)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: key)
        let hmacData = Data(hmac)
        return hmacData.base64EncodedString()
    }

    package func prepareJsonResult(payload: String, signature: String) throws -> String {
        let result = [
            "payload": payload,
            "version": Self.asfVersion,
            "signature": signature
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: result)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ASFError.stringConversion
        }
        let data = Data(jsonString.utf8)
        return data.base64EncodedString()
    }
}

package enum ASFError: Error {
    case stringConversion
    case dataConversion
    case hashKey
    case hashData
}

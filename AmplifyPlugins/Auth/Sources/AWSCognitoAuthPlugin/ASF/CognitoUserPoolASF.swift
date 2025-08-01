//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

struct CognitoUserPoolASF: AdvancedSecurityBehavior {

    static let appNameKey = "ApplicationName"
    static let targetSDKKey = "ApplicationTargetSdk"
    static let appVersionKey = "ApplicationVersion"
    static let deviceFingerPrintKey = "DeviceFingerprint"
    static let deviceNameKey = "DeviceName"
    static let buildTypeKey = "BuildType"
    static let releaseVersionKey = "DeviceOsReleaseVersion"
    static let deviceIdKey = "DeviceId"
    static let thirdPartyDeviceIdKey = "ThirdPartyDeviceId"
    static let platformKey = "Platform"
    static let timezoneKey = "ClientTimezone"
    static let deviceHeightKey = "ScreenHeightPixels"
    static let deviceWidthKey = "ScreenWidthPixels"
    static let deviceLanguageKey = "DeviceLanguage"
    static let phoneTypeKey = "PhoneType"
    static let asfVersion = "IOS20171114"

    func userContextData(for username: String = "unknown",
                         deviceInfo: ASFDeviceBehavior,
                         appInfo: ASFAppInfoBehavior,
                         configuration: UserPoolConfigurationData) async throws -> String {

        let contextData = await prepareUserContextData(deviceInfo: deviceInfo, appInfo: appInfo)
        let payload = try prepareJsonPayload(username: username,
                                             contextData: contextData,
                                             userPoolId: configuration.poolId)
        let signature = try calculateSecretHash(contextJson: payload,
                                                clientId: configuration.clientId)
        let result = try prepareJsonResult(payload: payload, signature: signature)
        return result
    }

    func prepareUserContextData(deviceInfo: ASFDeviceBehavior,
                                appInfo: ASFAppInfoBehavior) async -> [String: String] {
        var build = "release"
#if DEBUG
        build = "debug"
#endif
        let fingerPrint = await deviceInfo.deviceInfo()
        var contextData: [String: String] = [
            Self.targetSDKKey: appInfo.targetSDK,
            Self.appVersionKey: appInfo.version,
            Self.deviceNameKey: await deviceInfo.name,
            Self.phoneTypeKey: await deviceInfo.type,
            Self.deviceIdKey: deviceInfo.id,
            Self.releaseVersionKey: await deviceInfo.version,
            Self.platformKey: await deviceInfo.platform,
            Self.buildTypeKey: build,
            Self.timezoneKey: timeZoneOffet(),
            Self.deviceHeightKey: await deviceInfo.height,
            Self.deviceWidthKey: await deviceInfo.width,
            Self.deviceLanguageKey: await deviceInfo.locale,
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

    func prepareJsonPayload(username: String,
                            contextData: [String: String],
                            userPoolId: String) throws -> String {
        let timestamp = String(format: "%lli", floor(Date().timeIntervalSince1970 * 1000))
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

    func timeZoneOffet(seconds: Int = TimeZone.current.secondsFromGMT()) -> String {

        let hours = seconds/3600
        let minutes = abs(seconds/60) % 60
        return String(format: "%+.2d:%.2d", hours, minutes)
    }

    func calculateSecretHash(contextJson: String, clientId: String) throws -> String {
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

    func prepareJsonResult(payload: String, signature: String) throws -> String {
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

enum ASFError: Error {
    case stringConversion
    case dataConversion
    case hashKey
    case hashData
}

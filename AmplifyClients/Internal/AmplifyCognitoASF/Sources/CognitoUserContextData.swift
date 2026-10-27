//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// User context data for Amazon Cognito threat protection (advanced security), for the user pool requests your app
/// sends itself. It replaces `AWSCognitoIdentityProviderASF` from the AWS SDK for iOS.
///
/// `AWSCognitoAuthPlugin` and `AmplifyCognitoClient` already add this data to the requests they send.
///
/// Experimental: add the `AmplifyCognitoASF` product and import it with
/// `@_spi(AmplifyExperimental) import AmplifyCognitoASF`. Any release may change it.
@_spi(AmplifyExperimental)
public enum CognitoUserContextData {

    /// Returns the encoded user context data for one request to a user pool.
    ///
    /// Pass it as the `encodedData` of the request's `UserContextDataType`, for example in an `InitiateAuth` sent
    /// with the AWS SDK for Swift, or send it to your backend for the `ContextDataType` of an `Admin*` request:
    ///
    /// ```swift
    /// let encodedData = await CognitoUserContextData.encodedData(
    ///     userPoolId: userPoolId,
    ///     userPoolClientId: clientId,
    ///     username: username
    /// )
    /// let input = InitiateAuthInput(
    ///     authFlow: .userPasswordAuth,
    ///     authParameters: ["USERNAME": username, "PASSWORD": password],
    ///     clientId: clientId,
    ///     userContextData: .init(encodedData: encodedData)
    /// )
    /// ```
    ///
    /// The data describes this device and app as Amplify's own requests do (model and hardware identifier, name, system
    /// and version, screen size, language, time zone, identifier for vendor, bundle identifier, version and deployment
    /// target, and debug or release build), names the user, holds the time it was made and is signed with the app
    /// client ID, so make it for each request. It carries the username and device identifiers: don't log it. The
    /// device is read on the main actor.
    ///
    /// - Parameters:
    ///   - userPoolId: The user pool ID, such as `us-east-1_EXAMPLE`.
    ///   - userPoolClientId: The ID of the app client that sends the request.
    ///   - username: The username the request sends. `nil` sends `"unknown"`.
    ///   - deviceId: An ID that stays the same for this device, such as the device key of a remembered device.
    ///     `nil` sends the identifier for vendor, or no device ID where there is none, as on macOS.
    /// - Returns: The encoded data, or `nil` if `userPoolId` or `userPoolClientId` is empty, or the client ID isn't
    ///   ASCII.
    public static func encodedData(
        userPoolId: String,
        userPoolClientId: String,
        username: String?,
        deviceId: String? = nil
    ) async -> String? {
        await encodedData(
            userPoolId: userPoolId,
            userPoolClientId: userPoolClientId,
            username: username,
            deviceId: deviceId,
            device: ASFDeviceInfo(id: deviceId ?? ""),
            appInfo: ASFAppInfo()
        )
    }

    /// The public method over the given device and app, which are read only when both IDs are non-empty.
    package static func encodedData( // swiftlint:disable:this function_parameter_count
        userPoolId: String,
        userPoolClientId: String,
        username: String?,
        deviceId: String?,
        device: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior
    ) async -> String? {
        guard !userPoolId.isEmpty, !userPoolClientId.isEmpty else {
            return nil
        }
        var contextData = await UserContextDataEncoder.prepareUserContextData(deviceInfo: device, appInfo: appInfo)
        // As in the AWS SDK for iOS: the given device ID, else the vendor ID, else none.
        contextData[UserContextDataEncoder.deviceIdKey] = deviceId ?? contextData[UserContextDataEncoder.thirdPartyDeviceIdKey]
        return try? UserContextDataEncoder.encodedData(
            username: username ?? "unknown",
            contextData: contextData,
            userPoolId: userPoolId,
            clientId: userPoolClientId
        )
    }
}

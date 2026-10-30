//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CryptoKit
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoASF

final class CognitoUserContextDataTests: XCTestCase {

    private let userPoolId = "us-east-1_EXAMPLE"
    private let clientId = "1example23456789abcdefghij"
    private let vendorId = "00000000-0000-4000-8000-000000000047"

    /// Test that the encoded data is the signed context data of the request's pool, user and device
    ///
    /// - Given: A fixed device and app
    /// - When:
    ///    - the data is encoded for a pool, an app client, a username and a device ID
    /// - Then:
    ///    - the envelope holds the payload, the version and the payload's signature, keyed by the app client ID
    ///    - the payload names the pool, the user and the time, and its context data describes the device and app
    ///
    func testTheDataIsTheSignedContextDataOfThePoolTheUserAndTheDevice() async throws {
        let before = Self.milliseconds(Date())
        let encoded = await encodedData(username: "alice", deviceId: "device-key")
        let after = Self.milliseconds(Date())

        let envelope = try Self.envelope(XCTUnwrap(encoded))
        XCTAssertEqual(Set(envelope.keys), ["payload", "version", "signature"])
        XCTAssertEqual(envelope["version"], "IOS20171114")
        let payload = try XCTUnwrap(envelope["payload"])
        XCTAssertEqual(envelope["signature"], Self.signature(of: payload, clientId: clientId))

        let object = try Self.payload(XCTUnwrap(encoded))
        XCTAssertEqual(Set(object.keys), ["contextData", "username", "userPoolId", "timestamp"])
        XCTAssertEqual(object["username"] as? String, "alice")
        XCTAssertEqual(object["userPoolId"] as? String, userPoolId)
        let timestamp = try XCTUnwrap(Int64(XCTUnwrap(object["timestamp"] as? String)))
        XCTAssertTrue((before ... after).contains(timestamp), "\(timestamp) not in \(before)...\(after)")
        XCTAssertEqual(object["contextData"] as? [String: String], [
            "ApplicationName": "com.example.app",
            "ApplicationTargetSdk": "150000",
            "ApplicationVersion": "1.2-34",
            "BuildType": Self.buildType,
            "ClientTimezone": UserContextDataEncoder.timeZoneOffset(),
            "DeviceFingerprint": "Apple/iPhone/arm64/-:26.0/-/-:-/debug",
            "DeviceId": "device-key",
            "DeviceLanguage": "en-US",
            "DeviceName": "Unit Test Device",
            "DeviceOsReleaseVersion": "26.0",
            "PhoneType": "arm64",
            "Platform": "iOS",
            "ScreenHeightPixels": "2868",
            "ScreenWidthPixels": "1320",
            "ThirdPartyDeviceId": vendorId
        ])
    }

    /// Test that a request without a username names an unknown user
    ///
    /// - Given: A fixed device and app
    /// - When:
    ///    - the data is encoded without a username
    /// - Then:
    ///    - the payload's username is "unknown"
    ///
    func testANilUsernameIsSentAsUnknown() async throws {
        let encoded = await encodedData(username: nil)

        let object = try Self.payload(XCTUnwrap(encoded))
        XCTAssertEqual(object["username"] as? String, "unknown")
    }

    /// Test that a username is sent as it is given
    ///
    /// - Given: A fixed device and app
    /// - When:
    ///    - the data is encoded for an empty username, and for one with capitals and symbols
    /// - Then:
    ///    - each payload's username is the one given
    ///
    func testAUsernameIsSentAsGiven() async throws {
        for username in ["", "Alice+1@example.com"] {
            let encoded = await encodedData(username: username)

            let object = try Self.payload(XCTUnwrap(encoded))
            XCTAssertEqual(object["username"] as? String, username)
        }
    }

    /// Test that a given device ID is sent as it is
    ///
    /// - Given: A fixed device with a vendor ID
    /// - When:
    ///    - the data is encoded with a device key, and with an empty device ID
    /// - Then:
    ///    - each `DeviceId` is the one given, and `ThirdPartyDeviceId` is still the vendor ID
    ///
    func testAGivenDeviceIdIsSentAsGiven() async throws {
        for deviceId in ["device-key", ""] {
            let encoded = await encodedData(deviceId: deviceId)

            let contextData = try Self.contextData(XCTUnwrap(encoded))
            XCTAssertEqual(contextData["DeviceId"], deviceId)
            XCTAssertEqual(contextData["ThirdPartyDeviceId"], vendorId)
        }
    }

    /// Test that without a device ID the vendor ID is sent in its place
    ///
    /// - Given: A fixed device with a vendor ID
    /// - When:
    ///    - the data is encoded without a device ID
    /// - Then:
    ///    - `DeviceId` and `ThirdPartyDeviceId` are both the vendor ID
    ///
    func testWithoutADeviceIdTheVendorIdIsSent() async throws {
        let encoded = await encodedData(deviceId: nil)

        let contextData = try Self.contextData(XCTUnwrap(encoded))
        XCTAssertEqual(contextData["DeviceId"], vendorId)
        XCTAssertEqual(contextData["ThirdPartyDeviceId"], vendorId)
    }

    /// Test that without a device ID or a vendor ID no device ID is sent
    ///
    /// - Given: A fixed device without a vendor ID, as on macOS
    /// - When:
    ///    - the data is encoded without a device ID
    /// - Then:
    ///    - the data is still encoded and signed, with neither `DeviceId` nor `ThirdPartyDeviceId`
    ///
    func testWithoutADeviceIdOrAVendorIdNoDeviceIdIsSent() async throws {
        let encoded = await encodedData(deviceId: nil, device: FixedDevice(thirdPartyId: nil))

        let envelope = try Self.envelope(XCTUnwrap(encoded))
        let payload = try XCTUnwrap(envelope["payload"])
        XCTAssertEqual(envelope["signature"], Self.signature(of: payload, clientId: clientId))
        let contextData = try Self.contextData(XCTUnwrap(encoded))
        XCTAssertEqual(contextData.count, 13)
        XCTAssertNil(contextData["DeviceId"])
        XCTAssertNil(contextData["ThirdPartyDeviceId"])
    }

    /// Test that an empty pool or app client ID gives no data, before the device or app is read
    ///
    /// - Given: A device and an app that fail the test when read
    /// - When:
    ///    - the data is encoded with an empty user pool ID, and with an empty app client ID
    /// - Then:
    ///    - both give `nil`, and neither the device nor the app is read
    ///
    func testAnEmptyPoolOrClientIdGivesNilWithoutReadingTheDevice() async {
        for (pool, client) in [("", clientId), (userPoolId, "")] {
            let encoded = await CognitoUserContextData(userPoolId: pool, userPoolClientId: client).encodedData(
                username: "alice",
                deviceId: nil,
                device: UnreadableDevice(),
                appInfo: UnreadableAppInfo()
            )

            XCTAssertNil(encoded)
        }
    }

    /// Test that an app client ID that isn't ASCII gives no data
    ///
    /// - Given: A fixed device and app
    /// - When:
    ///    - the data is encoded with an app client ID that has no ASCII representation
    /// - Then:
    ///    - it gives `nil`
    ///
    func testAClientIdThatIsNotASCIIGivesNil() async {
        let encoded = await CognitoUserContextData(userPoolId: userPoolId, userPoolClientId: "🕺🏼").encodedData(
            username: "alice",
            deviceId: nil,
            device: FixedDevice(),
            appInfo: FixedAppInfo()
        )

        XCTAssertNil(encoded)
    }

    /// Test that the public method gives no data for an empty ID
    ///
    /// - Given: The system's device and app
    /// - When:
    ///    - `encodedData(username:deviceId:)` is called on data made with an empty user pool ID, and on data made
    ///      with an empty app client ID
    /// - Then:
    ///    - both give `nil`
    ///
    func testThePublicMethodGivesNilForAnEmptyId() async {
        let withoutPool = await CognitoUserContextData(userPoolId: "", userPoolClientId: clientId)
            .encodedData(username: "alice")
        let withoutClient = await CognitoUserContextData(userPoolId: userPoolId, userPoolClientId: "")
            .encodedData(username: "alice", deviceId: "device-key")

        XCTAssertNil(withoutPool)
        XCTAssertNil(withoutClient)
    }

    #if os(macOS)
    /// Test that the public method encodes the system's device and app for the IDs it is given
    ///
    /// - Given: The system's device and app, on macOS, where reading them never blocks a simulator
    /// - When:
    ///    - one value made for a pool and an app client encodes the data for a username and a device ID, and again
    ///      without a device ID
    /// - Then:
    ///    - both are signed with the app client ID, name the pool and the user, and carry the main bundle's ID
    ///    - `DeviceId` is the given ID, and without one there is none, as macOS has no identifier for vendor
    ///
    func testThePublicMethodEncodesTheSystemsDeviceAndApp() async throws {
        let contextData = CognitoUserContextData(userPoolId: userPoolId, userPoolClientId: clientId)
        let withDeviceId = await contextData.encodedData(username: "alice", deviceId: "device-key")
        let withoutDeviceId = await contextData.encodedData(username: "alice")

        for encoded in [withDeviceId, withoutDeviceId] {
            let envelope = try Self.envelope(XCTUnwrap(encoded))
            let payload = try XCTUnwrap(envelope["payload"])
            XCTAssertEqual(envelope["signature"], Self.signature(of: payload, clientId: clientId))
            let object = try Self.payload(XCTUnwrap(encoded))
            XCTAssertEqual(object["userPoolId"] as? String, userPoolId)
            XCTAssertEqual(object["username"] as? String, "alice")
            XCTAssertEqual(try Self.contextData(XCTUnwrap(encoded))["ApplicationName"], Bundle.main.bundleIdentifier)
        }
        XCTAssertEqual(try Self.contextData(XCTUnwrap(withDeviceId))["DeviceId"], "device-key")
        XCTAssertNil(try Self.contextData(XCTUnwrap(withoutDeviceId))["DeviceId"])
    }
    #endif

    private func encodedData(
        username: String? = "alice",
        deviceId: String? = "device-key",
        device: FixedDevice = FixedDevice()
    ) async -> String? {
        await CognitoUserContextData(userPoolId: userPoolId, userPoolClientId: clientId).encodedData(
            username: username,
            deviceId: deviceId,
            device: device,
            appInfo: FixedAppInfo()
        )
    }

    private static func envelope(_ encoded: String) throws -> [String: String] {
        let data = try XCTUnwrap(Data(base64Encoded: encoded))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
    }

    private static func payload(_ encoded: String) throws -> [String: Any] {
        let payload = try XCTUnwrap(envelope(encoded)["payload"])
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
    }

    private static func contextData(_ encoded: String) throws -> [String: String] {
        try XCTUnwrap(payload(encoded)["contextData"] as? [String: String])
    }

    private static func signature(of payload: String, clientId: String) -> String {
        let key = SymmetricKey(data: Data(clientId.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: Data("IOS20171114\(payload)".utf8), using: key)
        return Data(code).base64EncodedString()
    }

    private static func milliseconds(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970 * 1_000)
    }

    private static var buildType: String {
        #if DEBUG
        "debug"
        #else
        "release"
        #endif
    }
}

/// A device with fixed values, so no test reads `UIDevice` or `UIScreen`.
private struct FixedDevice: ASFDeviceBehavior {
    let id = "ignored"
    var thirdPartyId: String? = "00000000-0000-4000-8000-000000000047"
    let model = "iPhone"
    let name = "Unit Test Device"
    let platform = "iOS"
    let version = "26.0"
    let height = "2868"
    let width = "1320"
    let locale = "en-US"
    let type = "arm64"

    func deviceInfo() async -> String {
        "Apple/\(model)/\(type)/-:\(version)/-/-:-/debug"
    }
}

private struct FixedAppInfo: ASFAppInfoBehavior {
    let name: String? = "com.example.app"
    let targetSDK = "150000"
    let version = "1.2-34"
}

/// A device that fails the test when any of its values is read.
private struct UnreadableDevice: ASFDeviceBehavior {
    var id: String { Self.read() }
    var model: String { Self.read() }
    var name: String { Self.read() }
    var platform: String { Self.read() }
    var version: String { Self.read() }
    var thirdPartyId: String? { Self.read() }
    var height: String { Self.read() }
    var width: String { Self.read() }
    var locale: String { Self.read() }
    var type: String { Self.read() }

    func deviceInfo() async -> String {
        Self.read()
    }

    private static func read() -> String {
        XCTFail("The device was read")
        return ""
    }
}

/// An app that fails the test when any of its values is read.
private struct UnreadableAppInfo: ASFAppInfoBehavior {
    var name: String? { read() }
    var targetSDK: String { read() }
    var version: String { read() }

    private func read() -> String {
        XCTFail("The app was read")
        return ""
    }
}

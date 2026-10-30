//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoASF
import CryptoKit
import Foundation
import XCTest
@testable import InternalAWSCognitoAuth

/// Pins the user context data the engine sends to Cognito, over a fixed device and app.
final class UserContextDataFormatTests: XCTestCase {

    /// Test that the engine's context data has the format Cognito expects
    ///
    /// - Given: `CognitoUserPoolASF`, a fixed device and a fixed app
    /// - When:
    ///    - the context data is encoded for "alice"
    /// - Then:
    ///    - the envelope holds the payload, the version and the payload's signature, keyed by the client ID
    ///    - the payload names the user, the pool and the time
    ///    - the context data holds each of the device's and the app's values under its key
    ///
    func testTheEnginesContextDataIsPinned() async throws {
        let before = Self.milliseconds(Date())
        let encoded = try await CognitoUserPoolASF().userContextData(
            for: "alice",
            deviceInfo: FixedASFDevice(id: "asf-id"),
            appInfo: FixedAppInfo(),
            configuration: .testData
        )
        let after = Self.milliseconds(Date())

        let envelope = try Self.envelope(encoded)
        XCTAssertEqual(Set(envelope.keys), ["payload", "version", "signature"])
        XCTAssertEqual(envelope["version"], "IOS20171114")
        let payload = try XCTUnwrap(envelope["payload"])
        XCTAssertEqual(envelope["signature"], Self.signature(of: payload, clientId: "testClientId"))

        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["contextData", "username", "userPoolId", "timestamp"])
        XCTAssertEqual(object["username"] as? String, "alice")
        XCTAssertEqual(object["userPoolId"] as? String, "testPoolId")
        let timestamp = try XCTUnwrap(Int64(XCTUnwrap(object["timestamp"] as? String)))
        XCTAssertTrue((before ... after).contains(timestamp), "\(timestamp) not in \(before)...\(after)")
        XCTAssertEqual(object["contextData"] as? [String: String], [
            "ApplicationName": "com.example.app",
            "ApplicationTargetSdk": "150000",
            "ApplicationVersion": "1.2-34",
            "BuildType": Self.buildType,
            "ClientTimezone": Self.timeZoneOffset(),
            "DeviceFingerprint": "Apple/iPhone/arm64/-:26.0/-/-:-/debug",
            "DeviceId": "asf-id",
            "DeviceLanguage": "en-US",
            "DeviceName": "Unit Test Device",
            "DeviceOsReleaseVersion": "26.0",
            "PhoneType": "arm64",
            "Platform": "iOS",
            "ScreenHeightPixels": "2868",
            "ScreenWidthPixels": "1320",
            "ThirdPartyDeviceId": "00000000-0000-4000-8000-000000000047"
        ])
    }

    /// Test that the encoded context carries the ASF device ID it is given and the main bundle's app values
    ///
    /// - Given: An advanced-security client over a fixed device
    /// - When:
    ///    - `encodedContext` encodes the context for "alice" and an ASF device ID
    /// - Then:
    ///    - `DeviceId` is that ID, and the app's name, version and target SDK come from the main bundle and the
    ///      deployment target
    ///
    func testTheEncodedContextCarriesTheGivenDeviceIdAndTheMainBundle() async throws {
        let encoded = await CognitoUserPoolASF.encodedContext(
            username: "alice",
            asfDeviceId: "asf-id",
            asfClient: FixedDeviceASF(),
            userPoolConfiguration: .testData
        )

        let contextData = try Self.contextData(XCTUnwrap(encoded))
        let bundle = Bundle.main
        let buildVersion = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) ?? ""
        let bundleVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        XCTAssertEqual(contextData["DeviceId"], "asf-id")
        XCTAssertEqual(contextData["ApplicationName"], bundle.bundleIdentifier)
        XCTAssertEqual(contextData["ApplicationVersion"], "\(bundleVersion)-\(buildVersion)")
        let targetSDK = try XCTUnwrap(contextData["ApplicationTargetSdk"])
        XCTAssertTrue(targetSDK == "Unknown" || (!targetSDK.isEmpty && targetSDK.allSatisfy(\.isNumber)), targetSDK)
    }

    /// Test that the public context data is the engine's for the same device, app and IDs
    ///
    /// - Given: A fixed device and app
    /// - When:
    ///    - the engine and `CognitoUserContextData` encode the context data for the same pool, app client, username
    ///      and device ID
    /// - Then:
    ///    - both payloads name the same user and pool and hold the same context data, and both are signed with the
    ///      app client ID
    ///
    func testThePublicContextDataIsTheEnginesForTheSameDevice() async throws {
        let engine = try await CognitoUserPoolASF().userContextData(
            for: "alice",
            deviceInfo: FixedASFDevice(id: "asf-id"),
            appInfo: FixedAppInfo(),
            configuration: .testData
        )
        let encoded = await CognitoUserContextData(userPoolId: "testPoolId", userPoolClientId: "testClientId").encodedData(
            username: "alice",
            deviceId: "asf-id",
            device: FixedASFDevice(id: "asf-id"),
            appInfo: FixedAppInfo()
        )

        let shared = try XCTUnwrap(encoded)
        let enginePayload = try Self.payload(engine)
        let sharedPayload = try Self.payload(shared)
        XCTAssertEqual(sharedPayload["contextData"] as? [String: String], enginePayload["contextData"] as? [String: String])
        XCTAssertEqual(sharedPayload["username"] as? String, enginePayload["username"] as? String)
        XCTAssertEqual(sharedPayload["userPoolId"] as? String, enginePayload["userPoolId"] as? String)
        for encoded in [engine, shared] {
            let envelope = try Self.envelope(encoded)
            let payload = try XCTUnwrap(envelope["payload"])
            XCTAssertEqual(envelope["signature"], Self.signature(of: payload, clientId: "testClientId"))
        }
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

    /// The local time zone's offset from GMT as `±hh:mm`, from a formatter rather than the engine's code.
    private static func timeZoneOffset() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "xxx"
        return formatter.string(from: Date())
    }
}

private struct FixedAppInfo: ASFAppInfoBehavior {
    let name: String? = "com.example.app"
    let targetSDK = "150000"
    let version = "1.2-34"
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Differential test for `EngineDeviceInfo`: every member the engine reads must
/// equal `Amplify.DeviceInfo`'s on the platform the test runs on. These values reach Cognito (the confirmed
/// device name and the advanced-security fingerprint), so a drift would look like a new device.
///
/// CI runs this file on every platform in its matrix; each run checks that platform's branch.
@MainActor
final class EngineDeviceInfoTests: XCTestCase {

    /// Test that every copied member equals Amplify's
    ///
    /// - Given: `EngineDeviceInfo.current` and `Amplify.DeviceInfo.current`
    /// - When:
    ///    - Each member the engine reads is read from both
    /// - Then:
    ///    - `name`, `hostName`, `model`, `operatingSystem.name`, `operatingSystem.version`,
    ///      `identifierForVendor` and `screenBounds` are equal
    ///
    func testEveryMemberEqualsAmplifyDeviceInfo() {
        let engine = EngineDeviceInfo.current
        let amplify = DeviceInfo.current

        XCTAssertEqual(engine.name, amplify.name)
        XCTAssertEqual(engine.hostName, amplify.hostName)
        XCTAssertEqual(engine.model, amplify.model)
        XCTAssertEqual(engine.operatingSystem.name, amplify.operatingSystem.name)
        XCTAssertEqual(engine.operatingSystem.version, amplify.operatingSystem.version)
        XCTAssertEqual(engine.identifierForVendor, amplify.identifierForVendor)
        XCTAssertEqual(engine.screenBounds, amplify.screenBounds)
    }

    /// Test that the values the ASF fingerprint formats are equal too
    ///
    /// - Given: Both device infos
    /// - When:
    ///    - The screen size is formatted as `ASFDeviceInfo` formats it, and the vendor id as a string
    /// - Then:
    ///    - The strings are equal
    ///
    func testFormattedFingerprintValuesAreEqual() {
        let engine = EngineDeviceInfo.current
        let amplify = DeviceInfo.current

        XCTAssertEqual(
            String(format: "%.0f", engine.screenBounds.height),
            String(format: "%.0f", amplify.screenBounds.height)
        )
        XCTAssertEqual(
            String(format: "%.0f", engine.screenBounds.width),
            String(format: "%.0f", amplify.screenBounds.width)
        )
        XCTAssertEqual(engine.identifierForVendor?.uuidString, amplify.identifierForVendor?.uuidString)
    }

    /// Test that the ASF fingerprint reads the values Amplify's `DeviceInfo` gives
    ///
    /// - Given: An `ASFDeviceInfo`, which reads `EngineDeviceInfo`
    /// - When:
    ///    - Each fingerprint field is read
    /// - Then:
    ///    - Each equals the value built from `Amplify.DeviceInfo`, as `ASFDeviceInfo` built it before the fork
    ///
    func testASFDeviceInfoReadsTheSameValues() async {
        let asf = ASFDeviceInfo(id: "device-id")
        let amplify = DeviceInfo.current

        let model = await asf.model
        let name = await asf.name
        let platform = await asf.platform
        let version = await asf.version
        let thirdPartyId = await asf.thirdPartyId
        let height = await asf.height
        let width = await asf.width
        let type = await asf.type

        XCTAssertEqual(model, amplify.model)
        XCTAssertEqual(name, amplify.name)
        XCTAssertEqual(platform, amplify.operatingSystem.name)
        XCTAssertEqual(version, amplify.operatingSystem.version)
        XCTAssertEqual(thirdPartyId, amplify.identifierForVendor?.uuidString)
        XCTAssertEqual(height, String(format: "%.0f", amplify.screenBounds.height))
        XCTAssertEqual(width, String(format: "%.0f", amplify.screenBounds.width))
        XCTAssertEqual(type, Self.machineType(fallback: amplify.hostName))
    }

    /// The `utsname` machine string, falling back to Amplify's host name, as `ASFDeviceInfo.type` built it
    /// before the fork.
    private static func machineType(fallback: String) -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return String(
            bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)),
            encoding: .utf8
        ) ?? fallback
    }
}

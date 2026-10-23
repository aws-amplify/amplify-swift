//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The device the engine describes to Cognito comes from the advanced-security client
/// (`AdvancedSecurityBehavior.device(id:)`), so a unit test that fixes it never reads `UIDevice` or
/// `UIScreen`.
final class ASFDeviceSeamTests: XCTestCase {

    /// Test that the system's advanced-security client describes the system's device
    ///
    /// - Given: `CognitoUserPoolASF`, the client the plugin and the Cognito client build
    /// - When:
    ///    - its device is asked for, for an ASF device ID
    /// - Then:
    ///    - it is `ASFDeviceInfo`, with that ID. None of its values is read
    ///
    func testTheSystemClientDescribesTheSystemDevice() {
        let device = CognitoUserPoolASF().device(id: "device-id")

        XCTAssertTrue(device is ASFDeviceInfo)
        XCTAssertEqual(device.id, "device-id")
    }

    /// Test that the context data describes the advanced-security client's device
    ///
    /// - Given: An advanced-security client whose device is fixed
    /// - When:
    ///    - the context data is encoded for an ASF device ID
    /// - Then:
    ///    - the client encodes its own device, with that ID
    ///
    func testTheContextDataDescribesTheClientsDevice() async {
        let encoded = await CognitoUserPoolASF.encodedContext(
            username: "alice",
            asfDeviceId: "asf-id",
            asfClient: DeviceEchoingASF(),
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData()
        )

        XCTAssertEqual(encoded, "asf-id|Unit Test Device|2868x1320")
    }

    /// Test that a confirmed device is named after the advanced-security client's device
    ///
    /// - Given: A signed-in user with device metadata, and the test environment's fixed device
    /// - When:
    ///    - `ConfirmDevice` runs
    /// - Then:
    ///    - Cognito is asked to confirm the device under the fixed device's name
    ///
    func testTheConfirmedDeviceIsNamedAfterTheClientsDevice() async {
        let names = DeviceNames()
        let environment = Defaults.makeDefaultAuthEnvironment(userPoolFactory: {
            MockIdentityProvider(mockConfirmDeviceResponse: { input in
                await names.append(input.deviceName)
                return ConfirmDeviceOutput()
            })
        })
        let signedInData = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            deviceMetadata: .metadata(.init(deviceKey: "device-key", deviceGroupKey: "device-group-key")),
            cognitoUserPoolTokens: .testData
        )

        await ConfirmDevice(signedInData: signedInData).execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        let confirmed = await names.values
        XCTAssertEqual(confirmed, ["Unit Test Device"])
    }

    /// Test that the sign-up validation data describes the advanced-security client's device
    ///
    /// - Given: The test environment's fixed device
    /// - When:
    ///    - a sign-up input is built without validation data of the app's own
    /// - Then:
    ///    - on watchOS and UIKit platforms, the eight attributes come in the plugin's order, and the device's five
    ///      are the fixed device's; elsewhere there are none
    ///
    func testTheSignUpValidationDataDescribesTheClientsDevice() async {
        let input = await SignUpInput(
            username: "alice",
            password: "password",
            clientMetadata: nil,
            validationData: nil,
            attributes: [:],
            asfDeviceId: "asf-id",
            environment: BasicUserPoolEnvironment(
                userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
                cognitoUserPoolFactory: Defaults.makeDefaultUserPool,
                cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
                cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
            )
        )

        #if canImport(WatchKit) || canImport(UIKit)
        let validationData = input.validationData ?? []
        XCTAssertEqual(validationData.map(\.name), [
            "cognito:iOSVersion",
            "cognito:systemName",
            "cognito:deviceName",
            "cognito:model",
            "cognito:idForVendor",
            "cognito:bundleId",
            "cognito:bundleVersion",
            "cognito:bundleShortV"
        ])
        XCTAssertEqual(validationData.prefix(5).map(\.value), [
            "26.0",
            "iOS",
            "Unit Test Device",
            "iPhone",
            "00000000-0000-4000-8000-000000000047"
        ])
        #else
        XCTAssertNil(input.validationData)
        #endif
    }
}

/// An advanced-security client over a `FixedASFDevice` that encodes the device's ID, name and screen size.
private struct DeviceEchoingASF: AdvancedSecurityBehavior {

    func userContextData(
        for username: String,
        deviceInfo: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior,
        configuration: UserPoolConfigurationData
    ) async throws -> String {
        await "\(deviceInfo.id)|\(deviceInfo.name)|\(deviceInfo.height)x\(deviceInfo.width)"
    }

    func device(id: String) -> ASFDeviceBehavior {
        FixedASFDevice(id: id)
    }
}

private actor DeviceNames {
    private(set) var values: [String?] = []

    func append(_ name: String?) {
        values.append(name)
    }
}

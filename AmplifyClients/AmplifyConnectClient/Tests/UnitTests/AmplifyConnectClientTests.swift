//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyConnectClient
import AmplifyFoundation
import Foundation
import XCTest

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
final class AmplifyConnectClientTests: XCTestCase {

    /// Test that the identify-user request body contains only the user profile
    ///
    /// - Given: An IdentifyUserRequest with a populated profile
    /// - When:
    ///    - The request is encoded
    /// - Then:
    ///    - The body is { userProfile } with the expected fields and no other top-level keys
    ///
    func testIdentifyUserRequestEncodesCorrectBody() throws {
        let profile = UserProfile(
            email: "test@example.com",
            name: "Test User",
            phone: "+15555550100",
            customAttributes: ["tier": "premium"]
        )
        let request = IdentifyUserRequest(userProfile: profile)

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json.keys.sorted(), ["userProfile"])

        let userProfileJson = json["userProfile"] as! [String: Any]
        XCTAssertEqual(userProfileJson["email"] as? String, "test@example.com")
        XCTAssertEqual(userProfileJson["name"] as? String, "Test User")
        XCTAssertEqual(userProfileJson["phone"] as? String, "+15555550100")
        XCTAssertEqual(userProfileJson["customAttributes"] as? [String: String], ["tier": "premium"])
    }

    /// Test that an empty user profile encodes as an empty object
    ///
    /// - Given: An IdentifyUserRequest with a default UserProfile
    /// - When:
    ///    - The request is encoded
    /// - Then:
    ///    - userProfile is present and empty
    ///
    func testEmptyUserProfileEncodesAsEmptyObject() throws {
        let request = IdentifyUserRequest(userProfile: UserProfile())

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let userProfileJson = json["userProfile"] as! [String: Any]
        XCTAssertTrue(userProfileJson.isEmpty)
    }

    /// Test that UserProfile encodes location correctly
    ///
    /// - Given: A UserProfile with location
    /// - When:
    ///    - It is encoded to JSON
    /// - Then:
    ///    - Only the contract location fields (city, country, postalCode, region) are present
    ///
    func testUserProfileEncodesLocation() throws {
        let profile = UserProfile(
            location: UserProfileLocation(
                city: "Seattle",
                country: "US",
                postalCode: "98101",
                region: "WA"
            )
        )

        let data = try JSONEncoder().encode(profile)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let location = json["location"] as! [String: Any]

        XCTAssertEqual(location.keys.sorted(), ["city", "country", "postalCode", "region"])
        XCTAssertEqual(location["city"] as? String, "Seattle")
        XCTAssertEqual(location["country"] as? String, "US")
        XCTAssertEqual(location["postalCode"] as? String, "98101")
        XCTAssertEqual(location["region"] as? String, "WA")
    }

    /// Test that the register-device request body matches the wire contract
    ///
    /// - Given: A Device with all fields set
    /// - When:
    ///    - A RegisterDeviceRequest is encoded
    /// - Then:
    ///    - The body is { device: { token, deviceId, platform, appVersion, channelType } }
    ///
    func testRegisterDeviceRequestEncodesCorrectBody() throws {
        let request = RegisterDeviceRequest(
            device: Device(
                token: "apns-token",
                deviceId: "device-123",
                platform: "iOS",
                appVersion: "2.0.0",
                channelType: .apns
            )
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json.keys.sorted(), ["device"])

        let device = json["device"] as! [String: Any]
        XCTAssertEqual(device["token"] as? String, "apns-token")
        XCTAssertEqual(device["deviceId"] as? String, "device-123")
        XCTAssertEqual(device["platform"] as? String, "iOS")
        XCTAssertEqual(device["appVersion"] as? String, "2.0.0")
        XCTAssertEqual(device["channelType"] as? String, "APNS")
    }

    /// Test that the remove-device request body matches the wire contract
    ///
    /// - Given: A RemoveDeviceRequest with a deviceId
    /// - When:
    ///    - The request is encoded
    /// - Then:
    ///    - The body is { deviceId } with no other keys
    ///
    func testRemoveDeviceRequestEncodesCorrectBody() throws {
        let request = RemoveDeviceRequest(deviceId: "device-123")

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json.keys.sorted(), ["deviceId"])
        XCTAssertEqual(json["deviceId"] as? String, "device-123")
    }

    /// Test that DeviceIdProvider returns a stable, persisted identifier
    ///
    /// - Given: A clean UserDefaults suite
    /// - When:
    ///    - DeviceIdProvider.resolve() is called twice
    /// - Then:
    ///    - A non-empty UUID string is returned and persisted under the shared key
    ///
    func testDeviceIdProviderReturnsStableId() {
        let defaults = UserDefaults(suiteName: "test-device-id")!
        defaults.removeObject(forKey: "com.amplifyframework.device_id")

        let id1 = DeviceIdProvider.resolve(userDefaults: defaults)
        let id2 = DeviceIdProvider.resolve(userDefaults: defaults)

        XCTAssertFalse(id1.isEmpty)
        XCTAssertEqual(id1, id2)

        defaults.removeSuite(named: "test-device-id")
    }

    /// Test that the platform name reflects the current operating system
    ///
    /// - Given: The client's internal platform resolution
    /// - When:
    ///    - platformName is read
    /// - Then:
    ///    - It matches the OS the test is compiled for
    ///
    func testPlatformNameMatchesCurrentOS() {
        #if os(visionOS)
        XCTAssertEqual(AmplifyConnectClient.platformName, "visionOS")
        #elseif os(iOS)
        XCTAssertEqual(AmplifyConnectClient.platformName, "iOS")
        #elseif os(macOS)
        XCTAssertEqual(AmplifyConnectClient.platformName, "macOS")
        #elseif os(tvOS)
        XCTAssertEqual(AmplifyConnectClient.platformName, "tvOS")
        #elseif os(watchOS)
        XCTAssertEqual(AmplifyConnectClient.platformName, "watchOS")
        #endif
    }

    /// Test that ChannelType encodes to correct raw values
    ///
    /// - Given: ChannelType enum values
    /// - When:
    ///    - They are encoded
    /// - Then:
    ///    - The raw string values match the backend contract
    ///
    func testChannelTypeRawValues() {
        XCTAssertEqual(ChannelType.apns.rawValue, "APNS")
        XCTAssertEqual(ChannelType.apnsSandbox.rawValue, "APNS_SANDBOX")
        XCTAssertEqual(ChannelType.gcm.rawValue, "GCM")
    }

    /// Test ConnectClientConfiguration init from region and endpoint
    ///
    /// - Given: A region and endpoint
    /// - When:
    ///    - ConnectClientConfiguration is created
    /// - Then:
    ///    - The fields are set correctly
    ///
    func testConfigurationInit() {
        let config = ConnectClientConfiguration(
            region: "us-west-2",
            endpoint: "https://example.com"
        )
        XCTAssertEqual(config.region, "us-west-2")
        XCTAssertEqual(config.endpoint, "https://example.com")
    }

    /// Test ConnectClientConfiguration from invalid resource throws
    ///
    /// - Given: A nonexistent resource name
    /// - When:
    ///    - ConnectClientConfiguration(from:) is called
    /// - Then:
    ///    - A ConnectError.configuration is thrown
    ///
    func testConfigurationFromInvalidResourceThrows() {
        do {
            _ = try ConnectClientConfiguration(from: "nonexistent_file")
            XCTFail("Expected error")
        } catch let error as ConnectError {
            guard case .configuration = error else {
                XCTFail("Expected configuration error, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Test ConnectError conforms to AmplifyError
    ///
    /// - Given: A ConnectError
    /// - When:
    ///    - errorDescription and recoverySuggestion are accessed
    /// - Then:
    ///    - They return the correct values
    ///
    func testConnectErrorConformsToAmplifyError() {
        let error = ConnectError.service(
            "Something failed",
            "Try again later",
            nil
        )
        XCTAssertEqual(error.errorDescription, "Something failed")
        XCTAssertEqual(error.recoverySuggestion, "Try again later")
        XCTAssertNil(error.underlyingError)
    }
}

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
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AmplifyConnectClientTests: XCTestCase, @unchecked Sendable {

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

    /// Test that reading the device identifier never creates one
    ///
    /// - Given: A clean UserDefaults suite with no persisted identifier
    /// - When:
    ///    - DeviceIdProvider.existing() is called
    /// - Then:
    ///    - nil is returned and nothing is written, so a later call still sees no
    ///      identifier — removeDevice() must not mint an ID the backend never saw
    ///
    func testDeviceIdProviderExistingDoesNotCreateId() {
        let suite = "test-device-id-existing"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removeObject(forKey: "com.amplifyframework.device_id")

        XCTAssertNil(DeviceIdProvider.existing(userDefaults: defaults))
        XCTAssertNil(
            defaults.string(forKey: "com.amplifyframework.device_id"),
            "existing() must not persist an identifier"
        )
        XCTAssertNil(DeviceIdProvider.existing(userDefaults: defaults))

        defaults.removeSuite(named: suite)
    }

    /// Test that reading the device identifier returns the one resolve() persisted
    ///
    /// - Given: A suite where resolve() has created an identifier
    /// - When:
    ///    - DeviceIdProvider.existing() is called
    /// - Then:
    ///    - It returns that same identifier, so removeDevice() targets the device
    ///      registerDevice(token:) registered
    ///
    func testDeviceIdProviderExistingReturnsResolvedId() {
        let suite = "test-device-id-existing-match"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removeObject(forKey: "com.amplifyframework.device_id")

        let resolved = DeviceIdProvider.resolve(userDefaults: defaults)
        XCTAssertEqual(DeviceIdProvider.existing(userDefaults: defaults), resolved)

        defaults.removeSuite(named: suite)
    }

    /// Test that an empty persisted identifier is treated as absent
    ///
    /// - Given: A suite where the shared key holds an empty string
    /// - When:
    ///    - DeviceIdProvider.existing() is called
    /// - Then:
    ///    - nil is returned rather than an empty device ID being sent on the wire
    ///
    func testDeviceIdProviderExistingTreatsEmptyStringAsAbsent() {
        let suite = "test-device-id-empty"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set("", forKey: "com.amplifyframework.device_id")

        XCTAssertNil(DeviceIdProvider.existing(userDefaults: defaults))

        defaults.removeSuite(named: suite)
    }

    /// Test that removeDevice throws when this device was never registered
    ///
    /// - Given: A client and no persisted device identifier
    /// - When:
    ///    - removeDevice is called
    /// - Then:
    ///    - A ConnectError.validation is thrown before any credentials or network
    ///      work, and no identifier is created as a side effect
    ///
    func testRemoveDeviceThrowsWhenNoDeviceRegistered() async {
        let key = "com.amplifyframework.device_id"
        let defaults = UserDefaults.standard
        let saved = defaults.string(forKey: key)
        defaults.removeObject(forKey: key)
        defer {
            if let saved {
                defaults.set(saved, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        let client = AmplifyConnectClient(
            region: "us-west-2",
            endpoint: "https://example.com",
            credentialsProvider: UnusedCredentialsProvider()
        )
        do {
            try await client.removeDevice()
            XCTFail("Expected error")
        } catch let error as ConnectError {
            guard case .validation(let description, _, _) = error else {
                XCTFail("Expected validation error, got \(error)")
                return
            }
            XCTAssertTrue(
                description.contains("no push registration"),
                "Expected the error to explain nothing is registered, got: \(description)"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertNil(
            defaults.string(forKey: key),
            "removeDevice must not create a device identifier"
        )
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

    /// Test ConnectClientConfiguration rejects a resource name carrying an extension
    ///
    /// - Given: A resource name that includes the `.json` extension
    /// - When:
    ///    - ConnectClientConfiguration(from:) is called
    /// - Then:
    ///    - A ConnectError.configuration is thrown naming the extension as the problem,
    ///      rather than a confusing file-not-found error
    ///
    func testConfigurationRejectsResourceNameWithExtension() {
        do {
            _ = try ConnectClientConfiguration(from: "amplify_outputs.json")
            XCTFail("Expected error")
        } catch let error as ConnectError {
            guard case .configuration(let description, let suggestion, _) = error else {
                XCTFail("Expected configuration error, got \(error)")
                return
            }
            XCTAssertTrue(
                description.contains("must not include a file extension"),
                "Expected the error to call out the extension, got: \(description)"
            )
            XCTAssertTrue(
                suggestion.contains("amplify_outputs"),
                "Expected the suggestion to show the corrected name, got: \(suggestion)"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Test ConnectClientConfiguration rejects any resource extension, not just `.json`
    ///
    /// - Given: A resource name with a non-json extension
    /// - When:
    ///    - ConnectClientConfiguration(from:) is called
    /// - Then:
    ///    - A ConnectError.configuration is thrown for the extension
    ///
    func testConfigurationRejectsResourceNameWithNonJsonExtension() {
        do {
            _ = try ConnectClientConfiguration(from: "outputs.txt")
            XCTFail("Expected error")
        } catch let error as ConnectError {
            guard case .configuration(let description, _, _) = error else {
                XCTFail("Expected configuration error, got \(error)")
                return
            }
            XCTAssertTrue(
                description.contains("must not include a file extension"),
                "Expected the error to call out the extension, got: \(description)"
            )
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

    // MARK: - Endpoint validation

    /// Test that a well-formed https endpoint passes validation
    ///
    /// - Given: An https endpoint URL
    /// - When:
    ///    - validateEndpoint is called
    /// - Then:
    ///    - No error is thrown, including for non-default ports
    ///
    func testEndpointValidationAcceptsHttps() throws {
        try ConnectClientConfiguration.validateEndpoint("https://abc123.execute-api.us-west-2.amazonaws.com")
        try ConnectClientConfiguration.validateEndpoint("https://example.com:8443")
    }

    /// Test that non-https and malformed endpoints are rejected
    ///
    /// - Given: Endpoints using http, ftp, or no valid host
    /// - When:
    ///    - validateEndpoint is called
    /// - Then:
    ///    - A ConnectError.configuration is thrown for each
    ///
    func testEndpointValidationRejectsNonHttps() {
        let invalidEndpoints = [
            "http://example.com",
            "ftp://example.com",
            "example.com",
            "",
        ]
        for endpoint in invalidEndpoints {
            do {
                try ConnectClientConfiguration.validateEndpoint(endpoint)
                XCTFail("Expected error for endpoint: \(endpoint)")
            } catch let error as ConnectError {
                guard case .configuration = error else {
                    XCTFail("Expected configuration error for \(endpoint), got \(error)")
                    return
                }
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    /// Test that identifyUser rejects a non-https endpoint before any network call
    ///
    /// - Given: A client manually configured with an http endpoint
    /// - When:
    ///    - identifyUser is called
    /// - Then:
    ///    - A ConnectError.configuration is thrown
    ///
    func testClientRejectsHttpEndpoint() async {
        let client = AmplifyConnectClient(
            region: "us-west-2",
            endpoint: "http://example.com",
            credentialsProvider: UnusedCredentialsProvider()
        )
        do {
            try await client.identifyUser(userProfile: UserProfile())
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

    // MARK: - Input length validation

    /// Test that values at the maximum length pass validation
    ///
    /// - Given: Profile fields, custom attributes, and a token of exactly 255 characters
    /// - When:
    ///    - The validator is invoked
    /// - Then:
    ///    - No error is thrown
    ///
    func testValidationAcceptsValuesAtMaxLength() throws {
        let max = String(repeating: "a", count: 255)
        try ConnectClientValidator.validate(
            UserProfile(
                email: max,
                name: max,
                phone: max,
                customAttributes: [max: max],
                location: UserProfileLocation(
                    city: max,
                    country: max,
                    postalCode: max,
                    region: max
                )
            )
        )
        try ConnectClientValidator.validateToken(max)
    }

    /// Test that each over-length field throws a validation error naming the field
    ///
    /// - Given: Individual fields of 256 characters
    /// - When:
    ///    - The validator is invoked
    /// - Then:
    ///    - A ConnectError.validation is thrown whose description names the field
    ///
    func testValidationRejectsOverLengthValues() {
        let over = String(repeating: "a", count: 256)
        let cases: [(UserProfile, String)] = [
            (UserProfile(email: over), "userProfile.email"),
            (UserProfile(name: over), "userProfile.name"),
            (UserProfile(phone: over), "userProfile.phone"),
            (UserProfile(location: UserProfileLocation(city: over)), "userProfile.location.city"),
            (UserProfile(location: UserProfileLocation(country: over)), "userProfile.location.country"),
            (UserProfile(location: UserProfileLocation(postalCode: over)), "userProfile.location.postalCode"),
            (UserProfile(location: UserProfileLocation(region: over)), "userProfile.location.region"),
            (UserProfile(customAttributes: [over: "v"]), "userProfile.customAttributes key"),
            (UserProfile(customAttributes: ["k": over]), "userProfile.customAttributes[\"k\"]"),
        ]

        for (profile, expectedField) in cases {
            do {
                try ConnectClientValidator.validate(profile)
                XCTFail("Expected error for field: \(expectedField)")
            } catch let error as ConnectError {
                guard case .validation(let description, _, _) = error else {
                    XCTFail("Expected validation error for \(expectedField), got \(error)")
                    continue
                }
                XCTAssertTrue(
                    description.contains(expectedField),
                    "Expected description to name \(expectedField), got: \(description)"
                )
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    /// Test that length is measured in UTF-16 code units, matching the backend
    ///
    /// - Given: A value of 128 emoji (128 grapheme clusters, 256 UTF-16 code units)
    /// - When:
    ///    - The validator is invoked
    /// - Then:
    ///    - A ConnectError.validation is thrown, because the backend's JavaScript
    ///      `String.length` counts UTF-16 code units and would reject this value
    ///
    func testValidationCountsUTF16CodeUnits() {
        // 😀 is a surrogate pair: 1 grapheme cluster, 2 UTF-16 code units.
        let emoji = String(repeating: "😀", count: 128)
        XCTAssertEqual(emoji.count, 128)
        XCTAssertEqual(emoji.utf16.count, 256)

        XCTAssertThrowsError(
            try ConnectClientValidator.validate(UserProfile(email: emoji))
        ) { error in
            guard case .validation = error as? ConnectError else {
                return XCTFail("Expected validation error, got \(error)")
            }
        }

        // 127 emoji (254 code units) stays within the limit.
        let within = String(repeating: "😀", count: 127)
        XCTAssertNoThrow(try ConnectClientValidator.validate(UserProfile(email: within)))
    }

    /// Test that an over-length device token throws a validation error
    ///
    /// - Given: A token of 256 characters
    /// - When:
    ///    - registerDevice is called
    /// - Then:
    ///    - A ConnectError.validation is thrown before any network call
    ///
    func testRegisterDeviceRejectsOverLengthToken() async {
        let client = AmplifyConnectClient(
            region: "us-west-2",
            endpoint: "https://example.com",
            credentialsProvider: UnusedCredentialsProvider()
        )
        do {
            try await client.registerDevice(token: String(repeating: "a", count: 256))
            XCTFail("Expected error")
        } catch let error as ConnectError {
            guard case .validation(let description, _, _) = error else {
                XCTFail("Expected validation error, got \(error)")
                return
            }
            XCTAssertTrue(description.contains("token"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Test that identifyUser rejects an over-length profile field before any network call
    ///
    /// - Given: A profile with a 256-character email
    /// - When:
    ///    - identifyUser is called
    /// - Then:
    ///    - A ConnectError.validation is thrown
    ///
    func testIdentifyUserRejectsOverLengthField() async {
        let client = AmplifyConnectClient(
            region: "us-west-2",
            endpoint: "https://example.com",
            credentialsProvider: UnusedCredentialsProvider()
        )
        do {
            try await client.identifyUser(
                userProfile: UserProfile(email: String(repeating: "a", count: 256))
            )
            XCTFail("Expected error")
        } catch let error as ConnectError {
            guard case .validation = error else {
                XCTFail("Expected validation error, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Test doubles

/// Credentials provider that fails the test if it is ever resolved.
/// Used to prove validation rejects input before any credentials or
/// network work happens.
private struct UnusedCredentialsProvider: AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        XCTFail("Credentials should not be resolved for invalid input")
        throw ConnectError.credentials("unexpected", "unexpected")
    }
}

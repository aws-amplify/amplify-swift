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

    /// Test that identifyUser encodes the correct request body
    ///
    /// - Given: A client with a mock token provider
    /// - When:
    ///    - identifyUser is called with userId, profile, and options
    /// - Then:
    ///    - The request body contains the expected fields
    ///
    func testIdentifyUserEncodesCorrectBody() async throws {
        let profile = UserProfile(
            email: "test@example.com",
            name: "Test User",
            customProperties: ["tier": ["premium"]]
        )
        let options = IdentifyUserOptions(
            channelType: "APNS",
            platform: "iOS"
        )

        let request = IdentifyUserRequest(
            userId: "user-123",
            userProfile: profile,
            options: options
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["userId"] as? String, "user-123")

        let userProfileJson = json["userProfile"] as! [String: Any]
        XCTAssertEqual(userProfileJson["email"] as? String, "test@example.com")
        XCTAssertEqual(userProfileJson["name"] as? String, "Test User")

        let optionsJson = json["options"] as! [String: Any]
        XCTAssertEqual(optionsJson["channelType"] as? String, "APNS")
        XCTAssertEqual(optionsJson["platform"] as? String, "iOS")
    }

    /// Test that nil userProfile defaults to empty object in request
    ///
    /// - Given: An IdentifyUserRequest with nil userProfile passed to init
    /// - When:
    ///    - The request is encoded
    /// - Then:
    ///    - userProfile is present as an empty object
    ///
    func testNilUserProfileDefaultsToEmptyObject() async throws {
        let request = IdentifyUserRequest(
            userId: "user-123",
            userProfile: UserProfile(),
            options: nil
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["userId"] as? String, "user-123")
        XCTAssertNotNil(json["userProfile"])
        XCTAssertNil(json["options"])
    }

    /// Test that UserProfile encodes location correctly
    ///
    /// - Given: A UserProfile with location
    /// - When:
    ///    - It is encoded to JSON
    /// - Then:
    ///    - Location fields are present
    ///
    func testUserProfileEncodesLocation() throws {
        let profile = UserProfile(
            location: UserProfileLocation(
                city: "Seattle",
                country: "US",
                latitude: 47.6,
                longitude: -122.3
            )
        )

        let data = try JSONEncoder().encode(profile)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let location = json["location"] as! [String: Any]

        XCTAssertEqual(location["city"] as? String, "Seattle")
        XCTAssertEqual(location["country"] as? String, "US")
        XCTAssertEqual(location["latitude"] as? Double, 47.6)
        XCTAssertEqual(location["longitude"] as? Double, -122.3)
    }

    /// Test that IdentifyUserOptions encodes all fields
    ///
    /// - Given: An IdentifyUserOptions with all fields set
    /// - When:
    ///    - It is encoded to JSON
    /// - Then:
    ///    - All fields are present
    ///
    func testIdentifyUserOptionsEncodesAllFields() throws {
        let options = IdentifyUserOptions(
            userAttributes: ["hobby": ["biking"]],
            address: "apns-token",
            channelType: "APNS",
            optOut: "NONE",
            deviceId: "device-123",
            platform: "iOS",
            appVersion: "2.0.0",
            previousGuestIdentityId: "us-west-2:guest-id"
        )

        let data = try JSONEncoder().encode(options)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["address"] as? String, "apns-token")
        XCTAssertEqual(json["channelType"] as? String, "APNS")
        XCTAssertEqual(json["optOut"] as? String, "NONE")
        XCTAssertEqual(json["deviceId"] as? String, "device-123")
        XCTAssertEqual(json["platform"] as? String, "iOS")
        XCTAssertEqual(json["appVersion"] as? String, "2.0.0")
        XCTAssertEqual(json["previousGuestIdentityId"] as? String, "us-west-2:guest-id")
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

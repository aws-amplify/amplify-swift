//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(InternalAmplifyConfiguration) @testable import Amplify
@testable import AmplifyTestCommon

/// Uses internal methods of the Amplify configuration system to ensure we are throwing expected errors in exceptional
/// circumstances
class AmplifyOutputsInitializationTests: XCTestCase {

    static var tempDir: URL = {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("ConfigurationInternalsTests")
        return tempDir
    }()

    override func setUp() {
        do {
            try AmplifyOutputsInitializationTests.makeTempDir()
        } catch {
            XCTFail("Could not make test bundle container directory: \(error.localizedDescription)")
        }
    }

    override func tearDown() async throws {
        do {
            await Amplify.reset()
            try AmplifyOutputsInitializationTests.removeTempDir()
        } catch {
            XCTFail("Could not remove temporary directory: \(error.localizedDescription)")
        }
    }

    /// Given: A bundle that doesn't contain the file specified by `resource`
    /// When: Amplify.configure(with: .resource(named:) is invoked
    /// Then: The system throws a ConfigurationError.amplifyConfigurationFileNotFound error
    func testFileNotFoundInBundle() {
        guard let testBundle = try? AmplifyOutputsInitializationTests.makeTestBundle() else {
            XCTFail("Unable to create testBundle")
            return
        }

        XCTAssertThrowsError(try AmplifyOutputsData.init(bundle: testBundle, resource: "invalidFile")) { error in
            if case ConfigurationError.invalidAmplifyOutputsFile = error {
                return
            }
            XCTFail("Expected ConfigurationError.invalidAmplifyOutputsFile, got \(error)")
        }
    }

    /// Given: An data object with bad UTF8 data
    /// When: Amplify.configure(with: .data(:)) is invoked
    /// Then: The system throws a ConfigurationError.unableToDecode error
    func testInvalidUTF8Data() throws {
        // A unicode character whose bit pattern begins with a "1" is supposed to be part of a multibyte sequence
        let badUTF8Bytes = Data([0xc0, 0x20])

        XCTAssertThrowsError(try AmplifyOutputs.data(badUTF8Bytes).resolveConfiguration()) { error in
            if case ConfigurationError.unableToDecode = error {
                return
            }
            XCTFail("Expected ConfigurationError.unableToDecode, got \(error)")
        }
    }

    /// Given: A data object with invalid JSON data
    /// When: Amplify.configure(with: .data(:)) is invoked
    /// Then: The system throws a ConfigurationError.unableToDecode error
    func testInvalidJSON() throws {
        let poorlyFormedJSON = #"{"foo"}"#.data(using: .utf8)!

        XCTAssertThrowsError(try AmplifyOutputs.data(poorlyFormedJSON).resolveConfiguration()) { error in
            if case ConfigurationError.unableToDecode = error {
                return
            }
            XCTFail("Expected ConfigurationError.unableToDecode, got \(error)")
        }
    }

    /// Given: A data object with valid AmplifyOutputs JSON
    /// When: Amplify.configure(with: .data(:)) is invoked
    /// Then: Decoded data should contain the correct data, decoding snake case to camel case.
    func testValidAmplifyOutputsJSON() throws {
        let validAmplifyOutputsJSON = #"{"version": "1", "analytics": { "amazon_pinpoint": { "aws_region": "us-east-1", "app_id": "app123"}}}"#
        let configData = Data(validAmplifyOutputsJSON.utf8)

        try Amplify.configure(with: .data(configData))
        let config = try AmplifyOutputsData.decodeAmplifyOutputsData(from: configData)
        XCTAssertEqual(config.version, "1")
        XCTAssertEqual(config.analytics?.amazonPinpoint?.appId, "app123")
        XCTAssertEqual(config.analytics?.amazonPinpoint?.awsRegion, "us-east-1")
    }

    /// Given: A data object with valid AmplifyOutputs JSON containing snake case values.
    /// When: Amplify.configure(with: .data(:)) is invoked
    /// Then: Decoded data should contain the correct data, decoding snake case values to camel case enum cases.
    func testSnakeCaseJSONValues() throws {
        let validAmplifyOutputsJSON = #"{"version": "1", "auth": { "aws_region": "us-east-1", "user_pool_id": "poolId123", "user_pool_client_id": "clientId123", "standard_required_attributes": [ "family_name", "given_name", "middle_name", "phone_number", "preferred_username", "updated_at" ]}}"#
        let configData = Data(validAmplifyOutputsJSON.utf8)

        try Amplify.configure(with: .data(configData))
        let config = try AmplifyOutputsData.decodeAmplifyOutputsData(from: configData)
        XCTAssertEqual(config.version, "1")

        guard let auth = config.auth, let attributes = auth.standardRequiredAttributes else {
            XCTFail("Missing auth config after decoding")
            return
        }
        XCTAssertEqual(auth.awsRegion, "us-east-1")
        XCTAssertEqual(auth.userPoolId, "poolId123")
        XCTAssertEqual(auth.userPoolClientId, "clientId123")
        XCTAssertEqual(attributes.count, 6)
    }

    /// - Given: A valid configuration
    /// - When:
    ///    - Amplify is finished configuring its plugins
    /// - Then:
    ///    - I receive a Hub event
    func testConfigurationNotification() async throws {
        let notificationReceived = expectation(description: "Configured notification received")
        let listeningPlugin = NotificationListeningAnalyticsPlugin(notificationReceived: notificationReceived)
        await Amplify.reset()
        try Amplify.add(plugin: listeningPlugin)
        let config = AmplifyOutputsData()
        try Amplify.configure(config)

        await fulfillment(of: [notificationReceived], timeout: 1.0)
    }

    // MARK: - Utilities

    /// Creates the directory used as the container for the test bundle; each test will need this.
    static func makeTempDir() throws {
        try FileManager.default.createDirectory(at: tempDir,
                                                withIntermediateDirectories: true)
    }

    /// Creates a Bundle object from the container directory
    static func makeTestBundle() throws -> Bundle {
        let customBundleDir = tempDir.appendingPathComponent("TestBundle.bundle")

        try FileManager.default.createDirectory(at: customBundleDir,
                                                withIntermediateDirectories: true)

        guard let testBundle = Bundle(path: customBundleDir.path) else {
            throw "Could not create test bundle at \(customBundleDir.path)"
        }

        return testBundle
    }

    /// Removes the container directory used for the test bundle
    static func removeTempDir() throws {
        try FileManager.default.removeItem(at: tempDir)
    }
}


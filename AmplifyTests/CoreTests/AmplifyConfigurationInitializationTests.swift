//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

/// Uses internal methods of the Amplify configuration system to ensure we are throwing expected errors in exceptional
/// circumstances
class AmplifyConfigurationInitializationTests: XCTestCase {

    static var tempDir: URL = {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("ConfigurationInternalsTests")
        return tempDir
    }()

    override func setUp() {
        do {
            try AmplifyConfigurationInitializationTests.makeTempDir()
        } catch {
            XCTFail("Could not make test bundle container directory: \(error.localizedDescription)")
        }
    }

    override func tearDown() {
        do {
            try AmplifyConfigurationInitializationTests.removeTempDir()
        } catch {
            XCTFail("Could not remove temporary directory: \(error.localizedDescription)")
        }
    }

    /// Given: A bundle that doesn't contain an `amplifyconfiguration.json` file
    /// When: Amplify.configure(bundle:) is invoked
    /// Then: The system throws a ConfigurationError.amplifyConfigurationFileNotFound error
    func testFileNotFoundInBundle() {
        guard let testBundle = try? AmplifyConfigurationInitializationTests.makeTestBundle() else {
            XCTFail("Unable to create testBundle")
            return
        }

        XCTAssertThrowsError(try AmplifyConfiguration(bundle: testBundle)) { error in
            if case ConfigurationError.invalidAmplifyConfigurationFile = error {
                return
            }
            XCTFail("Expected ConfigurationError.amplifyConfigurationFileNotFound, got \(error)")
        }
    }

    /// Given: A path to a file that does not exist
    /// When: Amplify.configure(configurationFile:) is invoked
    /// Then: The system throws a ConfigurationError.amplifyConfigurationFileNotFound error
    func testFileNotFound() {
        let configFilePath = AmplifyConfigurationInitializationTests
            .tempDir
            .appendingPathComponent("amplifyconfiguration.json")

        XCTAssertThrowsError(try AmplifyConfiguration(configurationFile: configFilePath)) { error in
            if case ConfigurationError.invalidAmplifyConfigurationFile = error {
                return
            }
            XCTFail("Expected ConfigurationError.amplifyConfigurationFileNotFound, got \(error)")
        }
    }

    /// Given: An `amplifyconfiguration.json` file with bad UTF8 data
    /// When: Amplify.configure(configurationFile:) is invoked
    /// Then: The system throws a ConfigurationError.unableToDecode error
    func testInvalidUTF8Data() throws {
        // A unicode character whose bit pattern begins with a "1" is supposed to be part of a multibyte sequence
        let badUTF8Bytes = Data([0xc0, 0x20])
        let configFilePath = AmplifyConfigurationInitializationTests
            .tempDir
            .appendingPathComponent("amplifyconfiguration.json")

        try badUTF8Bytes.write(to: configFilePath)

        XCTAssertThrowsError(try AmplifyConfiguration(configurationFile: configFilePath)) { error in
            if case ConfigurationError.unableToDecode = error {
                return
            }
            XCTFail("Expected ConfigurationError.unableToDecode, got \(error)")
        }
    }

    /// Given: An `amplifyconfiguration.json` file with invalid JSON data
    /// When: Amplify.configure(configurationFile:) is invoked
    /// Then: The system throws a ConfigurationError.unableToDecode error
    func testInvalidJSON() throws {
        let configFilePath = AmplifyConfigurationInitializationTests
            .tempDir
            .appendingPathComponent("amplifyconfiguration.json")

        let poorlyFormedJSON = #"{"foo"}"#
        let configData = poorlyFormedJSON.data(using: .utf8)!
        try configData.write(to: configFilePath)

        XCTAssertThrowsError(try AmplifyConfiguration(configurationFile: configFilePath)) { error in
            if case ConfigurationError.unableToDecode = error {
                return
            }
            XCTFail("Expected ConfigurationError.unableToDecode, got \(error)")
        }
    }

    /// Given: An `amplifyconfiguration.json` file with valid JSON data, but not in the AmplifyConfiguration structure
    /// When: Amplify.configure(configurationFile:) is invoked
    /// Then: The system returns an AmplifyConfiguration object with no populated members
    func testInvalidAmplifyConfiguration() throws {
        let configFilePath = AmplifyConfigurationInitializationTests
            .tempDir
            .appendingPathComponent("amplifyconfiguration.json")

        let poorlyFormedJSON = #"{"foo": true}"#
        let configData = poorlyFormedJSON.data(using: .utf8)!
        try configData.write(to: configFilePath)

        let amplifyConfig = try AmplifyConfiguration(configurationFile: configFilePath)

        // Use the `allCases` enum to ensure we catch newly-added categories
        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .analytics:
                XCTAssertNil(amplifyConfig.analytics)
            case .api:
                XCTAssertNil(amplifyConfig.api)
            case .auth:
                XCTAssertNil(amplifyConfig.auth)
            case .dataStore:
                // TODO assert
                XCTAssert(true)
            case .geo:
                XCTAssertNil(amplifyConfig.geo)
            case .hub:
                XCTAssertNil(amplifyConfig.hub)
            case .logging:
                XCTAssertNil(amplifyConfig.logging)
            case .predictions:
                XCTAssertNil(amplifyConfig.predictions)
            case .storage:
                XCTAssertNil(amplifyConfig.storage)
            }
        }
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

        let analyticsConfiguration = AnalyticsCategoryConfiguration(plugins: [
            "NotificationListeningAnalyticsPlugin": true
        ])
        let config = AmplifyConfiguration(analytics: analyticsConfiguration)
        try Amplify.configure(config)

        await waitForExpectations(timeout: 1.0)
    }

    // MARK: - Utilities

    /// Creates the directory used as the container for the test bundle; each test will need this.
    static func makeTempDir() throws {
        try FileManager.default.createDirectory(at: tempDir,
                                                withIntermediateDirectories: true)
    }

    /// Creates a Bundle object from the container directory
    static func makeTestBundle(withConfigFileName: Data? = nil) throws -> Bundle {
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

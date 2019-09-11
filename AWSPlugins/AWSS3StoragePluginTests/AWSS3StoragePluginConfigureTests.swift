//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginConfigureTests: AWSS3StoragePluginTests {

    func testConfigureSuccess() throws {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket), (PluginConstants.Region, region))

        do {
            try storagePlugin.configure(using: storagePluginConfig)
        } catch {
            XCTFail("Failed to configure storage plugin")
        }
    }

    func testConfigureWithDefaultAccessLevelSuccess() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let accessLevel = JSONValue.init(stringLiteral: defaultAccessLevel.rawValue)
        let storagePluginConfig = JSONValue.init(dictionaryLiteral:
            (PluginConstants.Bucket, bucket),
            (PluginConstants.Region, region),
            (PluginConstants.DefaultAccessLevel, accessLevel))

        do {
            try storagePlugin.configure(using: storagePluginConfig)
        } catch {
            XCTFail("Failed to configure storage plugin with default access level")
        }
    }

    func testConfigureThrowsErrorForMissingConfiguration() {
        XCTAssertThrowsError(try storagePlugin.configure(using: "")) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.decodeConfigurationError.errorDescription)
        }
    }

    func testConfigureThrowsErrorForMissingConfigurationObject() {
        let storagePluginConfig = JSONValue.init(stringLiteral: "notADictionaryLiteral")

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.configurationObjectExpected.errorDescription)
        }
    }

    func testConfigureThrowsErrorForMissingBucketConfig() {
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.missingBucket.errorDescription)
        }
    }

    func testConfigureThrowsForEmptyBucketValue() {
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, ""), (PluginConstants.Region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.emptyBucket.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidBucketValue() {
        let bucket = JSONValue.init(integerLiteral: 1)
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket), (PluginConstants.Region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.invalidBucket.errorDescription)
        }
    }

    func testConfigureThrowsErrorForMissingRegionConfig() {

        let bucket = JSONValue.init(stringLiteral: testBucket)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.missingRegion.errorDescription)
        }
    }

    func testConfigureThrowsErrorForMissingRegionValue() {

        let bucket = JSONValue.init(stringLiteral: testBucket)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket), (PluginConstants.Region, ""))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.missingRegion.errorDescription)
        }
    }

    func testConfigureThrowsForEmptyRegionValue() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: "")
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket), (PluginConstants.Region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.emptyRegion.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidRegionValue() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(integerLiteral: 1)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket), (PluginConstants.Region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.invalidBucket.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidRegionType() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: "invalidRegionType")
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket), (PluginConstants.Region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.invalidRegion.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidDefaultAccessLevel() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let accessLevel = JSONValue.init(stringLiteral: "invalidAccessLevel")
        let storagePluginConfig = JSONValue.init(dictionaryLiteral:
            (PluginConstants.Bucket, bucket),
            (PluginConstants.Region, region),
            (PluginConstants.DefaultAccessLevel, accessLevel))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.invalidDefaultAccessLevel.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidDefaultAccessLevelString() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let accessLevel = JSONValue.init(integerLiteral: 1)
        let storagePluginConfig = JSONValue.init(dictionaryLiteral:
            (PluginConstants.Bucket, bucket),
                                                 (PluginConstants.Region, region),
                                                 (PluginConstants.DefaultAccessLevel, accessLevel))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.invalidDefaultAccessLevel.errorDescription)
        }
    }

    func testConfigureThrowsForSpecifiedAndEmptyDefaultAccessLevel() {

        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let accessLevel = JSONValue.init(stringLiteral: "")
        let storagePluginConfig = JSONValue.init(dictionaryLiteral:
            (PluginConstants.Bucket, bucket),
            (PluginConstants.Region, region),
            (PluginConstants.DefaultAccessLevel, accessLevel))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.invalidDefaultAccessLevel.errorDescription)
        }
    }
}

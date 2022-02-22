//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginConfigureTests: AWSS3StoragePluginTests {

    // MARK: Plugin Key test
    func testPluginKey() {
        let pluginKey = storagePlugin.key
        XCTAssertEqual(pluginKey, "awsS3StoragePlugin")
    }

    // MARK: Configuration tests

    func testConfigureSuccess() throws {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.bucket, bucket), (PluginConstants.region, region))

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
            (PluginConstants.bucket, bucket),
            (PluginConstants.region, region),
            (PluginConstants.defaultAccessLevel, accessLevel))

        do {
            try storagePlugin.configure(using: storagePluginConfig)
        } catch {
            XCTFail("Failed to configure storage plugin with default access level")
        }
    }

    func testConfigureThrowsErrorForMissingConfiguration() {
        XCTAssertThrowsError(try storagePlugin.configure(using: "")) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.decodeConfigurationError.errorDescription)
        }
    }

    func testConfigureThrowsErrorForMissingConfigurationObject() {
        let storagePluginConfig = JSONValue.init(stringLiteral: "notADictionaryLiteral")

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.configurationObjectExpected.errorDescription)
        }
    }

    func testConfigureFailureForNilConfiguration() throws {
        do {
            try storagePlugin.configure(using: nil)
            XCTFail("Storage configuration should not succeed")
        } catch {
            guard let pluginError = error as? PluginError,
                case .pluginConfigurationError = pluginError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }

    func testConfigureThrowsErrorForMissingBucketConfig() {
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription, PluginErrorConstants.missingBucket.errorDescription)
        }
    }

    func testConfigureThrowsForEmptyBucketValue() {
        let region = JSONValue.init(stringLiteral: testRegion)

        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.bucket, ""), (PluginConstants.region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription, PluginErrorConstants.emptyBucket.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidBucketValue() {
        let bucket = JSONValue.init(integerLiteral: 1)
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.bucket, bucket), (PluginConstants.region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription, PluginErrorConstants.invalidBucket.errorDescription)
        }
    }

    func testConfigureThrowsErrorForMissingRegionConfig() {

        let bucket = JSONValue.init(stringLiteral: testBucket)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.bucket, bucket))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription, PluginErrorConstants.missingRegion.errorDescription)
        }
    }

    func testConfigureThrowsForEmptyRegionValue() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: "")
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.bucket, bucket), (PluginConstants.region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription, PluginErrorConstants.emptyRegion.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidRegionValue() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(integerLiteral: 1)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.bucket, bucket), (PluginConstants.region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription, PluginErrorConstants.invalidRegion.errorDescription)
        }
    }

    let isValidationRegionConfig = false

    func testConfigureThrowsForInvalidRegionType() throws {
        try XCTSkipIf(!isValidationRegionConfig, "Skipping until region validation is enabled")
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: "invalidRegionType")
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.bucket, bucket), (PluginConstants.region, region))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription, PluginErrorConstants.invalidRegion.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidDefaultAccessLevel() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let accessLevel = JSONValue.init(stringLiteral: "invalidAccessLevel")
        let storagePluginConfig = JSONValue.init(dictionaryLiteral:
            (PluginConstants.bucket, bucket),
            (PluginConstants.region, region),
            (PluginConstants.defaultAccessLevel, accessLevel))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription,
                           PluginErrorConstants.invalidDefaultAccessLevel.errorDescription)
        }
    }

    func testConfigureThrowsForInvalidDefaultAccessLevelString() {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let accessLevel = JSONValue.init(integerLiteral: 1)
        let storagePluginConfig = JSONValue.init(dictionaryLiteral:
            (PluginConstants.bucket, bucket),
            (PluginConstants.region, region),
            (PluginConstants.defaultAccessLevel, accessLevel))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription,
                           PluginErrorConstants.invalidDefaultAccessLevel.errorDescription)
        }
    }

    func testConfigureThrowsForSpecifiedAndEmptyDefaultAccessLevel() {

        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let accessLevel = JSONValue.init(stringLiteral: "")
        let storagePluginConfig = JSONValue.init(dictionaryLiteral:
            (PluginConstants.bucket, bucket),
            (PluginConstants.region, region),
            (PluginConstants.defaultAccessLevel, accessLevel))

        XCTAssertThrowsError(try storagePlugin.configure(using: storagePluginConfig)) { error in
            guard case let StorageError.configuration(_, _, underlyingError) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            guard let resolvedUnderlyingError = underlyingError else {
                XCTFail("No underlying error in error: \(error)")
                return
            }

            guard let amplifyError = resolvedUnderlyingError as? AmplifyError else {
                XCTFail("Underlying error is not an AmplifyError: \(resolvedUnderlyingError)")
                return
            }

            XCTAssertEqual(amplifyError.errorDescription,
                           PluginErrorConstants.invalidDefaultAccessLevel.errorDescription)
        }
    }
}

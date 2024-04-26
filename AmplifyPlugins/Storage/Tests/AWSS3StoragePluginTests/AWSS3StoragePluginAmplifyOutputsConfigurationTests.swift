//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable @_spi(InternalAmplifyConfiguration) import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginAmplifyOutputsConfigurationTests: AWSS3StoragePluginTests {

    func testConfigureSuccess() throws {
        do {
            let config = AmplifyOutputsData(storage: .init(
                awsRegion: testRegion,
                bucketName: testBucket))
            try storagePlugin.configure(using: config)
        } catch {
            XCTFail("Failed to configure storage plugin")
        }
    }

    func testConfigureThrowsErrorForMissingStorageCategoryConfiguration() {
        let config = AmplifyOutputsData()
        XCTAssertThrowsError(try storagePlugin.configure(using: config)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }

            XCTAssertEqual(errorDescription, PluginErrorConstants.missingStorageCategoryConfiguration.errorDescription)
        }
    }

    func testConfigureThrowsForEmptyBucketValue() {
        let config = AmplifyOutputsData(storage: .init(
            awsRegion: testRegion,
            bucketName: ""))
        XCTAssertThrowsError(try storagePlugin.configure(using: config)) { error in
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

    func testConfigureThrowsForEmptyRegionValue() {
        let config = AmplifyOutputsData(storage: .init(
            awsRegion: "",
            bucketName: testBucket))
        XCTAssertThrowsError(try storagePlugin.configure(using: config)) { error in
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

    let isValidationRegionConfig = false

    func testConfigureThrowsForInvalidRegionType() throws {
        try XCTSkipIf(!isValidationRegionConfig, "Skipping until region validation is enabled")
        let config = AmplifyOutputsData(storage: .init(
            awsRegion: "invalidRegionType",
            bucketName: testBucket))

        XCTAssertThrowsError(try storagePlugin.configure(using: config)) { error in
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
}


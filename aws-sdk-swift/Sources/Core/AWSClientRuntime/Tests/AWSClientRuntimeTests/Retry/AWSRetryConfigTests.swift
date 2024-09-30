//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable @_spi(FileBasedConfig) import AWSClientRuntime
@_spi(FileBasedConfig) @testable import AWSSDKCommon

class AWSRetryConfigTests: XCTestCase {
    var fileBasedConfig: FileBasedConfiguration = try! CRTFileBasedConfiguration(
        configFilePath: Bundle.module.path(forResource: "retry_config_tests", ofType: nil)!,
        credentialsFilePath: nil
    )

    // MARK: - Retry mode

    func test_retryMode_resolvesAConfigValue() throws {
        let subject = AWSRetryConfig.retryMode(configValue: .adaptive, profileName: nil, fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, .adaptive)
    }

    func test_retryMode_resolvesDefaultProfile() throws {
        let subject = AWSRetryConfig.retryMode(configValue: nil, profileName: nil, fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, .adaptive)
    }

    func test_retryMode_resolvesSpecifiedProfile() throws {
        let subject = AWSRetryConfig.retryMode(configValue: nil, profileName: "retry-config-test", fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, .legacy)
    }

    func test_retryMode_defaultsToLegacy() throws {
        let subject = AWSRetryConfig.retryMode(configValue: nil, profileName: "no-such-profile", fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, .legacy)
    }

    // MARK: - Max attempts

    func test_maxAttempts_resolvesAConfigValue() throws {
        let subject = AWSRetryConfig.maxAttempts(configValue: 8, profileName: nil, fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, 8)
    }

    func test_maxAttempts_resolvesDefaultProfile() throws {
        let subject = AWSRetryConfig.maxAttempts(configValue: nil, profileName: nil, fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, 10)
    }

    func test_maxAttempts_resolvesSpecifiedProfile() throws {
        let subject = AWSRetryConfig.maxAttempts(configValue: nil, profileName: "retry-config-test", fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, 20)
    }

    func test_maxAttempts_defaultsToThree() throws {
        let subject = AWSRetryConfig.maxAttempts(configValue: nil, profileName: "no-such-profile", fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, 3)
    }
}

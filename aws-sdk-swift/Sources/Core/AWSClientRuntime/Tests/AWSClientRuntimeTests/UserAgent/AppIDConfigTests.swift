//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable @_spi(FileBasedConfig) import AWSClientRuntime
@_spi(FileBasedConfig) @testable import AWSSDKCommon
import XCTest

class AppIDConfigTests: XCTestCase {
    let configAppID = "passed-app-id"
    let envAppID = "env-app-id"
    // These match the test config file named app_id_config_tests
    let defaultProfileAppID = "default-app-id"
    let customProfileName = "app-id-config-test"
    let customProfileAppID = "custom-profile-app-id"

    var fileBasedConfig: FileBasedConfiguration = try! CRTFileBasedConfiguration(
        configFilePath: Bundle.module.path(forResource: "app_id_config_tests", ofType: nil)!,
        credentialsFilePath: nil
    )

    func test_appID_resolvesFromConfigAppID() {
        setenv("AWS_SDK_UA_APP_ID", envAppID, 1)
        let subject = AppIDConfig.appID(configValue: configAppID, profileName: nil, fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, configAppID)
    }

    func test_appID_resolvesFromEnvironmentVar() {
        setenv("AWS_SDK_UA_APP_ID", envAppID, 1)
        let subject = AppIDConfig.appID(configValue: nil, profileName: nil, fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, envAppID)
    }

    func test_appID_resolvesFromDefaultProfile() {
        unsetenv("AWS_SDK_UA_APP_ID")
        let subject = AppIDConfig.appID(configValue: nil, profileName: customProfileName, fileBasedConfig: fileBasedConfig)
        XCTAssertEqual(subject, customProfileAppID)
    }
}

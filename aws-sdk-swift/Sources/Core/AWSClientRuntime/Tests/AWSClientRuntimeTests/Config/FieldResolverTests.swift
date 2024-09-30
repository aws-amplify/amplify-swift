//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable @_spi(FileBasedConfig) import AWSClientRuntime
@testable @_spi(FileBasedConfig) import AWSSDKCommon

class FieldResolverTests: XCTestCase {
    let envVarName = "TEST_ENV_VAR_NAME"
    let configFieldName = "config_field_name"
    var fileBasedConfig: FileBasedConfiguration = try! CRTFileBasedConfiguration(
        configFilePath: Bundle.module.path(forResource: "field_resolver_tests", ofType: nil)!,
        credentialsFilePath: nil
    )

    func test_value_itReturnsTheConfigValue() {
        let expected = Int.random(in: 1...Int.max)
        let subject = FieldResolver(configValue: expected, envVarName: envVarName, configFieldName: configFieldName, fileBasedConfig: fileBasedConfig, profileName: nil, converter: { Int($0) })
        XCTAssertEqual(subject.value, expected)
    }

    func test_value_itReturnsTheEnvironmentValueWhenNoConfigValueIsSet() {
        let expected = Int.random(in: Int.min...Int.max)
        setenv(envVarName, "\(expected)", 1)
        let subject = FieldResolver(configValue: nil, envVarName: envVarName, configFieldName: configFieldName, fileBasedConfig: fileBasedConfig, profileName: nil, converter: { Int($0) })
        XCTAssertEqual(subject.value, expected)
        unsetenv(envVarName)
    }

    func test_value_itReturnsTheConfigFileValueFromTheDefaultProfileWhenNoConfigProfileOrEnvProfileIsSet() {
        let expected = 123
        let subject = FieldResolver(configValue: nil, envVarName: envVarName, configFieldName: configFieldName, fileBasedConfig: fileBasedConfig, profileName: nil, converter: { Int($0) })
        XCTAssertEqual(subject.value, expected)
    }

    func test_value_itReturnsTheConfigFileValueFromAltProfile1WhenProfileSpecifiedInParam() {
        let expected = 456
        let subject = FieldResolver(configValue: nil, envVarName: envVarName, configFieldName: configFieldName, fileBasedConfig: fileBasedConfig, profileName: "alt-profile-1", converter: { Int($0) })
        XCTAssertEqual(subject.value, expected)
    }

    func test_value_itReturnsTheConfigFileValueFromAltProfile2WhenProfileSpecifiedInEnvVar() {
        let expected = 789
        setenv("AWS_PROFILE", "alt-profile-2", 1)
        let subject = FieldResolver(configValue: nil, envVarName: envVarName, configFieldName: configFieldName, fileBasedConfig: fileBasedConfig, profileName: nil, converter: { Int($0) })
        XCTAssertEqual(subject.value, expected)
        unsetenv("AWS_PROFILE")
    }

    func test_value_itReturnsNilWhenNoSourceIsSet() {
        let subject = FieldResolver(configValue: nil, envVarName: envVarName, configFieldName: configFieldName, fileBasedConfig: fileBasedConfig, profileName: "no-such-profile", converter: { Int($0) })
        XCTAssertNil(subject.value)
    }
}

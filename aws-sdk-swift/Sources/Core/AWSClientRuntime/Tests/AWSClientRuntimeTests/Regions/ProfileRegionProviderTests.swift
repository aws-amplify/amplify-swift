//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import SmithyTestUtil
import XCTest
@_spi(DefaultRegionResolver) @testable import AWSClientRuntime
@_spi(FileBasedConfig) @testable import AWSSDKCommon

class ProfileRegionProviderTests: XCTestCase {
    
    let configPath = Bundle.module.path(forResource: "profile_region_provider_tests", ofType: nil)!
    
    let fileBasedConfigProvider: FileBasedConfigurationProviding = { configPath, credentialsPath in
        try CRTFileBasedConfiguration.make(configFilePath: configPath, credentialsFilePath: credentialsPath)
    }
    
    func testProfileRegionProviderUsesDefaultProfileWhenNil() async {
        let provider = ProfileRegionProvider(
            fileBasedConfigurationProvider: fileBasedConfigProvider,
            configFilePath: configPath
        )
        let region = try! await provider.getRegion()
        XCTAssertEqual(region, "us-east-2")
    }
    
    func testProfileRegionProviderUsesPassedInProfile() async {
        let provider = ProfileRegionProvider(
            fileBasedConfigurationProvider: fileBasedConfigProvider,
            profileName: "west",
            configFilePath: configPath
        )
        let region = try! await provider.getRegion()
        XCTAssertEqual(region, "us-west-2")
    }
    
    func testProfileRegionProviderWorksWithCredentialsFile() async {
        let provider = ProfileRegionProvider(
            fileBasedConfigurationProvider: { configPath, credentialsPath in
               try CRTFileBasedConfiguration(configFilePath: configPath, credentialsFilePath: credentialsPath)
            },
            credentialsFilePath: configPath
        )
        let region = try! await provider.getRegion()
        XCTAssertEqual(region, "us-east-2")
    }
}

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
@_spi(FileBasedConfig) import AWSSDKCommon

class DefaultRegionResolverTests: XCTestCase {
    
    let configPath = Bundle.module.path(forResource: "profile_region_provider_tests", ofType: nil)!
    
    let fileBasedConfigProvider: FileBasedConfigurationProviding = { configPath, credentialsPath in
        try CRTFileBasedConfiguration.make(configFilePath: configPath, credentialsFilePath: credentialsPath)
    }
    
    func testItResolvesFromEnvironment() async {
        setenv("AWS_REGION", "us-west-1", 1)
        defer {
            unsetenv("AWS_REGION")
        }
        
        do {
            let resolver = try DefaultRegionResolver(
                fileBasedConfigurationProvider: fileBasedConfigProvider
            )
            let region = await resolver.getRegion()
            XCTAssertEqual(region, "us-west-1")
        } catch {
            XCTFail("Failed to resolve region")
        }
    }
    
    func testItResolvesFromProfile() async {
        setenv("AWS_CONFIG_FILE", configPath, 1)
        // unset the region env var, otherwise the region provider will use the region from the env var instead of the profile
        unsetenv("AWS_REGION")
        defer {
            unsetenv("AWS_CONFIG_FILE")
        }
        
        do {
            let resolver = try DefaultRegionResolver(
                fileBasedConfigurationProvider: fileBasedConfigProvider
            )
            let region = await resolver.getRegion()
            XCTAssertEqual(region, "us-east-2")
        } catch {
            XCTFail("Failed to resolve region")
        }
    }
}

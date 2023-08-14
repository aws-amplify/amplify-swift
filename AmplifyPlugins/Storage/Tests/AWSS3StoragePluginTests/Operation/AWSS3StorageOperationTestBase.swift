//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin
@testable import AWSPluginsTestCommon
import AWSS3

class AWSS3StorageOperationTestBase: XCTestCase {
    
    var hubPlugin: MockHubCategoryPlugin!
    var mockStorageService: MockAWSS3StorageService!
    var mockAuthService: MockAWSAuthService!
    
    let testKey = "TestKey"
    let testTargetIdentityId = "TestTargetIdentityId"
    let testIdentityId = "TestIdentityId"
    let testPath = "TestPath"
    let testData = Data()
    let testContentType = "TestContentType"
    let testExpires = 10
    let testURL = URL(fileURLWithPath: "path")
    let testStorageConfiguration = AWSS3StoragePluginConfiguration()
    
    override func setUp() {
        let mockAmplifyConfig = AmplifyConfiguration()
        
        do {
            try Amplify.configure(mockAmplifyConfig)
        } catch let error as AmplifyError {
            XCTFail("setUp failed with error: \(error); \(error.errorDescription); \(error.recoverySuggestion)")
        } catch {
            XCTFail("setup failed with unknown error")
        }
        
        mockStorageService = MockAWSS3StorageService()
        mockAuthService = MockAWSAuthService()
    }
    
    override func tearDown() async throws {
        await Amplify.reset()
    }
}

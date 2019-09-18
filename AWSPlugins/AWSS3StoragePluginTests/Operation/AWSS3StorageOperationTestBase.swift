//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin
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

    override func setUp() {
        let hubConfig = HubCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )
        hubPlugin = MockHubCategoryPlugin()
        let mockAmplifyConfig = AmplifyConfiguration(hub: hubConfig)

        do {
            try Amplify.add(plugin: hubPlugin)
            try Amplify.configure(mockAmplifyConfig)
        } catch let error as AmplifyError {
            XCTFail("setUp failed with error: \(error); \(error.errorDescription); \(error.recoverySuggestion)")
        } catch {
            XCTFail("setup failed with unknown error")
        }

        //        let methodWasInvokedOnHubPlugin = expectation(
        //            description: "method was invoked on hub plugin")
        //        hubPlugin.listeners.append { message in
        //            if message == "dispatch(to:payload:)" {
        //                methodWasInvokedOnHubPlugin.fulfill()
        //            }
        //        }

        mockStorageService = MockAWSS3StorageService()
        mockAuthService = MockAWSAuthService()
    }

    override func tearDown() {
        Amplify.reset()
    }

}

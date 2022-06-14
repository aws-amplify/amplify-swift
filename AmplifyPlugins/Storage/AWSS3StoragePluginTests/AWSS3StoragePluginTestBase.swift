//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin
@testable import AmplifyTestCommon
@testable import AWSPluginsTestCommon

class AWSS3StoragePluginTests: XCTestCase {
    var storagePlugin: AWSS3StoragePlugin!
    var storageService: MockAWSS3StorageService!
    var authService: MockAWSAuthService!
    var queue: MockOperationQueue!
    let testKey = "key"
    let testBucket = "bucket"
    let testRegion = "us-east-1"
    let defaultAccessLevel: StorageAccessLevel = .guest
    let testIdentityId = "TestIdentityId"
    let testContentType = "TestContentType"
    let testURL = URL(fileURLWithPath: "fileURLWithPath")
    let testData = Data()
    let testPath = "TestPath"
    let testExpires = 10

    override func setUp() async throws {
        storagePlugin = AWSS3StoragePlugin()
        storageService = MockAWSS3StorageService()
        authService = MockAWSAuthService()
        queue = MockOperationQueue()

        storagePlugin.configure(storageService: storageService,
                                authService: authService,
                                defaultAccessLevel: defaultAccessLevel,
                                queue: queue)
    }
}

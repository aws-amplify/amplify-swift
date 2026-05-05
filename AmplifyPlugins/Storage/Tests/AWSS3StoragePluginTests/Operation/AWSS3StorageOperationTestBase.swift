//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsTestCommon
@testable import AWSS3StoragePlugin

/// Serializes global `Amplify.reset` / `configure` across operation unit tests. Concurrent calls can leave
/// `Hub` in `pendingConfiguration` while other code dispatches Hub events.
private actor AmplifyOperationTestsGlobalConfig {
    func resetThenConfigureForUnitTests() async throws {
        await Amplify.reset()
        try Amplify.configure(AmplifyConfiguration())
    }

    func reset() async {
        await Amplify.reset()
    }
}

private let amplifyOperationTestsGlobalConfig = AmplifyOperationTestsGlobalConfig()

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

    override func setUp() async throws {
        // Always reset + configure here. Do not call `Amplify.reset()` from `tearDown`: XCTest can run the next
        // test's `setUp` before the previous `tearDown` finishes, so a late `reset()` can leave Hub in
        // `pendingConfiguration` while the new test dispatches to Hub (fatal in HubCategory.plugin).
        try await amplifyOperationTestsGlobalConfig.resetThenConfigureForUnitTests()

        mockStorageService = MockAWSS3StorageService()
        mockAuthService = MockAWSAuthService()
    }

    override func tearDown() async throws {
        mockStorageService = nil
        mockAuthService = nil
    }
}

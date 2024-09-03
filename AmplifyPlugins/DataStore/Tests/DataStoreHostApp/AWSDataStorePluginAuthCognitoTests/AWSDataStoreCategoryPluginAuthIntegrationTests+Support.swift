//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import XCTest
#if !os(watchOS)
import DataStoreHostApp
#endif

extension AWSDataStoreCategoryPluginAuthIntegrationTests {
    func saveModel(_ model: some Model) async throws {
        let localSaveInvoked = expectation(description: "local model was saved")
        Task {
            do {
                let savedposts = try await Amplify.DataStore.save(model)
                print("Local model was saved: \(savedposts)")
                localSaveInvoked.fulfill()
            } catch {
                XCTFail("Failed to save model \(error)")
                throw error
            }
        }
        await fulfillment(of: [localSaveInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}

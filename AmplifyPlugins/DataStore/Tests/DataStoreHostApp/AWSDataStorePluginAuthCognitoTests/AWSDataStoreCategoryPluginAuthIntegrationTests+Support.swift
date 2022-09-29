//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import Amplify
import DataStoreHostApp

extension AWSDataStoreCategoryPluginAuthIntegrationTests {
    func saveModel<T: Model>(_ model: T) async throws {
        let localSaveInvoked = expectation(description: "local model was saved")
        Task {
            do {
                let savedposts = try await Amplify.DataStore.save(model)
                print("Local model was saved: \(savedposts)")
                await localSaveInvoked.fulfill()
            } catch {
                XCTFail("Failed to save model \(error)")
                throw error
            }
        }
        wait(for: [localSaveInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}

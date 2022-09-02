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
        do {
            let savedposts = try await Amplify.DataStore.save(model)
            print("Local model was saved: \(savedposts)")
        } catch {
            XCTFail("Failed to save model \(error)")
        }
    }
}

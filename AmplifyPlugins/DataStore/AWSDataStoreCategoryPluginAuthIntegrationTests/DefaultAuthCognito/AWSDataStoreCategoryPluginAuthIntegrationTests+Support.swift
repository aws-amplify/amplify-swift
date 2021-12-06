//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import Amplify

@testable import AmplifyTestCommon

extension AWSDataStoreCategoryPluginAuthIntegrationTests {
    func saveModel<T: Model>(_ model: T) {
        let localSaveInvoked = expectation(description: "local model was saved")
        Amplify.DataStore.save(model) { result in
            switch result {
            case .success(let todo):
                localSaveInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to save model \(error)")
            }
        }
        wait(for: [localSaveInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}

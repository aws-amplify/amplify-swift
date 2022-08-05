//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin

class LocalStoreIntegrationTestBase: XCTestCase {

    func setUp(withModels models: AmplifyModelRegistration) {

        continueAfterFailure = false

        do {
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() async throws {
        let clearComplete = expectation(description: "clear completed")
        Amplify.DataStore.clear { _ in
            clearComplete.fulfill()
        }
        await waitForExpectations(timeout: 10)
        await Amplify.reset()
    }

}

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

    override func setUp() async throws {
        await Amplify.reset()
    }
    
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
        try await Amplify.DataStore.clear()
        await Amplify.reset()
    }

}

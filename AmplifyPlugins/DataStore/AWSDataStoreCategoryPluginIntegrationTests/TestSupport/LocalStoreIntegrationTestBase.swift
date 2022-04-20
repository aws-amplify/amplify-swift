//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

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

    override func tearDown() {
        Amplify.DataStore.clear(completion: { _ in })
        Amplify.reset()
    }

}

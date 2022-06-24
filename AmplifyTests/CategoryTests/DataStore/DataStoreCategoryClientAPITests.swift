//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class DataStoreCategoryClientAPITests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() async throws {
        await Amplify.reset()

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)
    }

    // MARK: - Test passthrough delegations

    func testSave() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "save" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.DataStore.save(TestModel.make()) { _ in }

        waitForExpectations(timeout: 0.5)
    }

}

class TestModel: Model {
    static func make() -> TestModel {
        return TestModel(id: UUID().uuidString)
    }

    let id: Identifier
    init(id: Identifier) {
        self.id = id
    }
}

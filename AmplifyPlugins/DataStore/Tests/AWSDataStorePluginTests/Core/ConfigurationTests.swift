//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSAPICategoryPluginConfigureTests: XCTestCase, @unchecked Sendable {

    func testConfigureSuccessForNilConfiguration() throws {
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(
            modelRegistration: TestModelRegistration(),
            storageEngineBehaviorFactory: MockStorageEngineBehavior.mockStorageEngineBehaviorFactory,
            dataStorePublisher: dataStorePublisher,
            validAPIPluginKey: "MockAPICategoryPlugin",
            validAuthPluginKey: "MockAuthCategoryPlugin"
        )
        do {
            try plugin.configure(using: nil)

        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
    }
}

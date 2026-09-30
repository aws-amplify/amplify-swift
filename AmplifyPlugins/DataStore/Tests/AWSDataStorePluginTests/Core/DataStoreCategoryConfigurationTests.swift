//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSDataStorePlugin
import XCTest
@testable import Amplify

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSDataStorePluginConfigurationTests: XCTestCase, @unchecked Sendable {

    override func setUp() async throws {
        await Amplify.reset()
    }

    #if os(watchOS)
    func testSubscriptionDisabledTrue() throws {
        XCTAssertTrue(DataStoreConfiguration.subscriptionsDisabled.disableSubscriptions())
    }
    #endif

    func testDoesNotThrowOnMissingConfig() throws {
        #if os(watchOS)
        let plugin = AWSDataStorePlugin(
            modelRegistration: TestModelRegistration(),
            configuration: .subscriptionsDisabled
        )
        #else
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration())

        #endif
        try Amplify.add(plugin: plugin)

        let categoryConfig = DataStoreCategoryConfiguration(plugins: ["NonExistentPlugin": true])
        let amplifyConfig = AmplifyConfiguration(dataStore: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw even if not supplied with a plugin-specific config.")
        }
    }

}

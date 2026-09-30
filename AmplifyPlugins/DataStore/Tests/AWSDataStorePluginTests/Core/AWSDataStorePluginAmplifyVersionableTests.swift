//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSDataStorePlugin
import XCTest
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSDataStorePluginAmplifyVersionableTests: XCTestCase, @unchecked Sendable {

    func testVersionExists() {
        #if os(watchOS)
        let plugin = AWSDataStorePlugin(
            modelRegistration: AmplifyModels(),
            configuration: .subscriptionsDisabled
        )
        #else
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
        #endif
        XCTAssertNotNil(plugin.version)
    }

}

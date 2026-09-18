//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

#if os(iOS) && !os(visionOS)
// swiftlint:disable:next type_name
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class PersistentLoggingPluginAmplifyVersionableTests: XCTestCase, @unchecked Sendable {

    func testVersionExists() {
        let plugin = PersistentLoggingPlugin(plugin: AWSUnifiedLoggingPlugin())
        XCTAssertNotNil(plugin.version)
    }

}
#endif

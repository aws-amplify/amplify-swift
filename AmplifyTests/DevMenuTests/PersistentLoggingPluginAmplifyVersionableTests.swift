//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

#if canImport(UIKit)
// swiftlint:disable:next type_name
class PersistentLoggingPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = PersistentLoggingPlugin(plugin: AWSUnifiedLoggingPlugin())
        XCTAssertNotNil(plugin.version)
    }

}
#endif

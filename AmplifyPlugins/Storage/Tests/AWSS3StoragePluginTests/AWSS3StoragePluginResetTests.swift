//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginResetTests: AWSS3StoragePluginTests {

    func testReset() async {
        let resettable = storagePlugin as Resettable
        await resettable.reset()

        XCTAssertNil(storagePlugin.authService)
        XCTAssertNil(storagePlugin.storageService)
        XCTAssertNil(storagePlugin.queue)
    }
}

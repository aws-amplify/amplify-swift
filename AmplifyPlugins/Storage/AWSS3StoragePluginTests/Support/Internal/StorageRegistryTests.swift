//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class MockStorageBackgroundEventsHandler: StorageBackgroundEventsHandler {
    var backgroundEventCompletionHandler: (() -> Void)?
}

class StorageRegistryTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testRegisteringAndRunningHandler() throws {
        let exp = expectation(description: #function)

        let identifier = UUID().uuidString
        let handler = MockStorageBackgroundEventsHandler()
        let completionHandler: () -> Void = {
            exp.fulfill()
        }

        StorageRegistry.register(identifier: identifier, backgroundEventsHandler: handler)

        let handled = StorageRegistry.handleBackgroundEvent(identifier: identifier, completionHandler: completionHandler)

        XCTAssertTrue(handled)

        XCTAssertNotNil(StorageRegistry.findCompletionHandler(for: identifier))

        guard let handler = StorageRegistry.findCompletionHandler(for: identifier) else {
            XCTFail()
            return
        }

        // run handler
        handler()

        wait(for: [exp], timeout: 1.0)
    }

    func testRegisteringAndUnregister() throws {
        let identifier = UUID().uuidString
        let handler = MockStorageBackgroundEventsHandler()
        handler.backgroundEventCompletionHandler = {}

        StorageRegistry.register(identifier: identifier, backgroundEventsHandler: handler)

        XCTAssertNotNil(StorageRegistry.findCompletionHandler(for: identifier))

        StorageRegistry.unregister(identifier: identifier)

        XCTAssertNil(StorageRegistry.findCompletionHandler(for: identifier))
    }

}

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

class StorageBackgroundEventsRegistryTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testRegisteringAndRunningHandler() throws {
        let exp = expectation(description: #function)

        let identifier = UUID().uuidString
        var called = false
        let backgroundEventCompletionHandler: StorageBackgroundEventsRegistry.StorageBackgroundEventsHandler = {
            called = true
            exp.fulfill()
        }

        StorageBackgroundEventsRegistry.register(identifier: identifier)

        let handled = StorageBackgroundEventsRegistry.handleBackgroundEvent(identifier: identifier, completionHandler: backgroundEventCompletionHandler)

        XCTAssertTrue(handled)

        XCTAssertNotNil(StorageBackgroundEventsRegistry.findCompletionHandler(for: identifier))

        guard let handler = StorageBackgroundEventsRegistry.findCompletionHandler(for: identifier) else {
            XCTFail()
            return
        }

        // run handler
        handler()

        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(called)
    }

    func testRegisteringAndUnregister() throws {
        let identifier = UUID().uuidString
        let backgroundEventCompletionHandler: StorageBackgroundEventsRegistry.StorageBackgroundEventsHandler = {
            }

        StorageBackgroundEventsRegistry.register(identifier: identifier)
        let handled = StorageBackgroundEventsRegistry.handleBackgroundEvent(identifier: identifier, completionHandler: backgroundEventCompletionHandler)

        XCTAssertTrue(handled)
        XCTAssertNotNil(StorageBackgroundEventsRegistry.findCompletionHandler(for: identifier))

        StorageBackgroundEventsRegistry.removeCompletionHandler(for: identifier)

        XCTAssertNil(StorageBackgroundEventsRegistry.findCompletionHandler(for: identifier))
    }

    func testHandlingUnregisteredIdentifier() throws {
        let identifier = UUID().uuidString
        let backgroundEventCompletionHandler: StorageBackgroundEventsRegistry.StorageBackgroundEventsHandler = {
            }

        let handled = StorageBackgroundEventsRegistry.handleBackgroundEvent(identifier: identifier, completionHandler: backgroundEventCompletionHandler)

        XCTAssertFalse(handled)
    }

}

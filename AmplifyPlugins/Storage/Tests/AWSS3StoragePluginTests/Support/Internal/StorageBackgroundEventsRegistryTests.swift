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

    func testRegisteringAndUnregister() async throws {
        let identifier = UUID().uuidString
        let otherIdentifier = UUID().uuidString
        StorageBackgroundEventsRegistry.register(identifier: identifier)

        let done = expectation(description: "done")
        done.expectedFulfillmentCount = 2

        Task {
            let handled = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(identifier: identifier, continuation: continuation)
                done.fulfill()
            }
            XCTAssertTrue(handled)
        }

        Task {
            let otherHandled = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(identifier: otherIdentifier, continuation: continuation)
                done.fulfill()
            }
            XCTAssertFalse(otherHandled)
        }

        await fulfillment(of: [done])

        handleEvents(for: identifier)
        handleEvents(for: otherIdentifier)
    }

    func testHandlingUnregisteredIdentifier() async throws {
        let identifier = UUID().uuidString
        let otherIdentifier = UUID().uuidString
        StorageBackgroundEventsRegistry.register(identifier: otherIdentifier)

        let done = expectation(description: "done")

        Task {
            let handled = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(identifier: identifier, continuation: continuation)
                done.fulfill()
            }
            XCTAssertFalse(handled)
        }

        await fulfillment(of: [done])
    }

    // Simulates URLSessionDelegate behavior
    func handleEvents(for identifier: String) {
        if let continuation = StorageBackgroundEventsRegistry.getContinuation(for: identifier) {
            continuation.resume(returning: true)
        }
    }

}

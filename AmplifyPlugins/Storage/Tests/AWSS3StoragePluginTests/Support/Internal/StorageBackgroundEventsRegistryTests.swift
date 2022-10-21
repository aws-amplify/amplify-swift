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
        await StorageBackgroundEventsRegistry.shared.register(identifier: identifier)

        let notificationCenter = NotificationCenter()
        await StorageBackgroundEventsRegistry.shared.change(notificationCenter: notificationCenter)
        defer {
            Task {
                await StorageBackgroundEventsRegistry.shared.change(notificationCenter: nil)
            }
        }

        let done = asyncExpectation(description: "done")
        let waiting = asyncExpectation(description: "waiting")

        notificationCenter.addObserver(forName: Notification.Name.StorageBackgroundEventsRegistryWaiting, object: nil, queue: nil) { notification in
            guard let notificationIdentifier = notification.object as? String else {
                XCTFail("Identifier not defined")
                return
            }
            XCTAssertEqual(notificationIdentifier, identifier)
            Task {
                await waiting.fulfill()
            }
        }

        Task {
            let handled = await StorageBackgroundEventsRegistry.shared.handleEventsForBackgroundURLSession(identifier: identifier)
            await done.fulfill()
            XCTAssertTrue(handled)
        }

        await waitForExpectations([waiting])

        let didContinue = await handleEvents(for: identifier)
        XCTAssertTrue(didContinue)
        await waitForExpectations([done])

        let otherDone = asyncExpectation(description: "other done")

        Task {
            let otherHandled = await StorageBackgroundEventsRegistry.shared.handleEventsForBackgroundURLSession(identifier: otherIdentifier)
            await otherDone.fulfill()
            XCTAssertFalse(otherHandled)
        }

        let didNotContinue = await handleEvents(for: otherIdentifier)
        XCTAssertFalse(didNotContinue)
        await waitForExpectations([otherDone])
    }

    func testHandlingUnregisteredIdentifier() async throws {
        let identifier = UUID().uuidString
        let otherIdentifier = UUID().uuidString
        await StorageBackgroundEventsRegistry.shared.register(identifier: otherIdentifier)

        let done = asyncExpectation(description: "done")

        Task {
            let handled = await StorageBackgroundEventsRegistry.shared.handleEventsForBackgroundURLSession(identifier: identifier)
            await done.fulfill()
            XCTAssertFalse(handled)
        }

        await waitForExpectations([done])
    }

    // Simulates URLSessionDelegate behavior
    func handleEvents(for identifier: String) async -> Bool {
        await Task.yield()

        if let continuation = await StorageBackgroundEventsRegistry.shared.getContinuation(for: identifier) {
            continuation.resume(returning: true)
            await StorageBackgroundEventsRegistry.shared.removeContinuation(for: identifier)
            return true
        } else {
            print("No continuation for identifier: \(identifier)")
            return false
        }
    }

}

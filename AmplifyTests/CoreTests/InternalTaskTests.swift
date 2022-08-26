//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class InternalTaskTests: XCTestCase {

    func testRandomEmojiTaskRunner() async throws {
        let done = asyncExpectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = RandomEmojiRequest(total: total, delay: delay)
        let runner = RandomEmojiTaskRunner(request: request)
        let task = Task {
            var emojis = [String]()
            var thrown: Error?
            do {
                try await runner.sequence.forEach { emoji in
                    emojis.append(emoji)
                }
                await done.fulfill()
                XCTAssertEqual(total, emojis.count)
            } catch {
                thrown = error
            }
            XCTAssertNil(thrown)
            return emojis
        }

        let output = await task.value
        XCTAssertEqual(request.total, output.count)

        await waitForExpectations([done], timeout: timeout)
    }

    // needs attention
    func testRandomEmojiTaskRunnerWithRunnerCancellation() async throws {
        let done = asyncExpectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = RandomEmojiRequest(total: total, delay: delay)
        let runner = RandomEmojiTaskRunner(request: request)
        // must retain sequence because it is the only strong reference
        let sequence = runner.sequence
        let task = Task {
            var emojis = [String]()
            var thrown: Error?
            do {
                try await sequence.forEach { emoji in
                    emojis.append(emoji)
                }
                await done.fulfill()
                XCTAssertEqual(0, emojis.count)
            } catch {
                thrown = error
            }
            XCTAssertNil(thrown)
            return emojis
        }

        runner.cancel()

        let output = await task.value
        XCTAssertEqual(0, output.count)

        await waitForExpectations([done], timeout: timeout)
    }

    func testRandomEmojiTaskRunnerWithSequenceCancellation() async throws {
        let done = asyncExpectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = RandomEmojiRequest(total: total, delay: delay)
        let runner = RandomEmojiTaskRunner(request: request)
        let task = Task {
            var emojis = [String]()
            var thrown: Error?
            do {
                let sequence = runner.sequence
                sequence.cancel()
                try await sequence.forEach { emoji in
                    emojis.append(emoji)
                }
                await done.fulfill()
                XCTAssertEqual(0, emojis.count)
            } catch {
                thrown = error
            }
            XCTAssertNil(thrown)
            return emojis
        }

        let output = await task.value
        XCTAssertEqual(0, output.count)

        await waitForExpectations([done], timeout: timeout)
    }

    func testPluginAPI() async throws {
        let done = asyncExpectation(description: "done")
        let total = 10
        let delay = 0.01
        let timeout = Double(total) * 2.0 * delay
        let plugin = EmojisPlugin()
        let task = Task {
            var count = 0
            var emojis = [String]()
            try await plugin.getEmojis(total: total, delay: delay).forEach { emoji in
                count += 1
                emojis.append(emoji)
            }
            await done.fulfill()
            XCTAssertEqual(total, emojis.count)
            return count
        }

        let count = try await task.value
        XCTAssertEqual(count, total)

        await waitForExpectations([done], timeout: timeout)
    }

}

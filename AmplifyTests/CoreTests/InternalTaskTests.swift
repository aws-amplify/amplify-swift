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
    
    override func setUp() async throws {
        await Amplify.reset()
    }

    // MARK: - Magic Eight Ball (Non-Throwing) -

    func testMagicEightBallTaskRunner() async throws {

        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = MagicEightBallRequest(total: total, delay: delay)
        let runner = MagicEightBallTaskRunner(request: request)
        let task = Task<[String], Never> {
            let hubDone = expectation(description: "hub done")
            var emojis = [String]()
            var hubValues = [String]()
            let token = runner.subscribe { emoji in
                hubValues.append(emoji)
                if hubValues.count == total {
                    hubDone.fulfill()
                }
            }
            await runner.sequence.forEach { emoji in
                emojis.append(emoji)
            }
            await waitForExpectations(timeout: 1)
            XCTAssertEqual(total, hubValues.count)
            XCTAssertEqual(total, emojis.count)
            runner.unsubscribe(token)
            return emojis
        }

        let output = await task.value
        XCTAssertEqual(request.total, output.count)
    }

    func testMagicEightBallTaskRunnerWithRunnerCancellation() async throws {
        let done = expectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = MagicEightBallRequest(total: total, delay: delay)
        let runner = MagicEightBallTaskRunner(request: request)
        // must retain sequence because it is the only strong reference
        let sequence = runner.sequence
        let task = Task<[String], Never> {
            var emojis = [String]()
            await sequence.forEach { emoji in
                emojis.append(emoji)
            }
            done.fulfill()
            XCTAssertEqual(0, emojis.count)
            return emojis
        }

        runner.cancel()

        let output = await task.value
        XCTAssertEqual(0, output.count)

        wait(for: [done], timeout: timeout)
    }

    func testMagicEightBallTaskRunnerWithSequenceCancellation() async throws {
        let done = expectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = MagicEightBallRequest(total: total, delay: delay)
        let runner = MagicEightBallTaskRunner(request: request)
        let task = Task<[String], Never> {
            var emojis = [String]()
            let sequence = runner.sequence
            sequence.cancel()
            await sequence.forEach { emoji in
                emojis.append(emoji)
            }
            await done.fulfill()
            XCTAssertEqual(0, emojis.count)
            return emojis
        }

        let output = await task.value
        XCTAssertEqual(0, output.count)

        wait(for: [done], timeout: timeout)
    }

    func testMagicEightBallPluginAPI() async throws {
        let done = expectation(description: "done")
        let total = 10
        let delay = 0.01
        let timeout = Double(total) * 2.0 * delay
        let plugin = MagicEightBallPlugin()
        let task = Task<[String], Never> {
            var answers = [String]()
            await plugin.getAnswers(total: total, delay: delay).forEach { emoji in
                answers.append(emoji)
            }
            await done.fulfill()
            XCTAssertEqual(total, answers.count)
            return answers
        }

        let answers = await task.value
        XCTAssertEqual(answers.count, total)

        wait(for: [done], timeout: timeout)
    }
    
    // MARK: - Random Emoji (Throwing) -

    func testRandomEmojiTaskRunner() async throws {
        let done = expectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = RandomEmojiRequest(total: total, delay: delay)
        let runner = RandomEmojiTaskRunner(request: request)
        let task = Task<[String], Never> {
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

        wait(for: [done], timeout: timeout)
    }

    func testRandomEmojiTaskRunnerWithRunnerCancellation() async throws {
        let done = expectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = RandomEmojiRequest(total: total, delay: delay)
        let runner = RandomEmojiTaskRunner(request: request)
        // must retain sequence because it is the only strong reference
        let sequence = runner.sequence
        let task = Task<[String], Never> {
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

        wait(for: [done], timeout: timeout)
    }

    func testRandomEmojiTaskRunnerWithSequenceCancellation() async throws {
        let done = expectation(description: "done")
        let delay = 0.01
        let total = 10
        let timeout = Double(total) * 2.0 * delay
        let request = RandomEmojiRequest(total: total, delay: delay)
        let runner = RandomEmojiTaskRunner(request: request)
        let task = Task<[String], Never> {
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

        wait(for: [done], timeout: timeout)
    }

    func testEmojisPluginAPI() async throws {
        let done = expectation(description: "done")
        let total = 10
        let delay = 0.01
        let timeout = Double(total) * 2.0 * delay
        let plugin = EmojisPlugin()
        let task = Task<[String], Error> {
            var emojis = [String]()
            try await plugin.getEmojis(total: total, delay: delay).forEach { emoji in
                emojis.append(emoji)
            }
            await done.fulfill()
            XCTAssertEqual(total, emojis.count)
            return emojis
        }

        let emojis = try await task.value
        XCTAssertEqual(emojis.count, total)

        wait(for: [done], timeout: timeout)
    }

}

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
            var count = 0
            try await runner.sequence.forEach { emoji in
                count += 1
                print(emoji)
            }
            await done.fulfill()
            return count
        }

        let count = try await task.value
        XCTAssertEqual(count, request.total)

        await waitForExpectations([done], timeout: timeout)
    }

    func testPluginAPI() async throws {
        let done = asyncExpectation(description: "done")
        let total = 10
        let delay = 0.01
        let timeout = Double(total) * 2.0 * delay
        let emojis = EmojisPlugin()
        let task = Task {
            var count = 0
            try await emojis.getEmojis(total: total, delay: delay).forEach { emoji in
                count += 1
                print(emoji)
            }
            await done.fulfill()
            return count
        }

        let count = try await task.value
        XCTAssertEqual(count, total)

        await waitForExpectations([done], timeout: timeout)
    }

}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

final class AmplifySequenceTests: XCTestCase {
    enum Failure: Error {
        case unluckyNumber
    }

    actor Output<Element> {
        var elements: [Element] = []
        func append(_ element: Element) {
            elements.append(element)
        }
    }

    let sleepSeconds = 0.1

    func testNumberSequence() async throws {
        let input = [1, 2, 3, 4, 5]
        let channel = AmplifySequence<Int>()

        // load all numbers into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds)
        }

        let output = await channel.reduce(into: []) { array, value in
            array.append(value)
        }

        XCTAssertEqual(input, output)
    }

    func testStringSequence() async throws {
        let input = ["one", "two", "three", "four", "five"]
        let channel = AmplifySequence<String>()

        // load all strings into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds)
        }

        let output = await channel.reduce(into: []) { array, value in
            array.append(value)
        }

        XCTAssertEqual(input, output)
    }

    func testSucceedingSequence() async throws {
        let input = [3, 7, 14, 21]
        let channel = AsyncThrowingChannel<Int>()

        // load all numbers into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds) { element in
                if element == 13 {
                    throw Failure.unluckyNumber
                } else {
                    return element
                }
            }
        }

        var output: [Int] = []
        var thrown: Error? = nil

        print("-- before --")
        do {
            for try await element in channel {
                print(element)
                output.append(element)
            }
        } catch {
            thrown = error
        }
        print("-- after --")

        XCTAssertNil(thrown)
        XCTAssertEqual(input, output)
    }

    func testFailingSequence() async throws {
        let input = [3, 7, 13, 21]
        let channel = AsyncThrowingChannel<Int>()

        // load all numbers into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds) { element in
                if element == 13 {
                    throw Failure.unluckyNumber
                } else {
                    return element
                }
            }
        }

        var output: [Int] = []
        var thrown: Error? = nil

        do {
            for try await element in channel {
                output.append(element)
            }
        } catch {
            thrown = error
        }

        XCTAssertNotNil(thrown)
        let expected = Array(input[0..<2])
        XCTAssertEqual(expected, output)
    }

    func testChannelCancelled() async throws {
        // parent task is canceled while reducing values from sequence
        // before a value is sent which should result in a sum of zero
        let input = 2006
        let reduced = AsyncExpectation.expectation(description: "reduced")
        let done = AsyncExpectation.expectation(description: "done")
        let channel = AmplifySequence<Int>()

        let task = Task<Int, Never> {
            let sum = await channel.reduce(0, +)
            await reduced.fulfill()
            return sum
        }

        // cancel before value is sent
        task.cancel()

        try await AsyncExpectation.waitForExpectations([reduced])
        channel.send(input)

        Task {
            let output = await task.value
            XCTAssertNotEqual(input, output)
            XCTAssertEqual(0, output)
            await done.fulfill()
        }

        try await AsyncExpectation.waitForExpectations([done])
    }

    func testThrowingChannelCancelled() async throws {
        // parent task is canceled while reducing values from sequence
        // before a value is sent which should result in a sum of zero
        let input = 2006
        let reduced = AsyncExpectation.expectation(description: "reduced")
        let done = AsyncExpectation.expectation(description: "done")
        let channel = AsyncThrowingChannel<Int>()

        let task = Task<Int, Error> {
            let sum = try await channel.reduce(0, +)
            await reduced.fulfill()
            return sum
        }

        // cancel before any value is sent
        task.cancel()
        try await AsyncExpectation.waitForExpectations([reduced])
        channel.send(input)

        Task {
            let output = try await task.value
            XCTAssertNotEqual(input, output)
            XCTAssertEqual(0, output)
            await done.fulfill()
        }

        try await AsyncExpectation.waitForExpectations([done])
    }

    private func send<Element>(elements: [Element], channel: AmplifySequence<Element>, sleepSeconds: Double = 0.1) async throws {
        var index = 0
        while index < elements.count {
            try await Task.sleep(seconds: sleepSeconds)
            let element = elements[index]
            channel.send(element)

            index += 1
        }
        channel.finish()
    }

    private func send<Element>(elements: [Element], channel: AsyncThrowingChannel<Element>, sleepSeconds: Double = 0.1, processor: ((Element) throws -> Element)? = nil) async throws {
        var index = 0
        while index < elements.count {
            try await Task.sleep(seconds: sleepSeconds)
            let element = elements[index]
            if let processor = processor {
                do {
                    let processed = try processor(element)
                    channel.send(processed)
                } catch {
                    print("throwing \(error)")
                    channel.fail(error)
                }
            } else {
                channel.send(element)
            }

            index += 1
        }
        channel.finish()
    }

}

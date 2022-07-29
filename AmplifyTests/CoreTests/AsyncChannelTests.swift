//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

final class AsyncChannelTests: XCTestCase {
    enum Failure: Error {
        case unluckyNumber
    }
    let sleepSeconds = 0.1

    func testNumberSequence() async throws {
        let input = [1, 2, 3, 4, 5]
        let channel = AsyncChannel<Int>()

        // load all numbers into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds)
        }

        var output: [Int] = []

        print("-- before --")
        for await element in channel {
            print(element)
            output.append(element)
        }
        print("-- after --")

        XCTAssertEqual(input, output)
    }

    func testStringSequence() async throws {
        let input = ["one", "two", "three", "four", "five"]
        let channel = AsyncChannel<String>()

        // load all strings into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds)
        }

        var output: [String] = []

        print("-- before --")
        for await element in channel {
            print(element)
            output.append(element)
        }
        print("-- after --")

        XCTAssertEqual(input, output)
    }

    func testSendAfterFinishing() async throws {
        let input = ["a", "b", "c"]
        let channel = AsyncChannel<String>()

        // load all strings into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds)
            var thrown: Error? = nil
            do {
                try await channel.send("z")
            } catch {
                thrown = error
            }
            XCTAssertNotNil(thrown)
        }

        var output: [String] = []

        print("-- before --")
        for await element in channel {
            print(element)
            output.append(element)
        }
        print("-- after --")

        XCTAssertEqual(input, output)
    }

    func testSendAfterFinishingThrowing() async throws {
        let input = ["x", "y", "z"]
        let channel = AsyncThrowingChannel<String, Error>()

        // load all strings into the channel with delays
        Task {
            try await send(elements: input, channel: channel, sleepSeconds: sleepSeconds)
            var thrown: Error? = nil
            do {
                try await channel.send("a")
            } catch {
                thrown = error
            }
            XCTAssertNotNil(thrown)
        }

        var output: [String] = []

        print("-- before --")
        for try await element in channel {
            print(element)
            output.append(element)
        }
        print("-- after --")

        XCTAssertEqual(input, output)
    }

    func testSucceedingSequence() async throws {
        let input = [3, 7, 14, 21]
        let channel = AsyncThrowingChannel<Int, Error>()

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
        let channel = AsyncThrowingChannel<Int, Error>()

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

        XCTAssertNotNil(thrown)
        let expected = Array(input[0..<2])
        XCTAssertEqual(expected, output)
    }

    private func send<Element>(elements: [Element], channel: AsyncChannel<Element>, sleepSeconds: Double = 0.1) async throws {
        var index = 0
        while index < elements.count {
            try await Task.sleep(seconds: sleepSeconds)
            let element = elements[index]
            try await channel.send(element)

            index += 1
        }
        await channel.finish()
    }

    private func send<Element>(elements: [Element], channel: AsyncThrowingChannel<Element, Error>, sleepSeconds: Double = 0.1, processor: ((Element) throws -> Element)? = nil) async throws {
        var index = 0
        while index < elements.count {
            try await Task.sleep(seconds: sleepSeconds)
            let element = elements[index]
            if let processor = processor {
                do {
                    let processed = try processor(element)
                    try await channel.send(processed)
                } catch {
                    print("throwing \(error)")
                    await channel.fail(error)
                }
            } else {
                try await channel.send(element)
            }

            index += 1
        }
        await channel.finish()
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon

class AmplifyPublisherTests: XCTestCase {
    enum Failure: Error {
        case unluckyNumber
    }

    func testCreateFromTaskSuccess() async throws {
        let notDone = expectation(description: "notDone")
        notDone.isInverted = true
        let done = expectation(description: "done")
        let input = 7
        var output: Int = 0
        var success = false
        var thrown: Error? = nil
        
        let sink = Amplify.Publisher.create {
            try await self.getOutput(input: input)
        }
            .sink { completion in
                switch completion {
                case .finished:
                    success = true
                case .failure(let error):
                    thrown = error
                    notDone.fulfill()
                }
                done.fulfill()
            } receiveValue: { value in
                output = value
            }
        
        await waitForExpectations(timeout: 1)
        
        XCTAssertEqual(input, output)
        XCTAssertTrue(success)
        XCTAssertNil(thrown)
        
        sink.cancel()
    }

    func testCreateFromTaskFail() async throws {
        let failed = expectation(description: "failed")
        let done = expectation(description: "done")
        let input = 13
        var output: Int = 0
        var success = false
        var thrown: Error? = nil
        
        let sink = Amplify.Publisher.create {
            try await self.getOutput(input: input)
        }
            .sink { completion in
                switch completion {
                case .finished:
                    success = true
                case .failure(let error):
                    thrown = error
                    failed.fulfill()
                }
                done.fulfill()
            } receiveValue: { value in
                output = value
            }
        
        await waitForExpectations(timeout: 1)

        XCTAssertNotEqual(input, output)
        XCTAssertFalse(success)
        XCTAssertNotNil(thrown)

        sink.cancel()
    }

    func testCreateFromTaskCancellation() async throws {
        let noCompletion = expectation(description: "noCompletion")
        noCompletion.isInverted = true
        let noValueReceived = expectation(description: "noValueReceived")
        noValueReceived.isInverted = true
        let input = 7
        var output: Int = 0
        var success = false
        var thrown: Error? = nil
        
        let sink = Amplify.Publisher.create {
            try await self.getOutput(input: input, seconds: 0.25)
        }
            .sink { completion in
                switch completion {
                case .finished:
                    success = true
                case .failure(let error):
                    thrown = error
                }
                noCompletion.fulfill()
            } receiveValue: { value in
                output = value
                noValueReceived.fulfill()
        }

        // cancel immediately
        sink.cancel()

       await waitForExpectations(timeout: 1)

        // completion and value are not expected when sink is cancelled
        XCTAssertNotEqual(input, output)
        XCTAssertFalse(success)
        XCTAssertNil(thrown)
    }

    func testCreateFromAmplifyAsyncSequenceSuccess() async throws {
        let input = Array(1...100)
        let sequence = AmplifyAsyncSequence<Int>()
        var output = [Int]()
        let finished = expectation(description: "completion finished")
        let received = expectation(description: "values received")
        
        let sink = Amplify.Publisher.create(sequence)
            .sink { completion in
                switch completion {
                case .finished:
                    finished.fulfill()
                case .failure(let error):
                    XCTFail("Failed with error: \(error)")
                }
            } receiveValue: { value in
                output.append(value)
                if output.count == input.count {
                    received.fulfill()
                }
            }

        send(input: input, sequence: sequence)

        await waitForExpectations(timeout: 1)
        XCTAssertEqual(input, output)
        sink.cancel()
    }

    func testCreateFromAmplifyAsyncThrowingSequenceSuccess() async throws {
        let input = Array(1...100)
        let sequence = AmplifyAsyncThrowingSequence<Int>()
        var output = [Int]()
        let finished = expectation(description: "completion finished")
        
        let sink = Amplify.Publisher.create(sequence)
            .sink { completion in
                switch completion {
                case .finished:
                    finished.fulfill()
                case .failure(let error):
                    XCTFail("Failed with error: \(error)")
                }
            } receiveValue: { value in
                output.append(value)
            }

        send(input: input, throwingSequence: sequence)

        await waitForExpectations(timeout: 1)
        XCTAssertEqual(input, output)
        sink.cancel()
    }

    func testCreateFromBasicAsyncSequenceSuccess() async throws {
        let expected = [1, 2, 4, 8, 16]
        let sequence = Doubles()
        var output = [Int]()
        let finished = expectation(description: "completion finished")
        
        let sink = Amplify.Publisher.create(sequence)
            .sink { completion in
                switch completion {
                case .finished:
                    finished.fulfill()
                case .failure(let error):
                    XCTFail("Failed with error: \(error)")
                }
            } receiveValue: { value in
                output.append(value)
            }

        await waitForExpectations(timeout: 1)
        XCTAssertEqual(expected, output)
        sink.cancel()
    }
    
    func testCreateFromBasicAsyncSequenceFail() async throws {
        let expected = [1, 2, 4]
        let sequence = Doubles(fails: true)
        var output = [Int]()
        let failed = expectation(description: "completion failed")
        
        let sink = Amplify.Publisher.create(sequence)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("should not have finished")
                case .failure(let error):
                    XCTAssertEqual(error as! Failure, Failure.unluckyNumber)
                    failed.fulfill()
                }
            } receiveValue: { value in
                output.append(value)
            }

        await waitForExpectations(timeout: 1)
        XCTAssertEqual(expected, output)
        sink.cancel()
    }

    func testCreateFromAmplifyAsyncSequenceCancelSink() async throws {
        let input = Array(1...100)
        let expected = [Int]()
        let sequence = AmplifyAsyncSequence<Int>()
        var output = [Int]()
        let completed = expectation(description: "should not have completed")
        completed.isInverted = true
        
        let sink = Amplify.Publisher.create(sequence)
            .sink { completion in
                completed.fulfill()
            } receiveValue: { value in
                output.append(value)
            }
        
        sink.cancel()

        send(input: input, sequence: sequence)

        await waitForExpectations(timeout: 0.1)
        XCTAssertEqual(expected, output)
    }
    
    func testCreateFromAmplifyAsyncSequenceCancelSequence() async throws {
        let expected = [Int]()
        let sequence = AmplifyAsyncSequence<Int>()
        var output = [Int]()
        let finished = expectation(description: "completion finished")

        let sink = Amplify.Publisher.create(sequence)
            .sink { completion in
                switch completion {
                case .finished:
                    finished.fulfill()
                case .failure(let error):
                    XCTFail("Failed with error: \(error)")
                }
            } receiveValue: { value in
                output.append(value)
            }

        sequence.cancel()

        await waitForExpectations(timeout: 1)
        XCTAssertEqual(expected, output)
        sink.cancel()
    }

    private func send<Element>(input: [Element],
                               sequence: AmplifyAsyncSequence<Element>,
                               finish: Bool = true)  {
        for value in input {
            sequence.send(value)
        }
        if finish {
            sequence.finish()
        }
    }

    private func send<Element>(input: [Element],
                               throwingSequence: AmplifyAsyncThrowingSequence<Element>,
                               finish: Bool = true)  {
        for value in input {
            throwingSequence.send(value)
        }
        if finish {
            throwingSequence.finish()
        }
    }

    private struct Doubles: AsyncSequence {
        let fails: Bool
        
        init(fails: Bool = false) {
            self.fails = fails
        }

        typealias Element = Int
        
        func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(fails: fails)
        }
        
        struct AsyncIterator: AsyncIteratorProtocol {
            let fails: Bool
            
            init(fails: Bool = false) {
                self.fails = fails
            }
            
            var current = 1

            mutating func next() async throws -> Element? {
                defer { current *= 2 }
                if current > 16 {
                    return nil
                } else {
                    if fails && current > 4 {
                        throw Failure.unluckyNumber
                    } else {
                        return current
                    }
                }
            }
        }
    }

    private func getOutput(input: Int, seconds: Double = 0.0) async throws -> Int {
        try await Task.sleep(seconds: seconds)
        try Task.checkCancellation()
        guard input != 13 else { throw Failure.unluckyNumber }
        return input
    }
}

#endif

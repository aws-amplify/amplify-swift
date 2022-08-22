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
        let notDone = asyncExpectation(description: "notDone", isInverted: true)
        let done = asyncExpectation(description: "done")
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
                    Task {
                        await notDone.fulfill()
                    }
                }
                Task {
                    await done.fulfill()
                }
            } receiveValue: { value in
                output = value
            }
        
        await waitForExpectations([notDone], timeout: 0.01)
        await waitForExpectations([done])
        
        XCTAssertEqual(input, output)
        XCTAssertTrue(success)
        XCTAssertNil(thrown)
        
        sink.cancel()
    }

    func testCreateFromTaskFail() async throws {
        let failed = asyncExpectation(description: "failed")
        let done = asyncExpectation(description: "done")
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
                    Task {
                        await failed.fulfill()
                    }
                }
                Task {
                    await done.fulfill()
                }
            } receiveValue: { value in
                output = value
            }
        
        await waitForExpectations([failed])
        await waitForExpectations([done])

        XCTAssertNotEqual(input, output)
        XCTAssertFalse(success)
        XCTAssertNotNil(thrown)

        sink.cancel()
    }

    func testCreateFromTaskCancellation() async throws {
        let noCompletion = asyncExpectation(description: "noCompletion", isInverted: true)
        let noValueReceived = asyncExpectation(description: "noValueReceived", isInverted: true)
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
                Task {
                    await noCompletion.fulfill()
                }
            } receiveValue: { value in
                output = value
                Task {
                    await noValueReceived.fulfill()
                }
        }

        // cancel immediately
        sink.cancel()

        await waitForExpectations([noCompletion, noValueReceived], timeout: 0.01)

        // completion and value are not expected when sink is cancelled
        XCTAssertNotEqual(input, output)
        XCTAssertFalse(success)
        XCTAssertNil(thrown)
    }

    func testCreateFromAmplifyAsyncSequenceSuccess() async throws {
        let input = Array(1...100)
        let sequence = createAmplifyAsyncSequence(elements: input)
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
        let sequence = createAmplifyAsyncSequence(elements: input)
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

        await waitForExpectations(timeout: 0.1)
        XCTAssertEqual(expected, output)
    }
    
    func testCreateFromAmplifyAsyncSequenceCancelSequence() async throws {
        let input = Array(1...100)
        let expected = [Int]()
        let sequence = createAmplifyAsyncSequence(elements: input)
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

    private func createAmplifyAsyncSequence<Element>(elements: [Element]) -> AmplifyAsyncSequence<Element> {
        let sequence = AmplifyAsyncSequence<Element>()
        Task {
            for element in elements {
                sequence.send(element)
            }
            sequence.finish()
        }
        return sequence
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

import XCTest
@testable import AsyncTesting

actor AsyncRunner {
    typealias VoidNeverContinuation = CheckedContinuation<Void, Never>
    private var continuations: [VoidNeverContinuation] = []

    public nonisolated func run(timeout: Double = 5.0) async {
        await withTaskCancellationHandler {
            await handleRun(timeout: timeout)
        } onCancel: {
            Task {
                await finish()
            }
        }
    }

    public func finish() {
        while !continuations.isEmpty {
            let continuation = continuations.removeFirst()
            continuation.resume(returning: ())
        }
    }
    
    private func handleRun(timeout: Double) async {
        await withCheckedContinuation {
            continuations.append($0)
        }
        Task {
            try await Task.sleep(seconds: timeout)
            finish()
        }
    }
}

final class AsyncExpectationTests: XCTestCase {
    
    func testDoneExpectation() async throws {
        let delay = 0.01
        let done = asyncExpectation(description: "done")
        Task {
            try await Task.sleep(seconds: delay)
            await done.fulfill()
        }
        await waitForExpectations([done])
    }
    
    func testDoneMultipleTimesExpectation() async throws {
        let delay = 0.01
        let done = asyncExpectation(description: "done", expectedFulfillmentCount: 3)
        Task {
            try await Task.sleep(seconds: delay)
            await done.fulfill()
        }
        Task {
            try await Task.sleep(seconds: delay)
            await done.fulfill()
        }
        Task {
            try await Task.sleep(seconds: delay)
            await done.fulfill()
        }
        await waitForExpectations([done])
    }
    
    func testNotDoneInvertedExpectation() async throws {
        let delay = 0.01
        let notDone = asyncExpectation(description: "not done", isInverted: true)
        let task = Task {
            try await Task.sleep(seconds: delay)
            await notDone.fulfill()
        }
        // cancel immediately to prevent fulfill from being run
        task.cancel()
        await waitForExpectations([notDone], timeout: delay * 2)
    }
    
    func testNotYetDoneAndThenDoneExpectation() async throws {
        let delay = 0.01
        let notYetDone = asyncExpectation(description: "not yet done", isInverted: true)
        let done = asyncExpectation(description: "done")
        
        let task = Task {
            await AsyncRunner().run()
            XCTAssertTrue(Task.isCancelled)
            await notYetDone.fulfill() // will timeout before being called
            await done.fulfill() // will be called after cancellation
        }
        
        await waitForExpectations([notYetDone], timeout: delay)
        task.cancel()
        await waitForExpectations([done])
    }
    
    func testDoneAndNotDoneInvertedExpectation() async throws {
        let delay = 0.01
        let done = asyncExpectation(description: "done")
        let notDone = asyncExpectation(description: "not done", isInverted: true)
        Task {
            try await Task.sleep(seconds: delay)
            await done.fulfill()
            let task = Task {
                try await Task.sleep(seconds: delay)
                await notDone.fulfill()
            }
            // cancel immediately to prevent fulfill from being run
            task.cancel()
        }
        await waitForExpectations([notDone], timeout: delay * 2)
        await waitForExpectations([done])
    }
    
    func testMultipleFulfilledExpectation() async throws {
        let delay = 0.01
        let one = asyncExpectation(description: "one")
        let two = asyncExpectation(description: "two")
        let three = asyncExpectation(description: "three")
        Task {
            try await Task.sleep(seconds: delay)
            await one.fulfill()
        }
        Task {
            try await Task.sleep(seconds: delay)
            await two.fulfill()
        }
        Task {
            try await Task.sleep(seconds: delay)
            await three.fulfill()
        }
        await waitForExpectations([one, two, three])
    }
    
    func testMultipleAlreadyFulfilledExpectation() async throws {
        let one = asyncExpectation(description: "one")
        let two = asyncExpectation(description: "two")
        let three = asyncExpectation(description: "three")
        await one.fulfill()
        await two.fulfill()
        await three.fulfill()
        
        await waitForExpectations([one, two, three])
    }
    
}

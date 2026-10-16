//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Differential test for `EngineTaskQueue`: every workload runs through `Amplify.TaskQueue` and
/// through the engine's copy, and records the same observations. The credential store's operation client
/// serializes its CRUD through this queue, so ordering, overlap and error propagation must not drift.
final class EngineTaskQueueTests: XCTestCase {

    /// One `sync(block:)` entry point, so a workload can run against either queue.
    typealias Sync<Value> = @Sendable (@Sendable @escaping () async throws -> Value) async throws -> Value

    private static func amplify<Value>(_: Value.Type) -> Sync<Value> {
        let queue = TaskQueue<Value>()
        return { try await queue.sync(block: $0) }
    }

    private static func engine<Value>(_: Value.Type) -> Sync<Value> {
        let queue = EngineTaskQueue<Value>()
        return { try await queue.sync(block: $0) }
    }

    enum Failure: Error, Equatable {
        case thrown(Int)
    }

    /// Records the block events and the highest number of blocks running at once.
    actor Trace {
        private(set) var events: [String] = []
        private(set) var running = 0
        private(set) var maxRunning = 0

        func start(_ label: String) {
            running += 1
            maxRunning = max(maxRunning, running)
            events.append("start \(label)")
        }

        func end(_ label: String) {
            running -= 1
            events.append("end \(label)")
        }
    }

    /// Test that sequential calls run in call order and return each block's value
    ///
    /// - Given: A queue of each kind
    /// - When:
    ///    - 50 blocks are submitted one after the other, each sleeping briefly
    /// - Then:
    ///    - Both queues produce the same trace (start/end pairs in call order) and the same values
    ///
    func testSequentialCallsRunInOrderAndReturnTheirValues() async throws {
        func run(_ sync: Sync<Int>) async throws -> ([String], [Int]) {
            let trace = Trace()
            var values: [Int] = []
            for index in 0 ..< 50 {
                try await values.append(sync {
                    await trace.start("\(index)")
                    try await Task.sleep(nanoseconds: 1_000)
                    await trace.end("\(index)")
                    return index * 2
                })
            }
            return await (trace.events, values)
        }

        let amplify = try await run(Self.amplify(Int.self))
        let engine = try await run(Self.engine(Int.self))

        XCTAssertEqual(engine.0, amplify.0)
        XCTAssertEqual(engine.1, amplify.1)
        XCTAssertEqual(engine.1, (0 ..< 50).map { $0 * 2 })
    }

    /// Test that concurrent callers never overlap
    ///
    /// - Given: A queue of each kind
    /// - When:
    ///    - 100 child tasks call `sync` at the same time, each block sleeping briefly
    /// - Then:
    ///    - On both queues at most one block runs at a time, every block runs once, and every start is
    ///      immediately followed by its own end
    ///
    func testConcurrentCallersNeverOverlap() async throws {
        func run(_ sync: @escaping Sync<Int>) async throws -> (maxRunning: Int, events: [String], values: [Int]) {
            let trace = Trace()
            let values = try await withThrowingTaskGroup(of: Int.self) { group in
                for index in 0 ..< 100 {
                    group.addTask {
                        try await sync {
                            await trace.start("\(index)")
                            try await Task.sleep(nanoseconds: 1_000)
                            await trace.end("\(index)")
                            return index
                        }
                    }
                }
                var values: [Int] = []
                for try await value in group {
                    values.append(value)
                }
                return values.sorted()
            }
            return await (trace.maxRunning, trace.events, values)
        }

        for (name, sync) in [("amplify", Self.amplify(Int.self)), ("engine", Self.engine(Int.self))] {
            let result = try await run(sync)
            XCTAssertEqual(result.maxRunning, 1, name)
            XCTAssertEqual(result.values, Array(0 ..< 100), name)
            XCTAssertEqual(result.events.count, 200, name)
            for pair in stride(from: 0, to: result.events.count, by: 2) {
                let label = result.events[pair].dropFirst("start ".count)
                XCTAssertEqual(result.events[pair + 1], "end \(label)", name)
            }
        }
    }

    /// Test that a thrown error reaches the caller unchanged and does not stop the queue
    ///
    /// - Given: A queue of each kind
    /// - When:
    ///    - Blocks alternately return a value and throw
    /// - Then:
    ///    - Both queues give the same outcomes: the value, or the same error, for each call, in order
    ///
    func testErrorsReachTheCallerAndTheQueueContinues() async throws {
        func run(_ sync: Sync<Int>) async -> [String] {
            var outcomes: [String] = []
            for index in 0 ..< 20 {
                do {
                    let value = try await sync {
                        if index.isMultiple(of: 2) {
                            throw Failure.thrown(index)
                        }
                        return index
                    }
                    outcomes.append("value \(value)")
                } catch let error as Failure {
                    outcomes.append("error \(error)")
                } catch {
                    outcomes.append("unexpected \(error)")
                }
            }
            return outcomes
        }

        let amplify = await run(Self.amplify(Int.self))
        let engine = await run(Self.engine(Int.self))

        XCTAssertEqual(engine, amplify)
        XCTAssertEqual(engine.first, "error thrown(0)")
        XCTAssertEqual(engine.last, "value 19")
    }

    /// Test that an optional `nil` result passes through, as `CredentialStoreOperationClient` relies on
    ///
    /// - Given: A queue of each kind over an optional value
    /// - When:
    ///    - One block returns `nil` and the next a value
    /// - Then:
    ///    - Both return `nil`, then the value
    ///
    func testOptionalNilPassesThrough() async throws {
        func run(_ sync: Sync<String?>) async throws -> [String?] {
            try await [sync { nil }, sync { "stored" }]
        }

        let amplify = try await run(Self.amplify(String?.self))
        let engine = try await run(Self.engine(String?.self))

        XCTAssertEqual(engine, amplify)
        XCTAssertEqual(engine, [nil, "stored"])
    }

    /// Test that cancelling the caller neither cancels nor skips the block
    ///
    /// - Given: A queue of each kind
    /// - When:
    ///    - A caller task is cancelled before its `sync` call, and the block reports `Task.isCancelled`
    /// - Then:
    ///    - On both queues the block still runs, sees no cancellation (it runs on the queue's own task)
    ///      and its value reaches the cancelled caller
    ///
    func testCancellingTheCallerDoesNotCancelTheBlock() async throws {
        func run(_ sync: @escaping Sync<Bool>) async throws -> Bool {
            let caller = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await sync { Task.isCancelled }
            }
            return try await caller.value
        }

        let amplify = try await run(Self.amplify(Bool.self))
        let engine = try await run(Self.engine(Bool.self))

        XCTAssertEqual(engine, amplify)
        XCTAssertFalse(engine)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Runs a test concurrently for the number of times specified
///
/// The test is run repeatedly using a Swift task group; each test run is performed as a "child task".
/// The function returns when all test runs have completed, and rethrows if a test run throws.
/// - Parameters:
///   - count: The number of test runs
///   - test: The function pointer for the test to run
/// - Throws: Any error thrown by one of the test runs.
public func repeatConcurrently(count: Int, test: @escaping () async throws -> Void) async throws {
    try await withThrowingTaskGroup(of: Void.self) { taskGroup in
        for _ in 0..<count {
            taskGroup.addTask {
                try await test()
            }
        }
        try await taskGroup.waitForAll()
    }
}

/// Runs a test concurrently for the number of times specified with args
///
/// The test is run repeatedly using a Swift task group; each test run is performed as a "child task".
/// The function returns when all test runs have completed, and rethrows if a test run throws.
/// - Parameters:
///   - count: The number of test runs
///   - test: The function pointer for the test to run
///   - args: Any values to pass along to test function
/// - Throws: Any error thrown by one of the test runs.
public func repeatConcurrentlyWithArgs(
    count: Int,
    test: @escaping (Any...) async throws -> Void,
    args: Any...
) async throws {
    try await withThrowingTaskGroup(of: Void.self) { taskGroup in
        for _ in 0..<count {
            taskGroup.addTask {
                try await test(args)
            }
        }
        try await taskGroup.waitForAll()
    }
}

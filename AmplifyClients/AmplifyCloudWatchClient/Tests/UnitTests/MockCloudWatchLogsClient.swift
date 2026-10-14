//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs
import Foundation

@testable import AmplifyCloudWatchClient

class MockCloudWatchLogsClient: CloudWatchLogsClientProtocol {

    enum MockError: Error {
        case unexpected
    }

    private let interactionsLock = NSLock()
    private var recordedInteractions: [String] = []

    /// Guarded by `interactionsLock`, since batches consumed at the same time call the client from several tasks.
    var interactions: [String] {
        interactionsLock.lock()
        defer { interactionsLock.unlock() }
        return recordedInteractions
    }

    private func record(_ interaction: String) {
        interactionsLock.lock()
        defer { interactionsLock.unlock() }
        recordedInteractions.append(interaction)
    }

    var putLogEventsHandler: (PutLogEventsInput) async throws -> PutLogEventsOutput = { _ in
        return PutLogEventsOutput()
    }

    func putLogEvents(input: PutLogEventsInput) async throws -> PutLogEventsOutput {
        record(#function)
        return try await putLogEventsHandler(input)
    }

    var createLogStreamHandler: (CreateLogStreamInput) async throws -> CreateLogStreamOutput = { _ in
        return CreateLogStreamOutput()
    }

    func createLogStream(input: CreateLogStreamInput) async throws -> CreateLogStreamOutput {
        record(#function)
        return try await createLogStreamHandler(input)
    }

    var describeLogStreamsHandler: (DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput = { _ in
        return DescribeLogStreamsOutput()
    }

    func describeLogStreams(input: DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput {
        record(#function)
        return try await describeLogStreamsHandler(input)
    }
}

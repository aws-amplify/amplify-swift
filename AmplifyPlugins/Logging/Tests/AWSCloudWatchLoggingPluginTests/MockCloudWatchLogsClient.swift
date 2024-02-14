//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLoggingPlugin
import AWSCloudWatchLogs
import Foundation

class MockCloudWatchLogsClient: CloudWatchLogsClientProtocol {
    
    enum MockError: Error {
        case unexpected
        case unimplemented
    }
    
    var interactions: [String] = []
    
    var putLogEventsHandler: (PutLogEventsInput) async throws -> PutLogEventsOutput = { input in
        return PutLogEventsOutput()
    }

    func putLogEvents(input: PutLogEventsInput) async throws -> PutLogEventsOutput {
        interactions.append(#function)
        return try await putLogEventsHandler(input)
    }

    var createLogStreamHandler: (CreateLogStreamInput) async throws -> CreateLogStreamOutput = { _ in
        return CreateLogStreamOutput()
    }

    func createLogStream(input: CreateLogStreamInput) async throws -> CreateLogStreamOutput {
        interactions.append(#function)
        return try await createLogStreamHandler(input)
    }

    var describeLogStreamsHandler: (DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput = { _ in
        return DescribeLogStreamsOutput()
    }

    func describeLogStreams(input: DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput {
        interactions.append(#function)
        return try await describeLogStreamsHandler(input)
    }
}

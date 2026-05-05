//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs

/// Protocol wrapper for CloudWatchLogsClient to enable dependency injection for testing.
protocol CloudWatchLogsClientProtocol {
    func putLogEvents(input: PutLogEventsInput) async throws -> PutLogEventsOutput
    func createLogStream(input: CreateLogStreamInput) async throws -> CreateLogStreamOutput
    func describeLogStreams(input: DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput
}

extension AWSCloudWatchLogs.CloudWatchLogsClient: CloudWatchLogsClientProtocol {}

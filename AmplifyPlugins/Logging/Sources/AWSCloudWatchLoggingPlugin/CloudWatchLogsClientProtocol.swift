//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs

public protocol CloudWatchLogsClientProtocol {

    func describeLogStreams(input: DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput

    func createLogStream(input: CreateLogStreamInput) async throws -> CreateLogStreamOutput

    func putLogEvents(input: PutLogEventsInput) async throws -> PutLogEventsOutput

}

extension CloudWatchLogsClient: CloudWatchLogsClientProtocol { }

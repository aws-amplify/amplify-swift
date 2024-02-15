//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs

public protocol CloudWatchLogsClientProtocol {

    /// Performs the `DescribeLogStreams` operation on the `Logs_20140328` service.
    ///
    /// Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered. You can specify the log group to search by using either logGroupIdentifier or logGroupName. You must include one of these two parameters, but you can't include both. This operation has a limit of five transactions per second, after which transactions are throttled. If you are using CloudWatch cross-account observability, you can use this operation in a monitoring account and view data from the linked source accounts. For more information, see [CloudWatch cross-account observability](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Unified-Cross-Account.html).
    ///
    /// - Parameter DescribeLogStreamsInput : [no documentation found]
    ///
    /// - Returns: `DescribeLogStreamsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidParameterException` : A parameter is specified incorrectly.
    /// - `ResourceNotFoundException` : The specified resource does not exist.
    /// - `ServiceUnavailableException` : The service cannot complete the request.
    func describeLogStreams(input: DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput

    /// Performs the `CreateLogStream` operation on the `Logs_20140328` service.
    ///
    /// Creates a log stream for the specified log group. A log stream is a sequence of log events that originate from a single source, such as an application instance or a resource that is being monitored. There is no limit on the number of log streams that you can create for a log group. There is a limit of 50 TPS on CreateLogStream operations, after which transactions are throttled. You must use the following guidelines when naming a log stream:
    ///
    /// * Log stream names must be unique within the log group.
    ///
    /// * Log stream names can be between 1 and 512 characters long.
    ///
    /// * Don't use ':' (colon) or '*' (asterisk) characters.
    ///
    /// - Parameter CreateLogStreamInput : [no documentation found]
    ///
    /// - Returns: `CreateLogStreamOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidParameterException` : A parameter is specified incorrectly.
    /// - `ResourceAlreadyExistsException` : The specified resource already exists.
    /// - `ResourceNotFoundException` : The specified resource does not exist.
    /// - `ServiceUnavailableException` : The service cannot complete the request.
    func createLogStream(input: CreateLogStreamInput) async throws -> CreateLogStreamOutput

    /// Performs the `PutLogEvents` operation on the `Logs_20140328` service.
    ///
    /// Uploads a batch of log events to the specified log stream. The sequence token is now ignored in PutLogEvents actions. PutLogEvents actions are always accepted and never return InvalidSequenceTokenException or DataAlreadyAcceptedException even if the sequence token is not valid. You can use parallel PutLogEvents actions on the same log stream. The batch of events must satisfy the following constraints:
    ///
    /// * The maximum batch size is 1,048,576 bytes. This size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.
    ///
    /// * None of the log events in the batch can be more than 2 hours in the future.
    ///
    /// * None of the log events in the batch can be more than 14 days in the past. Also, none of the log events can be from earlier than the retention period of the log group.
    ///
    /// * The log events in the batch must be in chronological order by their timestamp. The timestamp is the time that the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In Amazon Web Services Tools for PowerShell and the Amazon Web Services SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.)
    ///
    /// * A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.
    ///
    /// * Each log event can be no larger than 256 KB.
    ///
    /// * The maximum number of log events in a batch is 10,000.
    ///
    /// * The quota of five requests per second per log stream has been removed. Instead, PutLogEvents actions are throttled based on a per-second per-account quota. You can request an increase to the per-second throttling quota by using the Service Quotas service.
    ///
    ///
    /// If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is a non-valid Amazon Web Services access key ID or secret key.
    ///
    /// - Parameter PutLogEventsInput : [no documentation found]
    ///
    /// - Returns: `PutLogEventsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `DataAlreadyAcceptedException` : The event was already logged. PutLogEvents actions are now always accepted and never return DataAlreadyAcceptedException regardless of whether a given batch of log events has already been accepted.
    /// - `InvalidParameterException` : A parameter is specified incorrectly.
    /// - `InvalidSequenceTokenException` : The sequence token is not valid. You can get the correct sequence token in the expectedSequenceToken field in the InvalidSequenceTokenException message. PutLogEvents actions are now always accepted and never return InvalidSequenceTokenException regardless of receiving an invalid sequence token.
    /// - `ResourceNotFoundException` : The specified resource does not exist.
    /// - `ServiceUnavailableException` : The service cannot complete the request.
    /// - `UnrecognizedClientException` : The most likely cause is an Amazon Web Services access key ID or secret key that's not valid.
    func putLogEvents(input: PutLogEventsInput) async throws -> PutLogEventsOutput

}

extension CloudWatchLogsClient: CloudWatchLogsClientProtocol { }

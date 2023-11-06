//
//  File.swift
//  
//
//  Created by Saultz, Ian on 11/6/23.
//

import Foundation

struct PutLogEventsInput: Equatable {
    /// The log events.
    /// This member is required.
    var logEvents: [CloudWatchLogsClientTypes.InputLogEvent]?
    /// The name of the log group.
    /// This member is required.
    var logGroupName: String?
    /// The name of the log stream.
    /// This member is required.
    var logStreamName: String?
    /// The sequence token obtained from the response of the previous PutLogEvents call. The sequenceToken parameter is now ignored in PutLogEvents actions. PutLogEvents actions are now accepted and never return InvalidSequenceTokenException or DataAlreadyAcceptedException even if the sequence token is not valid.
    var sequenceToken: String?

    enum CodingKeys: String, CodingKey {
        case logEvents
        case logGroupName
        case logStreamName
        case sequenceToken
    }
}

extension CloudWatchLogsClientTypes {
    /// Represents the rejected events.
    struct RejectedLogEventsInfo: Swift.Equatable {
        /// The expired log events.
        var expiredLogEventEndIndex: Swift.Int?
        /// The log events that are too new.
        var tooNewLogEventStartIndex: Swift.Int?
        /// The log events that are dated too far in the past.
        var tooOldLogEventEndIndex: Swift.Int?
    }
}

struct PutLogEventsOutputResponse: Equatable {
    /// The next sequence token. This field has been deprecated. The sequence token is now ignored in PutLogEvents actions. PutLogEvents actions are always accepted even if the sequence token is not valid. You can use parallel PutLogEvents actions on the same log stream and you do not need to wait for the response of a previous PutLogEvents action to obtain the nextSequenceToken value.
    var nextSequenceToken: String?
    /// The rejected events.
    var rejectedLogEventsInfo: CloudWatchLogsClientTypes.RejectedLogEventsInfo?
}

extension CloudWatchLogsClientTypes {
    /// Represents a log event, which is a record of activity that was recorded by the application or resource being monitored.
    struct InputLogEvent: Equatable {
        /// The raw event message. Each log event can be no larger than 256 KB.
        /// This member is required.
        var message: String?
        /// The time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC.
        /// This member is required.
        var timestamp: Int?
    }
}

struct CreateLogStreamInput: Equatable {
    /// The name of the log group.
    /// This member is required.
    var logGroupName: String?
    /// The name of the log stream.
    /// This member is required.
    var logStreamName: String?

    enum CodingKeys: String, CodingKey {
        case logGroupName
        case logStreamName
    }
}

struct CreateLogStreamOutputResponse: Equatable {
    init() { }
}


struct DescribeLogStreamsInput: Equatable {
    /// If the value is true, results are returned in descending order. If the value is to false, results are returned in ascending order. The default value is false.
    var descending: Bool?
    /// The maximum number of items returned. If you don't specify a value, the default is up to 50 items.
    var limit: Int?
    /// Specify either the name or ARN of the log group to view. If the log group is in a source account and you are using a monitoring account, you must use the log group ARN. You must include either logGroupIdentifier or logGroupName, but not both.
    var logGroupIdentifier: String?
    /// The name of the log group. You must include either logGroupIdentifier or logGroupName, but not both.
    var logGroupName: String?
    /// The prefix to match. If orderBy is LastEventTime, you cannot specify this parameter.
    var logStreamNamePrefix: String?
    /// The token for the next set of items to return. (You received this token from a previous call.)
    var nextToken: String?
    /// If the value is LogStreamName, the results are ordered by log stream name. If the value is LastEventTime, the results are ordered by the event time. The default value is LogStreamName. If you order the results by event time, you cannot specify the logStreamNamePrefix parameter. lastEventTimestamp represents the time of the most recent log event in the log stream in CloudWatch Logs. This number is expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. lastEventTimestamp updates on an eventual consistency basis. It typically updates in less than an hour from ingestion, but in rare situations might take longer.
    var orderBy: CloudWatchLogsClientTypes.OrderBy?

    init(
        descending: Bool? = nil,
        limit: Int? = nil,
        logGroupIdentifier: String? = nil,
        logGroupName: String? = nil,
        logStreamNamePrefix: String? = nil,
        nextToken: String? = nil,
        orderBy: CloudWatchLogsClientTypes.OrderBy? = nil
    )
    {
        self.descending = descending
        self.limit = limit
        self.logGroupIdentifier = logGroupIdentifier
        self.logGroupName = logGroupName
        self.logStreamNamePrefix = logStreamNamePrefix
        self.nextToken = nextToken
        self.orderBy = orderBy
    }
}

extension CloudWatchLogsClientTypes {
    enum OrderBy: Equatable, RawRepresentable, CaseIterable, Codable, Swift.Hashable {
        case lasteventtime
        case logstreamname
        case sdkUnknown(String)

        static var allCases: [OrderBy] {
            return [
                .lasteventtime,
                .logstreamname,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .lasteventtime: return "LastEventTime"
            case .logstreamname: return "LogStreamName"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = OrderBy(rawValue: rawValue) ?? OrderBy.sdkUnknown(rawValue)
        }
    }
}


struct DescribeLogStreamsOutputResponse: Equatable {
    /// The log streams.
    var logStreams: [CloudWatchLogsClientTypes.LogStream]?
    /// The token for the next set of items to return. The token expires after 24 hours.
    var nextToken: String?
}

enum CloudWatchLogsClientTypes {}

extension CloudWatchLogsClientTypes {
    /// Represents a log stream, which is a sequence of log events from a single emitter of logs.
    struct LogStream: Equatable {
        /// The Amazon Resource Name (ARN) of the log stream.
        var arn: String?
        /// The creation time of the stream, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC.
        var creationTime: Int?
        /// The time of the first event, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC.
        var firstEventTimestamp: Int?
        /// The time of the most recent log event in the log stream in CloudWatch Logs. This number is expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. The lastEventTime value updates on an eventual consistency basis. It typically updates in less than an hour from ingestion, but in rare situations might take longer.
        var lastEventTimestamp: Int?
        /// The ingestion time, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC The lastIngestionTime value updates on an eventual consistency basis. It typically updates in less than an hour after ingestion, but in rare situations might take longer.
        var lastIngestionTime: Int?
        /// The name of the log stream.
        var logStreamName: String?
        /// The number of bytes stored. Important: As of June 17, 2019, this parameter is no longer supported for log streams, and is always reported as zero. This change applies only to log streams. The storedBytes parameter for log groups is not affected.
        @available(*, deprecated, message: "Starting on June 17, 2019, this parameter will be deprecated for log streams, and will be reported as zero. This change applies only to log streams. The storedBytes parameter for log groups is not affected.")
        var storedBytes: Int?
        /// The sequence token. The sequence token is now ignored in PutLogEvents actions. PutLogEvents actions are always accepted regardless of receiving an invalid sequence token. You don't need to obtain uploadSequenceToken to use a PutLogEvents action.
        var uploadSequenceToken: String?
    }
}

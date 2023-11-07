//
//  File.swift
//  
//
//  Created by Saultz, Ian on 11/6/23.
//

import Foundation

struct PutLogEventsInput: Equatable, Encodable {
    /// This member is required.
    var logEvents: [CloudWatchLogsClientTypes.InputLogEvent]
    /// This member is required.
    var logGroupName: String
    /// This member is required.
    var logStreamName: String

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
    struct RejectedLogEventsInfo: Equatable, Decodable {
        var expiredLogEventEndIndex: Int?
        var tooNewLogEventStartIndex: Int?
        var tooOldLogEventEndIndex: Int?

        enum CodingKeys: String, CodingKey {
            case expiredLogEventEndIndex
            case tooNewLogEventStartIndex
            case tooOldLogEventEndIndex
        }
    }
}

struct PutLogEventsOutputResponse: Equatable, Decodable {
    var nextSequenceToken: String?
    var rejectedLogEventsInfo: CloudWatchLogsClientTypes.RejectedLogEventsInfo?

    enum CodingKeys: String, CodingKey {
        case nextSequenceToken
        case rejectedLogEventsInfo
    }
}

extension CloudWatchLogsClientTypes {
    struct InputLogEvent: Equatable, Encodable {
        /// This member is required.
        var message: String
        /// This member is required.
        var timestamp: Int

        enum CodingKeys: String, CodingKey {
            case message
            case timestamp
        }
    }
}

struct CreateLogStreamInput: Equatable, Encodable {
    /// This member is required.
    var logGroupName: String
    /// This member is required.
    var logStreamName: String

    enum CodingKeys: String, CodingKey {
        case logGroupName
        case logStreamName
    }
}

struct CreateLogStreamOutputResponse: Equatable, Decodable {
    init() {}
}


struct DescribeLogStreamsInput: Equatable, Encodable {
    var descending: Bool?
    var limit: Int?
    var logGroupIdentifier: String?
    var logGroupName: String?
    var logStreamNamePrefix: String?
    var nextToken: String?
    var orderBy: CloudWatchLogsClientTypes.OrderBy?

    enum CodingKeys: String, CodingKey {
        case descending
        case limit
        case logGroupIdentifier
        case logGroupName
        case logStreamNamePrefix
        case nextToken
        case orderBy
    }
}

extension CloudWatchLogsClientTypes {
    enum OrderBy: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
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


struct DescribeLogStreamsOutputResponse: Equatable, Decodable {
    var logStreams: [CloudWatchLogsClientTypes.LogStream]?
    var nextToken: String?

    enum CodingKeys: String, CodingKey {
        case logStreams
        case nextToken
    }
}

enum CloudWatchLogsClientTypes {}

extension CloudWatchLogsClientTypes {
    struct LogStream: Equatable, Decodable {
        var arn: String?
        var creationTime: Int?
        var firstEventTimestamp: Int?
        var lastEventTimestamp: Int?
        var lastIngestionTime: Int?
        var logStreamName: String?
        @available(*, deprecated, message: "Starting on June 17, 2019, this parameter will be deprecated for log streams, and will be reported as zero. This change applies only to log streams. The storedBytes parameter for log groups is not affected.")
        var storedBytes: Int?
        var uploadSequenceToken: String?

        enum CodingKeys: String, CodingKey {
            case arn
            case creationTime
            case firstEventTimestamp
            case lastEventTimestamp
            case lastIngestionTime
            case logStreamName
            case storedBytes
            case uploadSequenceToken
        }
    }
}


extension CloudWatchLogsClientTypes {
    struct FilteredLogEvent: Equatable, Decodable {
        var eventId: String?
        var ingestionTime: Int?
        var logStreamName: String?
        var message: String?
        var timestamp: Int?
    }
}

struct FilterLogEventsInput: Equatable, Encodable {
    var endTime: Int?
    var filterPattern: String?
    @available(*, deprecated, message: "Starting on June 17, 2019, this parameter will be ignored and the value will be assumed to be true. The response from this operation will always interleave events from multiple log streams within a log group.")
    var interleaved: Bool?
    var limit: Int?
    var logGroupIdentifier: String?
    var logGroupName: String?
    var logStreamNamePrefix: String?
    var logStreamNames: [String]?
    var nextToken: String?
    var startTime: Int?
    var unmask: Bool?

    enum CodingKeys: String, CodingKey {
        case endTime
        case filterPattern
        case interleaved
        case limit
        case logGroupIdentifier
        case logGroupName
        case logStreamNamePrefix
        case logStreamNames
        case nextToken
        case startTime
        case unmask
    }
}

struct FilterLogEventsOutputResponse: Equatable, Decodable {
    var events: [CloudWatchLogsClientTypes.FilteredLogEvent]?
    var nextToken: String?
    var searchedLogStreams: [CloudWatchLogsClientTypes.SearchedLogStream]?

    enum CodingKeys: String, CodingKey {
        case events
        case nextToken
        case searchedLogStreams
    }

}

extension CloudWatchLogsClientTypes {
    struct SearchedLogStream: Equatable, Decodable {
        var logStreamName: String?
        var searchedCompletely: Bool?
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite

extension PinpointEvent {
    private static let archiver: AmplifyArchiverBehaviour = AmplifyArchiver()
    
    /// Converts a Pinpoint Event to a collection of SQL Bindings for SQL insert statements
    /// - Parameters:
    ///   - dateFormater: The date formatter to format dates to strings.  Defaults to ISO8601 with fractional seconds format.
    ///   - archiver: The archiver to archive metrics and attributes
    /// - Returns: A collection of SQLite Bindings
    func getInsertBindings(dateFormater: DateFormatter = DateFormatter.iso8601DateFormatterWithFractionalSeconds, archiver: AmplifyArchiverBehaviour = PinpointEvent.archiver) -> [Binding?] {
        var stopTimeBinding: String?
        if let stopTime = session.stopTime {
            stopTimeBinding = dateFormater.string(from: stopTime)
        }
        let encodedAttributes = try? archiver.encode(attributes).base64EncodedString()
        let encodedMetrics = try? archiver.encode(metrics).base64EncodedString()
        return [
            id, 
            encodedAttributes,
            eventType,
            encodedMetrics,
            eventTimestamp,
            session.sessionId,
            dateFormater.string(from: session.startTime),
            stopTimeBinding,
            Date().timeIntervalSince1970, // timestamp
            0, // isDirty
            0 // RetryCount
        ]
    }
    
    /// Converts a SQL Statement element to a pinpoint event based on predefined/known property index of columns/index
    /// - Parameters:
    ///   - element: The SQL statement element
    ///   - dateFormater: The date formatter to convert string to date.  Defaults to ISO8601 with fractional seconds format.
    ///   - archiver: The default archiver to decode metrics and attributes.
    /// - Returns: A Pinpoint event
    static func convertToEvent(_ element: Statement.Element, dateFormater: DateFormatter = DateFormatter.iso8601DateFormatterWithFractionalSeconds, archiver: AmplifyArchiverBehaviour = PinpointEvent.archiver) -> PinpointEvent? {
        guard let sessionId = element[EventPropertyIndex.sessionId] as? String, let startTime = element[EventPropertyIndex.sessionStartTime] as? String,
              let startDateTime = dateFormater.date(from: startTime)else {
            return nil
        }
        
        var stopDateTime: Date? = nil
        if let stopTime = element[EventPropertyIndex.sessionStopTime] as? String {
            stopDateTime = dateFormater.date(from: stopTime)
        }
        
        let session = PinpointSession(sessionId: sessionId, startTime: startDateTime, stopTime: stopDateTime)

        guard let eventType = element[EventPropertyIndex.eventType] as? String, let timeStamp = element[EventPropertyIndex.timestamp] as? TimeInterval else {
            return nil
        }
        
        let pinpointEvent = PinpointEvent(eventType: eventType, eventTimestamp: Date.Millisecond(timeStamp), session: session)
        
        if let attributes = element[EventPropertyIndex.attributes] as? String, let data = Data(base64Encoded: attributes),
           let decodedAttributes = try? archiver.decode(AnalyticsClient.PinpointEventAttributes.self, from: data) {
            for (key, value) in decodedAttributes {
                pinpointEvent.addAttribute(value, forKey: key)
            }
        }
        
        if let metrics = element[EventPropertyIndex.metrics] as? String, let data = Data(base64Encoded: metrics),
           let decodedMetrics = try? archiver.decode(AnalyticsClient.PinpointEventMetrics.self, from: data) {
            for (key, value) in decodedMetrics {
                pinpointEvent.addMetric(value, forKey: key)
            }
        }
        
        return pinpointEvent
    }

    struct EventPropertyIndex {
        static let id = 0
        static let attributes = 1
        static let eventType = 2
        static let metrics = 3
        static let eventTimestamp = 4
        static let sessionId = 5
        static let sessionStartTime = 6
        static let sessionStopTime = 7
        static let timestamp = 8
        static let retryCount = 9
    }
}

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
    func getInsertBindings(archiver: AmplifyArchiverBehaviour = PinpointEvent.archiver) -> [Binding?] {
        let attributesBlob = PinpointEvent.archiveEventAttributes(attributes)
        var metricsBlob: Blob?
        if let encodedMetrics = try? archiver.encode(metrics) {
            metricsBlob = Blob(bytes: [UInt8](encodedMetrics))
        }

        return [
            id,
            attributesBlob,
            eventType,
            metricsBlob,
            eventDate.asISO8601String,
            session.sessionId,
            session.startTime.asISO8601String,
            session.stopTime?.asISO8601String ?? "",
            Date().timeIntervalSince1970, // timestamp
            0, // isDirty
            0 // RetryCount
        ]
    }

    static func archiveEventAttributes(_ attributes: [String: String]) -> Binding? {
        guard let encodedAttributes = try? archiver.encode(attributes) else {
            return nil
        }
        return Blob(bytes: [UInt8](encodedAttributes))
    }

    /// Converts a SQL Statement element to a pinpoint event based on predefined/known property index of columns/index
    /// - Parameters:
    ///   - element: The SQL statement element
    ///   - dateFormatter: The date formatter to convert string to date.  Defaults to ISO8601 with fractional seconds format.
    ///   - archiver: The default archiver to decode metrics and attributes.
    /// - Returns: A Pinpoint event
    static func convertToEvent(_ element: Statement.Element, archiver: AmplifyArchiverBehaviour = PinpointEvent.archiver) -> PinpointEvent? {
        let dateFormatter = DateFormatter.iso8601Formatter
        guard let sessionId = element[EventPropertyIndex.sessionId] as? String,
              let startTimeString = element[EventPropertyIndex.sessionStartTime] as? String,
              let startTime = dateFormatter.date(from: startTimeString) else {
            return nil
        }

        var stopTime: Date?
        if let stopTimeString = element[EventPropertyIndex.sessionStopTime] as? String {
            stopTime = dateFormatter.date(from: stopTimeString)
        }

        let session = PinpointSession(sessionId: sessionId, startTime: startTime, stopTime: stopTime)

        guard let eventType = element[EventPropertyIndex.eventType] as? String,
              let eventTimestampValue = element[EventPropertyIndex.eventTimestamp] as? String,
              let timestamp = dateFormatter.date(from: eventTimestampValue) else {
            return nil
        }

        guard let eventId = element[EventPropertyIndex.id] as? String else {
            return nil
        }

        let pinpointEvent = PinpointEvent(id: eventId, eventType: eventType, eventDate: timestamp, session: session)

        if let attributes = element[EventPropertyIndex.attributes] as? Blob,
           let decodedAttributes = try? archiver.decode(AnalyticsClient.PinpointEventAttributes.self, from: Data(attributes.bytes)) {
            for (key, value) in decodedAttributes {
                pinpointEvent.addAttribute(value, forKey: key)
            }
        }

        if let metrics = element[EventPropertyIndex.metrics] as? Blob,
           let decodedMetrics = try? archiver.decode(AnalyticsClient.PinpointEventMetrics.self, from: Data(metrics.bytes)) {
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
        static let dirtyFlag = 9
        static let retryCount = 10
    }
}

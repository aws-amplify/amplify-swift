//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// An analytics event enriched with device, app, session, and SDK metadata.
///
/// Use ``toJson()`` to serialize to a Pinpoint-compatible JSON envelope.
public struct EnrichedEvent: Sendable {
    /// Unique event identifier (UUID).
    public let eventId: String

    /// Type of the event.
    public let eventType: String

    /// Milliseconds since epoch when the event was recorded.
    public let eventTimestamp: Int64

    /// Session active at the time of recording.
    public let session: Session

    /// Merged attributes (globals + per-event).
    public let attributes: [String: String]

    /// Merged metrics (globals + per-event).
    public let metrics: [String: Double]

    /// Device metadata.
    public let device: DeviceMetadata

    /// Application metadata.
    public let app: AppMetadata

    /// SDK metadata.
    public let sdk: SDKMetadata

    /// Persistent client/device identifier.
    public let clientId: String

    /// Optional user identifier.
    public let userId: String?

    private static let eventVersion = "3.1"
    private nonisolated(unsafe) static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Serializes to a Pinpoint-compatible JSON string.
    public func toJson() throws -> String {
        var deviceMap: [String: Any] = [:]
        var platformMap: [String: Any] = [:]
        if let platform = device.platform { platformMap["name"] = platform }
        if let platformVersion = device.platformVersion { platformMap["version"] = platformVersion }
        if !platformMap.isEmpty { deviceMap["platform"] = platformMap }
        if let manufacturer = device.manufacturer { deviceMap["make"] = manufacturer }
        if let model = device.model { deviceMap["model"] = model }
        if let locale = device.locale { deviceMap["locale"] = ["code": locale] }

        var applicationMap: [String: Any] = [
            "app_id": app.appId,
            "sdk": [
                "name": sdk.name,
                "version": sdk.version,
            ] as [String: Any],
        ]
        if let packageName = app.packageName { applicationMap["package_name"] = packageName }
        if let versionName = app.versionName { applicationMap["version_name"] = versionName }
        if let versionCode = app.versionCode { applicationMap["version_code"] = versionCode }
        if let title = app.title { applicationMap["title"] = title }

        var clientMap: [String: Any] = ["client_id": clientId]
        if let userId { clientMap["user_id"] = userId }

        var sessionMap: [String: Any] = [
            "id": session.id,
            "start_timestamp": Self.isoFormatter.string(from: session.startTimestamp),
        ]
        if let stopTimestamp = session.stopTimestamp {
            sessionMap["stop_timestamp"] = Self.isoFormatter.string(from: stopTimestamp)
        }
        if let duration = session.duration { sessionMap["duration"] = duration }

        var map: [String: Any] = [
            "event_type": eventType,
            "event_timestamp": eventTimestamp,
            "arrival_timestamp": eventTimestamp,
            "event_version": Self.eventVersion,
            "application": applicationMap,
            "client": clientMap,
            "device": deviceMap,
            "session": sessionMap,
        ]
        if !attributes.isEmpty { map["attributes"] = attributes }
        if !metrics.isEmpty { map["metrics"] = metrics }

        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: map, options: [.sortedKeys])
        } catch {
            throw EventEnrichmentError.serialization(
                "Failed to serialize event to JSON",
                "Verify that event attributes and metrics contain only JSON-compatible values.",
                error
            )
        }
        guard let json = String(data: data, encoding: .utf8) else {
            throw EventEnrichmentError.serialization(
                "Failed to encode JSON data as UTF-8 string",
                "Verify that event attributes and metrics contain only JSON-compatible values."
            )
        }
        return json
    }
}

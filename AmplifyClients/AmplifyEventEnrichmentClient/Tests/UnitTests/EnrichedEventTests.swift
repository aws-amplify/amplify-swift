//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import Foundation
import XCTest

final class EnrichedEventTests: XCTestCase {

    /// Test that toJson produces valid Pinpoint-compatible JSON
    ///
    /// - Given: An enriched event with all fields populated
    /// - When:
    ///    - toJson() is called
    /// - Then:
    ///    - The output is valid JSON with Pinpoint envelope structure
    ///
    func testToJsonProducesValidJson() throws {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let event = EnrichedEvent(
            eventId: "event-123",
            eventType: "test_event",
            eventTimestamp: 1_700_000_000_000,
            session: Session(
                id: "session-123",
                startTimestamp: startDate
            ),
            attributes: ["key": "value"],
            metrics: ["count": 1.0],
            device: DeviceMetadata(
                platform: "iOS",
                platformVersion: "17.0",
                manufacturer: "Apple",
                model: "iPhone15,2",
                locale: "en_US"
            ),
            app: AppMetadata(
                appId: "app-123",
                packageName: "com.example.app",
                versionName: "1.0.0",
                versionCode: "1"
            ),
            sdk: SDKMetadata(name: "amplify-swift", version: "2.58.0"),
            clientId: "client-123",
            userId: "user-456"
        )

        let json = event.toJson()
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["event_type"] as? String, "test_event")
        XCTAssertEqual(parsed["event_timestamp"] as? Int, 1_700_000_000_000)
        XCTAssertEqual(parsed["arrival_timestamp"] as? Int, 1_700_000_000_000)
        XCTAssertEqual(parsed["event_version"] as? String, "3.1")

        let application = parsed["application"] as! [String: Any]
        XCTAssertEqual(application["app_id"] as? String, "app-123")
        XCTAssertEqual(application["package_name"] as? String, "com.example.app")
        let sdkMap = application["sdk"] as! [String: Any]
        XCTAssertEqual(sdkMap["name"] as? String, "amplify-swift")
        XCTAssertEqual(sdkMap["version"] as? String, "2.58.0")

        let client = parsed["client"] as! [String: Any]
        XCTAssertEqual(client["client_id"] as? String, "client-123")
        XCTAssertEqual(client["user_id"] as? String, "user-456")

        let device = parsed["device"] as! [String: Any]
        let platform = device["platform"] as! [String: Any]
        XCTAssertEqual(platform["name"] as? String, "iOS")
        XCTAssertEqual(platform["version"] as? String, "17.0")
        XCTAssertEqual(device["make"] as? String, "Apple")
        XCTAssertEqual(device["model"] as? String, "iPhone15,2")

        let session = parsed["session"] as! [String: Any]
        XCTAssertEqual(session["id"] as? String, "session-123")
        XCTAssertTrue((session["start_timestamp"] as? String)?.contains("2023-11-14") == true)

        let attributes = parsed["attributes"] as! [String: String]
        XCTAssertEqual(attributes["key"], "value")

        let metrics = parsed["metrics"] as! [String: Double]
        XCTAssertEqual(metrics["count"], 1.0)
    }

    /// Test that toJson omits nil fields
    ///
    /// - Given: An enriched event with minimal fields
    /// - When:
    ///    - toJson() is called
    /// - Then:
    ///    - Nil fields are omitted from the JSON output
    ///
    /// Test that toJson includes stop_timestamp and duration for stopped sessions
    ///
    /// - Given: An enriched event with a stopped session (has stopTimestamp and duration)
    /// - When:
    ///    - toJson() is called
    /// - Then:
    ///    - The session includes stop_timestamp and duration in the JSON output
    ///
    func testToJsonWithStoppedSession() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let stop = Date(timeIntervalSince1970: 1_700_000_100)
        let event = EnrichedEvent(
            eventId: "event-123",
            eventType: "test_event",
            eventTimestamp: 1_700_000_100_000,
            session: Session(
                id: "session-123",
                startTimestamp: start,
                stopTimestamp: stop,
                duration: 100_000
            ),
            attributes: [:],
            metrics: [:],
            device: DeviceMetadata(),
            app: AppMetadata(appId: "app-123"),
            sdk: SDKMetadata(name: "test", version: "1.0"),
            clientId: "client-123",
            userId: nil
        )

        let json = event.toJson()
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let session = parsed["session"] as! [String: Any]
        XCTAssertNotNil(session["stop_timestamp"])
        XCTAssertEqual(session["duration"] as? Int, 100_000)
        XCTAssertTrue((session["stop_timestamp"] as? String)?.contains("2023-11-14") == true)
    }

    /// Test that toJson omits nil fields
    ///
    /// - Given: An enriched event with minimal fields
    /// - When:
    ///    - toJson() is called
    /// - Then:
    ///    - Nil fields are omitted from the JSON output
    ///
    func testToJsonOmitsNilFields() throws {
        let event = EnrichedEvent(
            eventId: "event-123",
            eventType: "test_event",
            eventTimestamp: 1_700_000_000_000,
            session: Session(id: "session-123", startTimestamp: Date(timeIntervalSince1970: 1_700_000_000)),
            attributes: [:],
            metrics: [:],
            device: DeviceMetadata(),
            app: AppMetadata(appId: "app-123"),
            sdk: SDKMetadata(name: "test", version: "1.0"),
            clientId: "client-123",
            userId: nil
        )

        let json = event.toJson()
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let client = parsed["client"] as! [String: Any]
        XCTAssertNil(client["user_id"])
        XCTAssertNil(parsed["attributes"])
        XCTAssertNil(parsed["metrics"])

        let session = parsed["session"] as! [String: Any]
        XCTAssertNil(session["stop_timestamp"])
        XCTAssertNil(session["duration"])
    }
}

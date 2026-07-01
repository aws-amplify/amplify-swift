//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import XCTest

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
final class AmplifyEventEnrichmentClientTests: XCTestCase {

    /// Test that recording an event returns an enriched event with expected fields
    ///
    /// - Given: A configured event enrichment client
    /// - When:
    ///    - An event is recorded with a type, attributes, and metrics
    /// - Then:
    ///    - The returned enriched event contains the correct metadata and fields
    ///
    func testRecordReturnsEnrichedEvent() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "amplify-swift", version: "2.58.0"),
            deviceMetadata: DeviceMetadata(platform: "iOS", platformVersion: "17.0")
        )

        let event = try await client.record(
            "button_clicked",
            attributes: ["screen": "home"],
            metrics: ["load_time": 1.5]
        )

        XCTAssertEqual(event.eventType, "button_clicked")
        XCTAssertEqual(event.attributes["screen"], "home")
        XCTAssertEqual(event.metrics["load_time"], 1.5)
        XCTAssertEqual(event.app.appId, "test-app")
        XCTAssertEqual(event.device.platform, "iOS")
        XCTAssertEqual(event.sdk.name, "amplify-swift")
        XCTAssertFalse(event.clientId.isEmpty)
        XCTAssertNil(event.userId)
        XCTAssertFalse(event.eventId.isEmpty)
        XCTAssertFalse(event.session.id.isEmpty)

        await client.close()
    }

    /// Test that recording on a closed client throws an error
    ///
    /// - Given: A closed event enrichment client
    /// - When:
    ///    - An event recording is attempted
    /// - Then:
    ///    - An EventEnrichmentError.clientClosed error is thrown
    ///
    func testRecordAfterCloseThrows() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "amplify-swift", version: "1.0.0"),
            deviceMetadata: DeviceMetadata(platform: "iOS")
        )

        await client.close()

        do {
            _ = try await client.record("test_event")
            XCTFail("Expected error to be thrown")
        } catch let error as EventEnrichmentError {
            guard case .clientClosed = error else {
                XCTFail("Expected clientClosed error, got \(error)")
                return
            }
        }
    }

    /// Test that global attributes are merged into events
    ///
    /// - Given: A client with global attributes set
    /// - When:
    ///    - An event is recorded
    /// - Then:
    ///    - The event contains both global and per-event attributes
    ///
    func testGlobalAttributesMerged() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        await client.addGlobalAttribute("app_version", value: "2.0")
        let event = try await client.record(
            "test",
            attributes: ["local_key": "local_value"]
        )

        XCTAssertEqual(event.attributes["app_version"], "2.0")
        XCTAssertEqual(event.attributes["local_key"], "local_value")

        await client.close()
    }

    /// Test that per-event attributes override global attributes
    ///
    /// - Given: A client with a global attribute set
    /// - When:
    ///    - An event is recorded with the same attribute key
    /// - Then:
    ///    - The per-event value takes precedence
    ///
    func testPerEventAttributesOverrideGlobals() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        await client.addGlobalAttribute("key", value: "global_value")
        let event = try await client.record(
            "test",
            attributes: ["key": "local_value"]
        )

        XCTAssertEqual(event.attributes["key"], "local_value")

        await client.close()
    }

    /// Test that setUserId is stamped on events
    ///
    /// - Given: A client with a userId set
    /// - When:
    ///    - An event is recorded
    /// - Then:
    ///    - The event contains the userId
    ///
    func testSetUserId() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        await client.setUserId("user-123")
        let event = try await client.record("test")

        XCTAssertEqual(event.userId, "user-123")

        await client.close()
    }

    /// Test that global metrics are merged into events
    ///
    /// - Given: A client with global metrics set
    /// - When:
    ///    - An event is recorded
    /// - Then:
    ///    - The event contains both global and per-event metrics
    ///
    func testGlobalMetricsMerged() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        await client.addGlobalMetric("session_count", value: 5.0)
        let event = try await client.record(
            "test",
            metrics: ["local_metric": 2.0]
        )

        XCTAssertEqual(event.metrics["session_count"], 5.0)
        XCTAssertEqual(event.metrics["local_metric"], 2.0)

        await client.close()
    }

    /// Test that removing a global attribute stops it from appearing on events
    ///
    /// - Given: A client with a global attribute that is then removed
    /// - When:
    ///    - An event is recorded after removal
    /// - Then:
    ///    - The removed attribute is not present on the event
    ///
    func testRemoveGlobalAttribute() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        await client.addGlobalAttribute("key", value: "value")
        await client.removeGlobalAttribute("key")
        let event = try await client.record("test")

        XCTAssertNil(event.attributes["key"])

        await client.close()
    }

    /// Test that removing a global metric stops it from appearing on events
    ///
    /// - Given: A client with a global metric that is then removed
    /// - When:
    ///    - An event is recorded after removal
    /// - Then:
    ///    - The removed metric is not present on the event
    ///
    func testRemoveGlobalMetric() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        await client.addGlobalMetric("count", value: 10.0)
        await client.removeGlobalMetric("count")
        let event = try await client.record("test")

        XCTAssertNil(event.metrics["count"])

        await client.close()
    }

    /// Test that setting userId to nil clears it from subsequent events
    ///
    /// - Given: A client with a userId set
    /// - When:
    ///    - setUserId(nil) is called and an event is recorded
    /// - Then:
    ///    - The event has no userId
    ///
    func testSetUserIdNilClearsUserId() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        await client.setUserId("user-123")
        await client.setUserId(nil)
        let event = try await client.record("test")

        XCTAssertNil(event.userId)

        await client.close()
    }

    /// Test that multiple records reuse the same session ID
    ///
    /// - Given: A client with an active session
    /// - When:
    ///    - Multiple events are recorded
    /// - Then:
    ///    - All events share the same session ID
    ///
    func testMultipleRecordsShareSessionId() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        let event1 = try await client.record("event_1")
        let event2 = try await client.record("event_2")
        let event3 = try await client.record("event_3")

        XCTAssertEqual(event1.session.id, event2.session.id)
        XCTAssertEqual(event2.session.id, event3.session.id)

        await client.close()
    }

    /// Test that disabling autoSessionTracking does not start a session
    ///
    /// - Given: A client created with autoSessionTracking = false
    /// - When:
    ///    - An event is recorded (which triggers lazy session start)
    /// - Then:
    ///    - The event still has a session (started on-demand)
    ///    - No ActivityTracker is created
    ///
    func testAutoSessionTrackingDisabled() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            options: EventEnrichmentClientOptions(autoSessionTracking: false)
        )

        let event = try await client.record("test")

        XCTAssertFalse(event.session.id.isEmpty)

        await client.close()
    }

    /// Test that each event gets a unique eventId
    ///
    /// - Given: A configured client
    /// - When:
    ///    - Multiple events are recorded
    /// - Then:
    ///    - Each event has a distinct eventId
    ///
    func testEachEventGetsUniqueId() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0")
        )

        let event1 = try await client.record("event_1")
        let event2 = try await client.record("event_2")

        XCTAssertNotEqual(event1.eventId, event2.eventId)

        await client.close()
    }
}


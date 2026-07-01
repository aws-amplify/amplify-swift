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
            appMetadata: AppMetadata(appId: "test-app"),
            deviceMetadata: DeviceMetadata(platform: "iOS", platformVersion: "17.0"),
            sdkMetadata: SDKMetadata(name: "amplify-swift", version: "2.58.0"),
            clientId: "test-client-id"
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
        XCTAssertEqual(event.clientId, "test-client-id")
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
            appMetadata: AppMetadata(appId: "test-app"),
            deviceMetadata: DeviceMetadata(platform: "iOS"),
            sdkMetadata: SDKMetadata(name: "amplify-swift", version: "1.0.0"),
            clientId: "test-id"
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
            appMetadata: AppMetadata(appId: "test-app"),
            deviceMetadata: DeviceMetadata(),
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            clientId: "test-id"
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
            appMetadata: AppMetadata(appId: "test-app"),
            deviceMetadata: DeviceMetadata(),
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            clientId: "test-id"
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
            appMetadata: AppMetadata(appId: "test-app"),
            deviceMetadata: DeviceMetadata(),
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            clientId: "test-id"
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
            appMetadata: AppMetadata(appId: "test-app"),
            deviceMetadata: DeviceMetadata(),
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            clientId: "test-id"
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
            appMetadata: AppMetadata(appId: "test-app"),
            deviceMetadata: DeviceMetadata(),
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            clientId: "test-id"
        )

        await client.addGlobalAttribute("key", value: "value")
        await client.removeGlobalAttribute("key")
        let event = try await client.record("test")

        XCTAssertNil(event.attributes["key"])

        await client.close()
    }
}

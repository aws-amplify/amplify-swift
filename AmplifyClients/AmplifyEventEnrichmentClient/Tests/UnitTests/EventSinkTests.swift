//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import XCTest

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
final class EventSinkTests: XCTestCase {

    /// Test that the event sink receives events when recording
    ///
    /// - Given: A client configured with a mock event sink
    /// - When:
    ///    - An event is recorded
    /// - Then:
    ///    - The sink receives the enriched event
    ///
    func testSinkReceivesEvents() async throws {
        let mockSink = MockEventSink()
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            deviceMetadata: DeviceMetadata(platform: "iOS"),
            sink: mockSink
        )

        _ = try await client.record("test_event")

        let events = await mockSink.sentEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, "test_event")

        await client.close()
    }
}

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
private actor MockEventSink: EventSink {
    var sentEvents: [EnrichedEvent] = []

    func send(_ event: EnrichedEvent) {
        sentEvents.append(event)
    }
}

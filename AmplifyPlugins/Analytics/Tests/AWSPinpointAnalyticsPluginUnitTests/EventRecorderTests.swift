//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPinpoint
@testable import Amplify
@testable import AWSPinpointAnalyticsPlugin

class EventRecorderTests: XCTestCase {
    var recorder: AnalyticsEventRecording!
    var storage: MockAnalyticsEventStorage!
    var pinpointClient: MockPinpointClient!
    var endpointClient: MockEndpointClient!

    override func setUp() {
        pinpointClient = MockPinpointClient()
        endpointClient = MockEndpointClient()
        storage = MockAnalyticsEventStorage()
        do {
            recorder = try EventRecorder(appId: "appId", storage: storage, pinpointClient: pinpointClient, endpointClient: endpointClient)
        } catch {
            XCTFail("Failed to setup EventRecorderTests")
        }
    }

    /// - Given: a event recorder
    /// - When: instance is constructed
    /// - Then: storage initializatin is called followed by disk size check and dirty event removal
    func testRecorderInitilization() {
        XCTAssertEqual(storage.initializeStorageCallCount, 1)
        XCTAssertEqual(storage.deleteDirtyEventCallCount, 1)
        XCTAssertEqual(storage.checkDiskSizeCallCount, 1)
    }

    /// - Given: a event recorder
    /// - When: a new pinpoint event is aved
    /// - Then: the event is saved to storage followed by a disk size check
    func testSaveEvent() {
        let session = PinpointSession(sessionId: "1", startTime: Date(), stopTime: nil)
        let event = PinpointEvent(id: "1", eventType: "eventType", eventDate: Date(), session: session)

        XCTAssertEqual(storage.events.count, 0)
        XCTAssertEqual(storage.checkDiskSizeCallCount, 1)

        do {
            try recorder.save(event)
        } catch {
            XCTFail("Failed to save events")
        }

        XCTAssertEqual(storage.events.count, 1)
        XCTAssertEqual(event, storage.events[0])
        XCTAssertEqual(storage.checkDiskSizeCallCount, 2)
    }
}

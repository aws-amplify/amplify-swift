//
//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin

class MockEventRecorder: AnalyticsEventRecording {
    var saveCount = 0
    var lastSavedEvent: PinpointEvent?
    func save(_ event: PinpointEvent) throws {
        saveCount += 1
        lastSavedEvent = event
    }

    var submitCount = 0
    func submitAllEvents() async throws -> [PinpointEvent] {
        submitCount += 1
        return []
    }
}

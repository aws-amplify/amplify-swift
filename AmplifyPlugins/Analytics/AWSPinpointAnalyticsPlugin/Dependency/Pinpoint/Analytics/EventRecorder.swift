//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AnalyticsEventRecording {
    func save(_ event: PinpointEvent) async throws
    func submitAllEvents() async throws -> [PinpointEvent]
}

class EventRecorder: AnalyticsEventRecording {
    func save(_ event: PinpointEvent) async throws {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func submitAllEvents() async throws -> [PinpointEvent] {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
}

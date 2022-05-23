//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct PinpointSession {
    let startTime: Date
    let stopTime: Date?
    let sessionId: String
    
    init(with context: PinpointContext) {
        startTime = Date()
        stopTime = nil
        sessionId = Self.generateSessionId(from: context)
    }
    
    func stop() {
        // TODO: Implement
        fatalError("Not yet implemented")

    }
    
    func pause() {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func resume() {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    var isPaused: Bool {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    var timeDurationInMillis: Int {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    static func generateSessionId(from context: PinpointContext) -> String {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
}

struct PinpointEndpointProfile {
    
    func addIdentityId(_ identityId: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func addUserProfile(_ userProfile: AnalyticsUserProfile) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
}

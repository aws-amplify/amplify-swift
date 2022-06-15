//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class PinpointSession: Codable {
    typealias SessionId = String

    let sessionId: SessionId
    let startTime: Date
    private(set) var stopTime: Date?
    
    init(appId: String,
         uniqueId: String) {
        sessionId = Self.generateSessionId(appId: appId,
                                           uniqueId: uniqueId)
        startTime = Date()
        stopTime = nil
    }
    
    init(sessionId: SessionId,
         startTime: Date,
         stopTime: Date?) {
        self.sessionId = sessionId
        self.startTime = startTime
        self.stopTime = stopTime
    }
    
    var isPaused: Bool {
        return stopTime != nil
    }
    
    var duration: Date.Millisecond {
        let endTime = stopTime ?? Date()
        return endTime.utcTimeMillis - startTime.utcTimeMillis
    }
    
    func stop() {
        guard stopTime == nil else { return }
        stopTime = Date()
    }
    
    func pause() {
        guard !isPaused else { return }
        stopTime = Date()
    }
    
    func resume() {
        stopTime = nil
    }
    
    private static func generateSessionId(appId: String,
                                          uniqueId: String) -> SessionId {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: Constants.Date.defaultTimezone)
        dateFormatter.locale = Locale(identifier: Constants.Date.defaultLocale)
        
        // Timestamp: Day
        dateFormatter.dateFormat = Constants.Date.dateFormat
        let timestampDay = dateFormatter.string(from: now)
        
        // Timestamp: Time
        dateFormatter.dateFormat = Constants.Date.timeFormat
        let timestampTime = dateFormatter.string(from: now)
        
        let appIdKey = appId.padding(toLength: Constants.maxAppKeyLength,
                                     withPad: Constants.paddingChar,
                                     startingAt: 0)
        let uniqueIdKey = uniqueId.padding(toLength: Constants.maxUniqueIdLength,
                                           withPad: Constants.paddingChar,
                                           startingAt: 0)
        
        // Create Session ID formatted as <AppId> - <UniqueID> - <Day> - <Time>
        return "\(appIdKey)-\(uniqueIdKey)-\(timestampDay)-\(timestampTime)"
    }
}

// MARK: - Equatable
extension PinpointSession: Equatable {
    static func == (lhs: PinpointSession, rhs: PinpointSession) -> Bool {
        return lhs.sessionId == rhs.sessionId
        && lhs.startTime == rhs.startTime
        && lhs.stopTime == rhs.stopTime
    }
}

extension PinpointSession {
    struct Constants {
        static let defaultSessionId = "00000000-00000000"
        static let maxAppKeyLength = 8
        static let maxUniqueIdLength = 8
        static let paddingChar = "_"

        struct CodingKeys {
            static let sessionId = "sessionId"
            static let startTime = "startTime"
            static let stopTime = "stopTime"
        }
        
        struct Date {
            static let defaultTimezone = "GMT"
            static let defaultLocale = "en_US"
            static let dateFormat = "yyyyMMdd"
            static let timeFormat = "HHmmssSSS"
        }
    }
}

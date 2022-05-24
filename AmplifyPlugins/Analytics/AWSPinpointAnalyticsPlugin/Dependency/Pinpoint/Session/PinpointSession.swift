//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class PinpointSession: NSObject, NSSecureCoding {
    static var supportsSecureCoding = true

    let sessionId: String
    let startTime: Date
    private(set) var stopTime: Date?
    
    init(appId: String,
         uniqueId: String) {
        sessionId = Self.generateSessionId(appId: appId,
                                           uniqueId: uniqueId)
        startTime = Date()
        stopTime = nil
    }
    
    init(sessionId: String,
         startTime: Date,
         stopTime: Date?) {
        self.sessionId = sessionId
        self.startTime = startTime
        self.stopTime = stopTime
    }
    
    required init?(coder: NSCoder) {
        guard let sessionId = coder.decodeObject(of: NSString.self, forKey: Constants.CodingKeys.sessionId) as? String,
              let startTime = coder.decodeObject(of: NSDate.self, forKey: Constants.CodingKeys.startTime) as? Date else {
            return nil
        }

        self.sessionId = sessionId
        self.startTime = startTime
        self.stopTime = coder.decodeObject(of: NSDate.self, forKey: Constants.CodingKeys.stopTime) as? Date
    }
    
    var isPaused: Bool {
        return stopTime != nil
    }
    
    var timeDurationInMillis: Int64 {
        let endTime = stopTime ?? Date()
        return endTime.utcTimeMillis - startTime.utcTimeMillis
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(sessionId as NSString, forKey: Constants.CodingKeys.sessionId)
        coder.encode(startTime as NSDate, forKey: Constants.CodingKeys.startTime)
        coder.encode(stopTime as NSDate?, forKey: Constants.CodingKeys.stopTime)
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
                                          uniqueId: String) -> String {
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

extension PinpointSession {
    struct Constants {
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
            static let dateFormat = "yyyMMdd"
            static let timeFormat = "HHmmssSSS"
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(InternalAWSPinpoint)
public struct PinpointSession: Codable {
    private enum State: Codable {
        case active
        case paused(date: Date)
        case stopped(date: Date)
    }
    typealias SessionId = String

    let sessionId: SessionId
    let startTime: Date
    var stopTime: Date? {
        switch state {
        case .active:
            return nil
        case .paused(let stopTime),
             .stopped(let stopTime):
            return stopTime
        }
    }
    
    private var state: State = .active

    init(appId: String,
         uniqueId: String) {
        sessionId = Self.generateSessionId(appId: appId,
                                           uniqueId: uniqueId)
        startTime = Date()
    }

    init(sessionId: SessionId,
         startTime: Date,
         stopTime: Date?) {
        self.sessionId = sessionId
        self.startTime = startTime
        if let stopTime {
            self.state = .stopped(date: stopTime)
        }
    }

    var isPaused: Bool {
        if case .paused = state {
            return true
        }

        return false
    }
    
    var isStopped: Bool {
        if case .stopped = state {
            return true
        }

        return false
    }

    var duration: Date.Millisecond? {
        /// According to Pinpoint's documentation, `duration` is only required if `stopTime` is not nil.
        guard let stopTime else { return nil }
        return stopTime.millisecondsSince1970 - startTime.millisecondsSince1970
    }

    mutating func stop() {
        guard !isStopped else { return }
        state = .stopped(date: stopTime ?? Date())
    }

    mutating func pause() {
        guard !isPaused else { return }
        state = .paused(date: Date())
    }

    mutating func resume() {
        state = .active
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
    public static func == (lhs: PinpointSession, rhs: PinpointSession) -> Bool {
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

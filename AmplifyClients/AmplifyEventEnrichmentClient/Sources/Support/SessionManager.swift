//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The state of the session manager.
enum SessionState: Sendable {
    /// No active session.
    case stopped
    /// Session is active (app in foreground).
    case active
    /// Session is paused (app backgrounded, within timeout).
    case paused
}

/// Manages session lifecycle with Active/Paused/Stopped states.
///
/// When the app backgrounds, the session enters ``SessionState/paused``.
/// If the app returns to foreground within the configured timeout, the same
/// session resumes. If the timeout expires, a new session starts on next
/// foreground.
actor SessionManager {
    private let appId: String
    private let sessionTimeout: TimeInterval
    private let generateId: @Sendable () -> String

    private var _state: SessionState = .stopped
    private var _session: Session?
    private var sessionStart: Date?
    private var pausedAt: Date?
    private var pauseTask: Task<Void, Never>?

    /// Current session state.
    var state: SessionState { _state }

    /// The most recent session, or `nil` if none has ever been started.
    ///
    /// This remains non-`nil` after ``stopSession()`` so callers can read the
    /// stop timestamp and duration of the session that just ended. Use
    /// ``activeSession`` to stamp events, which excludes stopped sessions.
    var session: Session? { _session }

    /// The session events may be attributed to, or `nil` if there is none.
    ///
    /// Unlike ``session`` this is `nil` once the session has stopped, so an
    /// event recorded after ``stopSession()`` is rejected rather than silently
    /// attributed to a session that has already ended.
    var activeSession: Session? {
        _state == .stopped ? nil : _session
    }

    /// Creates a session manager.
    /// - Parameters:
    ///   - appId: Application identifier used in session ID generation.
    ///   - sessionTimeout: Duration the app can remain backgrounded before a new session starts.
    ///   - generateId: Closure to generate a unique identifier (e.g., UUID).
    init(
        appId: String,
        sessionTimeout: TimeInterval = 5.0,
        generateId: @escaping @Sendable () -> String
    ) {
        self.appId = appId
        self.sessionTimeout = sessionTimeout
        self.generateId = generateId
    }

    /// Starts a new session. No-op if a session is already active or paused.
    func startSession() {
        if _state != .stopped {
            return
        }
        let start = Date()
        sessionStart = start
        _session = Session(
            id: generateSessionId(),
            startTimestamp: start
        )
        _state = .active
    }

    /// Stops the current session, recording stop time and duration.
    ///
    /// - Parameter stopTime: When the session ended. Defaults to now; pass an
    ///   earlier date when the session ended before this call was made, such as
    ///   a paused session whose timeout later expired.
    func stopSession(at stopTime: Date = Date()) {
        cancelPauseTimer()
        pausedAt = nil
        guard let currentSession = _session, let start = sessionStart else { return }
        _session = Session(
            id: currentSession.id,
            startTimestamp: currentSession.startTimestamp,
            stopTimestamp: stopTime,
            duration: Int64(stopTime.timeIntervalSince(start) * 1_000)
        )
        _state = .stopped
    }

    /// Called when the app moves to background.
    func handleAppPaused() {
        guard _state == .active else { return }
        _state = .paused
        pausedAt = Date()
        let timeout = sessionTimeout
        pauseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.onTimeoutExpired()
        }
    }

    /// Called when the app returns to foreground.
    func handleAppResumed() {
        switch _state {
        case .paused:
            cancelPauseTimer()
            pausedAt = nil
            _state = .active
        case .stopped:
            startSession()
        case .active:
            break
        }
    }

    private func onTimeoutExpired() {
        // The session became inactive when the app was backgrounded, not when
        // the timeout elapsed, so attribute the stop to the pause time.
        stopSession(at: pausedAt ?? Date())
    }

    private func cancelPauseTimer() {
        pauseTask?.cancel()
        pauseTask = nil
    }

    /// Builds a session ID formatted as `<appId>-<uniqueId>-<day>-<time>`.
    ///
    /// The layout matches Pinpoint's `PinpointSession.generateSessionId`: both the
    /// app ID and the unique ID are right-padded with `_` (and truncated when
    /// longer) to a fixed 8 characters so consumers can parse the ID positionally.
    private func generateSessionId() -> String {
        let appIdKey = appId.padding(
            toLength: Constants.maxAppKeyLength,
            withPad: Constants.paddingCharacter,
            startingAt: 0
        )
        let uniqueIdKey = generateId().padding(
            toLength: Constants.maxUniqueIdLength,
            withPad: Constants.paddingCharacter,
            startingAt: 0
        )
        let now = Date()
        let day = Self.dayFormatter.string(from: now)
        let time = Self.timeFormatter.string(from: now)
        return "\(appIdKey)-\(uniqueIdKey)-\(day)-\(time)"
    }

    private static let dayFormatter = makeFormatter(format: Constants.dayFormat)
    private static let timeFormatter = makeFormatter(format: Constants.timeFormat)

    /// A fixed-locale, fixed-timezone formatter so session IDs are stable
    /// regardless of the device's calendar, locale, or time zone.
    private static func makeFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: Constants.formatterLocale)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter
    }
}

private extension SessionManager {
    enum Constants {
        static let maxAppKeyLength = 8
        static let maxUniqueIdLength = 8
        static let paddingCharacter = "_"
        static let formatterLocale = "en_US_POSIX"
        static let dayFormat = "yyyyMMdd"
        static let timeFormat = "HHmmssSSS"
    }
}

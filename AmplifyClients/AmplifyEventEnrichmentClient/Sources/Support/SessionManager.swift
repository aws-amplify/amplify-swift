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

/// A session boundary, reported from inside the transition that caused it.
enum SessionBoundary: Sendable {
    case start
    case stop

    /// The event type sent for this boundary. Matches legacy Amplify Analytics.
    var eventType: String {
        switch self {
        case .start: return "_session.start"
        case .stop: return "_session.stop"
        }
    }
}

/// Manages session lifecycle with Active/Paused/Stopped states.
///
/// When the app backgrounds, the session enters ``SessionState/paused``.
/// If the app returns to foreground within the configured timeout, the same
/// session resumes. If the timeout expires, a new session starts on next
/// foreground.
///
/// Every transition runs synchronously on the actor and reports its boundary
/// before returning, so boundaries are reported in transition order.
actor SessionManager {
    private let appId: String
    private let sessionTimeout: TimeInterval
    private let generateId: @Sendable () -> String
    private let now: @Sendable () -> Date
    private let onBoundary: @Sendable (SessionBoundary, Session) -> Void

    private var _state: SessionState = .stopped
    private var _session: Session?
    private var sessionStart: Date?
    private var pausedAt: Date?
    private var pauseTask: Task<Void, Never>?
    private var pauseGeneration = 0
    private var backgrounded = false
    private var stoppedExplicitly = false
    private var disposed = false

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
    ///   - now: Clock used for session timestamps and pause expiry.
    ///   - startingSession: Whether to start a session right away.
    ///   - onBoundary: Called synchronously inside each transition. Must not block.
    init(
        appId: String,
        sessionTimeout: TimeInterval = 5.0,
        generateId: @escaping @Sendable () -> String,
        now: @escaping @Sendable () -> Date = { Date() },
        startingSession: Bool = false,
        onBoundary: @escaping @Sendable (SessionBoundary, Session) -> Void = { _, _ in }
    ) {
        self.appId = appId
        self.sessionTimeout = sessionTimeout
        self.generateId = generateId
        self.now = now
        self.onBoundary = onBoundary
        if startingSession {
            // An initializer cannot call isolated methods, so this repeats startFresh().
            let start = now()
            let session = Self.makeSession(appId: appId, uniqueId: generateId(), start: start)
            self.sessionStart = start
            self._session = session
            self._state = .active
            onBoundary(.start, session)
        }
    }

    /// Starts a new session, ending the current one first if there is one.
    /// No-op once disposed.
    func startSession() {
        guard !disposed else { return }
        endCurrent()
        startFresh()
    }

    /// Hands `body` the session an event recorded now belongs to, in the same
    /// isolated section that resolves it, so whatever `body` queues lands after
    /// that session's start and before its stop.
    ///
    /// A pause past the timeout ends the session first. With no running
    /// session, starts one. Returns `nil` once disposed.
    func withRecordingSession<T: Sendable>(_ body: @Sendable (Session) -> T) -> T? {
        guard !disposed else { return nil }
        if _state == .paused, isPauseExpired {
            endCurrent()
        }
        if _state == .stopped {
            startFresh()
        }
        guard let session = _session else { return nil }
        return body(session)
    }

    /// Stops the current session, recording stop time and duration.
    ///
    /// No-op if the session is already stopped. ``handleAppResumed()`` does not
    /// start a new session afterwards; ``startSession()`` does.
    func stopSession() {
        guard !disposed else { return }
        stoppedExplicitly = true
        endCurrent()
    }

    /// Stops the current session and turns every later call into a no-op.
    func dispose() {
        guard !disposed else { return }
        endCurrent()
        disposed = true
    }

    /// Called when the app moves to background. Noted even with no session
    /// running, so a session started before the next foreground starts paused.
    func handleAppPaused() {
        guard !disposed else { return }
        backgrounded = true
        guard _state == .active else { return }
        pauseCurrent()
    }

    /// Called when the app returns to foreground.
    ///
    /// The pause timestamp decides expiry, not only the timer, because the
    /// system can suspend timers while the app is in the background.
    func handleAppResumed() {
        guard !disposed else { return }
        backgrounded = false
        switch _state {
        case .paused:
            if isPauseExpired {
                endCurrent()
                startFresh()
            } else {
                cancelPauseTimer()
                pausedAt = nil
                _state = .active
            }
        case .stopped:
            guard !stoppedExplicitly else { return }
            startFresh()
        case .active:
            break
        }
    }

    /// Ends the paused session when its timeout elapses. Internal for tests.
    func onTimeoutExpired(pauseGeneration generation: Int) {
        // A timer that outlived its pause must not end the session after it.
        guard _state == .paused, generation == pauseGeneration else { return }
        endCurrent()
    }

    private var isPauseExpired: Bool {
        guard let pausedAt else { return false }
        return now().timeIntervalSince(pausedAt) >= sessionTimeout
    }

    private func pauseCurrent() {
        _state = .paused
        pausedAt = now()
        pauseGeneration += 1
        let generation = pauseGeneration
        let timeout = sessionTimeout
        pauseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.onTimeoutExpired(pauseGeneration: generation)
        }
    }

    private func startFresh() {
        stoppedExplicitly = false
        let start = now()
        let session = Self.makeSession(appId: appId, uniqueId: generateId(), start: start)
        sessionStart = start
        _session = session
        _state = .active
        onBoundary(.start, session)
        // A session started while backgrounded pauses immediately so it can
        // still time out.
        if backgrounded { pauseCurrent() }
    }

    // The session became inactive when the app was backgrounded, so a session
    // ended while paused is stamped at the pause time.
    private func endCurrent() {
        cancelPauseTimer()
        let stopTime = pausedAt ?? now()
        pausedAt = nil
        guard _state != .stopped, let currentSession = _session, let start = sessionStart else { return }
        let ended = Session(
            id: currentSession.id,
            startTimestamp: currentSession.startTimestamp,
            stopTimestamp: stopTime,
            duration: Int64(stopTime.timeIntervalSince(start) * 1_000)
        )
        _session = ended
        _state = .stopped
        onBoundary(.stop, ended)
    }

    private func cancelPauseTimer() {
        pauseTask?.cancel()
        pauseTask = nil
    }

    private static func makeSession(appId: String, uniqueId: String, start: Date) -> Session {
        Session(id: generateSessionId(appId: appId, uniqueId: uniqueId, at: start), startTimestamp: start)
    }

    /// Builds a session ID formatted as `<appId>-<uniqueId>-<day>-<time>`.
    ///
    /// The layout matches Pinpoint's `PinpointSession.generateSessionId`: both the
    /// app ID and the unique ID are right-padded with `_` (and truncated when
    /// longer) to a fixed 8 characters so consumers can parse the ID positionally.
    private static func generateSessionId(appId: String, uniqueId: String, at date: Date) -> String {
        let appIdKey = appId.padding(
            toLength: Constants.maxAppKeyLength,
            withPad: Constants.paddingCharacter,
            startingAt: 0
        )
        let uniqueIdKey = uniqueId.padding(
            toLength: Constants.maxUniqueIdLength,
            withPad: Constants.paddingCharacter,
            startingAt: 0
        )
        let day = dayFormatter.string(from: date)
        let time = timeFormatter.string(from: date)
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

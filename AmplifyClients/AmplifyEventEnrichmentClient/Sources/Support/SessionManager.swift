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
    private var pauseTask: Task<Void, Never>?

    /// Current session state.
    var state: SessionState { _state }

    /// Current session, or `nil` if stopped.
    var session: Session? { _session }

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
        sessionStart = Date()
        _session = Session(
            id: generateSessionId(),
            startTimestamp: sessionStart!
        )
        _state = .active
    }

    /// Stops the current session, recording stop time and duration.
    func stopSession() {
        cancelPauseTimer()
        guard let currentSession = _session, let start = sessionStart else { return }
        let now = Date()
        _session = Session(
            id: currentSession.id,
            startTimestamp: currentSession.startTimestamp,
            stopTimestamp: now,
            duration: Int64(now.timeIntervalSince(start) * 1_000)
        )
        _state = .stopped
    }

    /// Called when the app moves to background.
    func handleAppPaused() {
        guard _state == .active else { return }
        _state = .paused
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
            _state = .active
        case .stopped:
            startSession()
        case .active:
            break
        }
    }

    private func onTimeoutExpired() {
        stopSession()
    }

    private func cancelPauseTimer() {
        pauseTask?.cancel()
        pauseTask = nil
    }

    private func generateSessionId() -> String {
        var prefix = appId
        if prefix.count > 8 {
            prefix = String(prefix.prefix(8))
        } else {
            prefix = String(repeating: "_", count: 8 - prefix.count) + prefix
        }
        let uniqueId = String(generateId().prefix(8))
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(
            in: TimeZone(identifier: "UTC")!,
            from: now
        )
        let date = String(
            format: "%04d%02d%02d-%02d%02d%02d%03d",
            components.year!, components.month!, components.day!,
            components.hour!, components.minute!, components.second!,
            components.nanosecond! / 1_000_000
        )
        return "\(prefix)-\(uniqueId)-\(date)"
    }
}

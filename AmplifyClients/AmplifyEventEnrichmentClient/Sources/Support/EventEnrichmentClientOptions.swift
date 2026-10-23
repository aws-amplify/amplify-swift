//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Configuration options for ``AmplifyEventEnrichmentClient``.
public struct EventEnrichmentClientOptions: Sendable {
    /// Whether to automatically start a session on initialization.
    ///
    /// Defaults to `true`.
    public let autoSessionTracking: Bool

    /// Duration the app can remain backgrounded before a new session starts.
    ///
    /// Defaults to 5 seconds.
    public let sessionTimeout: TimeInterval

    /// Whether session starts and stops are sent to the sink as `_session.start`
    /// and `_session.stop` events. Sessions are tracked and stamped on every
    /// event either way.
    ///
    /// Defaults to `true`.
    public let emitSessionEvents: Bool

    public init(
        autoSessionTracking: Bool = true,
        sessionTimeout: TimeInterval = 5.0,
        emitSessionEvents: Bool = true
    ) {
        self.autoSessionTracking = autoSessionTracking
        self.sessionTimeout = sessionTimeout
        self.emitSessionEvents = emitSessionEvents
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents an app session with start/stop timestamps and duration.
public struct Session: Sendable {
    /// Unique session identifier.
    public let id: String

    /// When the session started.
    public let startTimestamp: Date

    /// When the session stopped, or `nil` if still active.
    public let stopTimestamp: Date?

    /// Duration of the session in milliseconds.
    public let duration: Int64?

    public init(
        id: String,
        startTimestamp: Date,
        stopTimestamp: Date? = nil,
        duration: Int64? = nil
    ) {
        self.id = id
        self.startTimestamp = startTimestamp
        self.stopTimestamp = stopTimestamp
        self.duration = duration
    }
}

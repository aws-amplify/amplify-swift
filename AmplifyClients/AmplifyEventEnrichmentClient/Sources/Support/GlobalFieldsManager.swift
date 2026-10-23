//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Manages the user ID, global attributes and metrics that are stamped on every event.
///
/// Values are in-memory only and not persisted between sessions. Guarded by a
/// lock rather than an actor so a session transition can stamp an event
/// synchronously.
final class GlobalFieldsManager: @unchecked Sendable {
    private let lock = NSLock()
    private var _userId: String?
    private var _attributes: [String: String] = [:]
    private var _metrics: [String: Double] = [:]

    init() {}

    /// Current user ID.
    var userId: String? {
        get { lock.withLock { _userId } }
        set { lock.withLock { _userId = newValue } }
    }

    /// Current global attributes.
    var attributes: [String: String] { lock.withLock { _attributes } }

    /// Current global metrics.
    var metrics: [String: Double] { lock.withLock { _metrics } }

    /// Adds a global attribute.
    func addAttribute(_ key: String, value: String) {
        lock.withLock { _attributes[key] = value }
    }

    /// Removes a global attribute by key.
    func removeAttribute(_ key: String) {
        lock.withLock { _ = _attributes.removeValue(forKey: key) }
    }

    /// Adds a global metric.
    func addMetric(_ key: String, value: Double) {
        lock.withLock { _metrics[key] = value }
    }

    /// Removes a global metric by key.
    func removeMetric(_ key: String) {
        lock.withLock { _ = _metrics.removeValue(forKey: key) }
    }

    /// Reads every field in one critical section.
    func snapshot() -> (userId: String?, attributes: [String: String], metrics: [String: Double]) {
        lock.withLock { (_userId, _attributes, _metrics) }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Manages global attributes and metrics that are stamped on every event.
///
/// Values are in-memory only and not persisted between sessions.
internal actor GlobalFieldsManager {
    private var _attributes: [String: String] = [:]
    private var _metrics: [String: Double] = [:]

    internal init() {}

    /// Current global attributes.
    internal var attributes: [String: String] { _attributes }

    /// Current global metrics.
    internal var metrics: [String: Double] { _metrics }

    /// Adds a global attribute.
    internal func addAttribute(_ key: String, value: String) {
        _attributes[key] = value
    }

    /// Removes a global attribute by key.
    internal func removeAttribute(_ key: String) {
        _attributes.removeValue(forKey: key)
    }

    /// Adds a global metric.
    internal func addMetric(_ key: String, value: Double) {
        _metrics[key] = value
    }

    /// Removes a global metric by key.
    internal func removeMetric(_ key: String) {
        _metrics.removeValue(forKey: key)
    }
}

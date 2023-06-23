//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension Resettable where Self: Plugin {
    /// A default conformance if the plugin has no reset logic
    func reset() async {
        // Do nothing
    }
}

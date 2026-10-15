//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Runs a consumer's log stream setup one at a time; batches consumed meanwhile wait for the same setup.
/// A setup that couldn't create the stream is dropped, so the next batch tries again with the same name.
package actor LogStreamSetup {
    private var setup: Task<(name: String, isSetUp: Bool), Never>?
    private var name: String?

    package init() {}

    /// - Parameter setUp: Sets up the stream, given the name an earlier attempt chose, and reports whether it now exists.
    package func streamName(setUp: @escaping @Sendable (String?) async -> (name: String, isSetUp: Bool)) async -> String {
        let setup = setup ?? Task { [name] in await setUp(name) }
        self.setup = setup
        let result = await setup.value
        name = result.name
        if !result.isSetUp, self.setup == setup {
            self.setup = nil
        }
        return result.name
    }
}

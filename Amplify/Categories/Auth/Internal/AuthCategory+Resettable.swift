//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: Resettable {

    public func reset() async {
        // Hoisted so the task closure below captures these Sendable values rather
        // than a non-Sendable `self`, which is an error in the Swift 6 language mode.
        let log = log
        let categoryType = categoryType
        await withTaskGroup(of: Void.self) { taskGroup in
            for plugin in plugins.values {
                taskGroup.addTask {
                    log.verbose("Resetting \(String(describing: categoryType)) plugin")
                    await plugin.reset()
                    log.verbose("Resetting \(String(describing: categoryType)) plugin: finished")
                }
            }
            await taskGroup.waitForAll()
        }
        isConfigured = false
    }
}

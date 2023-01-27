//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DataStoreCategory: Resettable {

    public func reset(onComplete: @escaping BasicClosure) {
        let group = DispatchGroup()

        for plugin in plugins.values {
            log.verbose("Resetting \(categoryType) plugin")
            group.enter()
            plugin.reset {
                self.log.verbose("Resetting \(self.categoryType) plugin: finished")
                group.leave()
            }
        }

        group.wait()

        isConfigured = false
        onComplete()
    }

}

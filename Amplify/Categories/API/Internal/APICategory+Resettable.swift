//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyAPICategory: Resettable {

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

        log.verbose("Resetting ModelRegistry and ModelListDecoderRegistry")
        ModelRegistry.reset()
        ModelListDecoderRegistry.reset()
        log.verbose("Resetting ModelRegistry and ModelListDecoderRegistry: finished")

        group.wait()

        isConfigured = false
        onComplete()
    }

}

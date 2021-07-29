//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension LoggingCategory: Resettable {

    public func reset(onComplete: @escaping BasicClosure) {
        log.verbose("Resetting \(categoryType) plugin: no 'finish' message will be logged")
        concurrencyQueue.sync {
            let group = DispatchGroup()

            group.enter()
            plugin.reset {
                group.leave()
            }

            group.wait()

            configurationState = .default
            onComplete()
        }
    }

}

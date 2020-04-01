//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension LoggingCategory: Resettable {

    public func reset(onComplete: @escaping BasicClosure) {
        concurrencyQueue.sync {
            let group = DispatchGroup()

            group.enter()

            plugin.reset { group.leave() }

            group.wait()

            configurationState = .default
            onComplete()
        }
    }

}

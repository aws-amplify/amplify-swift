//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class ConcurrentEffectExecutor: EffectExecutor {
    private let concurrentQueue: DispatchQueue

    init(concurrentQueue: DispatchQueue) {
        self.concurrentQueue = concurrentQueue
    }

    func execute(
        _ actions: [Action],
        dispatchingTo eventDispatcher: EventDispatcher,
        environment: Environment
    ) {
        actions.forEach { action in
            self.concurrentQueue.async {
                action.execute(withDispatcher: eventDispatcher, environment: environment)
            }
        }
    }

}

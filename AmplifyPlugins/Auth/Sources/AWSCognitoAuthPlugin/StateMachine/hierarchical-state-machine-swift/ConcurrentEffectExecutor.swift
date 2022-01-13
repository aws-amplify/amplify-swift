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
        _ commands: [Command],
        dispatchingTo eventDispatcher: EventDispatcher,
        environment: Environment
    ) {
        commands.forEach { command in
            self.concurrentQueue.async {
                command.execute(withDispatcher: eventDispatcher, environment: environment)
            }
        }
    }

}

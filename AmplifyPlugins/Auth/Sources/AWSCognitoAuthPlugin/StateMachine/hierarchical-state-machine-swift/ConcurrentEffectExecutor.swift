//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum ConcurrentEffectExecutor: EffectExecutor {

    static func execute(
        _ actions: [Action],
        dispatchingTo eventDispatcher: EventDispatcher,
        environment: Environment) {
            actions.forEach { action in
                Task {
                    await action.execute(withDispatcher: eventDispatcher, environment: environment)
                }
            }
        }

}

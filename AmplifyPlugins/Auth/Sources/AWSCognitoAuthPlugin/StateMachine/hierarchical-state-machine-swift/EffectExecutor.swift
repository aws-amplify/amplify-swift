//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol EffectExecutor {
    func execute(
        _ commands: [Command],
        dispatchingTo eventDispatcher: EventDispatcher,
        environment: Environment
    )
}

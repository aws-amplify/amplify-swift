//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol EffectExecutor {
    static func execute(
        _ actions: [Action],
        dispatchingTo eventDispatcher: EventDispatcher,
        environment: Environment
    )
}

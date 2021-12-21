//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public extension AuthorizationState {

    struct Resolver: StateMachineResolver {
        public typealias StateType = AuthorizationState
        public let defaultState = AuthorizationState.unconfigured

        public init() { }

        public func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {

            return .from(oldState)
        }


    }
}

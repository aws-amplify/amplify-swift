//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct StateResolution<T: State> {
    package let newState: T
    package let actions: [Action]

    package static func from(_ state: T) -> StateResolution<T> {
        StateResolution(newState: state)
    }

    package init(
        newState: T,
        actions: [Action] = []
    ) {
        self.newState = newState
        self.actions = actions
    }
}
